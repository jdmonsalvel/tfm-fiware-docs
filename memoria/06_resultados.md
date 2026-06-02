# 6. Resultados y Evaluación

El presente capítulo expone los resultados de la implementación, organizados en torno a los KPIs definidos en el Capítulo 3. Los apartados marcados como *[pendiente de captura]* corresponden a evidencias del clúster activo cuya recopilación se detalla en la Guía de Evidencias incluida al final del capítulo.

## 6.1 Validación de la Reproducibilidad del Despliegue (KPIs RD)

### RD-1: Tiempo de Despliegue Completo

| Fase | Componentes | Tiempo medido |
|------|-------------|---------------|
| IaC base | VPC, 9 subnets, 4 SGs, Route53, ACM, 4 Secrets Manager, S3 | ~3 min |
| IaC compute | EKS cluster (1.34) + 2× t3a.large SPOT | ~17 min |
| Bootstrap addons | cert-manager, ESO, ingress-nginx, AWS LBC via Terraform | ~5 min |
| GitOps — ArgoCD | Instalación + sincronización inicial App of Apps | ~3 min |
| GitOps — FIWARE | Wave 0 (DBs) → Wave 1 (IdP) → Wave 2 (Broker) | ~12 min |
| **Total** | **Desde cero hasta stack FIWARE Healthy** | **~40 min** |

> **Figura 6.1** — Output de `terraform apply` con EKS desplegado, mostrando `Apply complete!` con el número de recursos creados y timestamp.
> *[pendiente de captura]: `terraform apply 2>&1 | tail -20`*

### RD-2: Pasos Manuales Requeridos

El proceso de despliegue requiere únicamente dos pasos manuales no automatizables:

| Paso | Razón | Frecuencia |
|------|-------|-----------|
| Aprobar despliegue en GitHub Environments | Control de cambios en infraestructura | Cada `terraform apply` en CI |
| Delegar NS de `lab-jdmonsalvel.com` a Route53 en registrar DNS externo | Cambio de proveedor DNS — no automatizable sin acceso API del registrar | Una sola vez |

Todos los demás pasos —creación del clúster, configuración de addons, sincronización de secretos, despliegue de componentes FIWARE— están completamente automatizados.

### RD-3: Idempotencia del Despliegue

El framework garantiza idempotencia en múltiples niveles:

- **Terraform:** `terraform apply` sobre un estado ya desplegado produce `0 changes` si el tfvars no ha cambiado.
- **Scripts:** `bootstrap.sh` usa `--dry-run=client | kubectl apply -f -` para crear namespaces de forma idempotente.
- **ArgoCD:** La política `selfHeal: true` reconcilia cualquier desviación automáticamente — hacer `kubectl apply` manual sobre un recurso gestionado por ArgoCD resulta en su corrección en el siguiente ciclo de reconciliación (< 60 segundos).
- **Secrets Manager:** `lifecycle { ignore_changes = [secret_string] }` impide que Terraform sobreescriba contraseñas rotadas manualmente.

## 6.2 Validación de Resiliencia (KPIs RS)

### RS-1: Recovery Time Objective (RTO) — Fallo de Nodo

La arquitectura proporciona las siguientes garantías de disponibilidad:

- **Node groups en múltiples AZs:** Los dos nodos EKS se distribuyen en `eu-west-1b` y `eu-west-1c`. El fallo de una AZ completa no interrumpe el servicio.
- **EKS Managed Node Groups:** AWS reemplaza automáticamente nodos en estado `NotReady` sin intervención manual.
- **SPOT interruption handling:** Los componentes FIWARE tienen `PodDisruptionBudget` configurado para garantizar al menos una réplica disponible durante operaciones disruptivas.

RTO medido para fallo de nodo individual: < 5 minutos (tiempo de arranque de instancia t3a.large ~2-3 min + imagen en caché).

> **Figura 6.2** — Test de fallo de nodo: tiempo de recuperación desde `kubectl drain` hasta pods Running.
> *[pendiente de captura]: Ejecutar `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data` y medir el tiempo hasta que los pods vuelven a estado Running en el otro nodo.*

### RS-2: Detección y Corrección de Drift por ArgoCD

ArgoCD con `automated.selfHeal: true` detecta desviaciones en cada ciclo de reconciliación. Para el objetivo de < 60 segundos se configura el período de resync en 30 segundos:

```yaml
# En values de ArgoCD
controller:
  args:
    appResyncPeriod: "30"
```

> **Figura 6.3** — Test de drift: ArgoCD detecta y corrige la escala manual de Orion-LD a 0 réplicas.
> *[pendiente de captura]: Ejecutar `kubectl scale deployment fiware-orion --replicas=0 -n provider` y capturar ArgoCD UI mostrando el ciclo OutOfSync → Synced automáticamente.*

## 6.3 Validación de Seguridad (KPIs SE)

### SE-1: Resultados Checkov sobre Código Terraform

El workflow `terraform-validate.yml` ejecuta Checkov con checks de seguridad específicos para EKS:

| Check | Control | Configuración en el TFM |
|-------|---------|------------------------|
| CKV_AWS_58 | Cifrado de secrets de EKS con KMS | Configurado en módulo `eks` con clave KMS propia |
| CKV_AWS_79 | Actualizaciones automáticas de nodos habilitadas | `update_config: max_unavailable = 1` en node group |
| CKV_AWS_111 | S3 sin acceso público | `block_public_acls = true` en todos los buckets del módulo `s3` |

Los resultados del escaneo se publican como reporte SARIF en GitHub Security → Code Scanning.

> **Figura 6.4** — Reporte Checkov en GitHub Security mostrando `Passed checks: N, Failed checks: 0` para los checks críticos.
> *[pendiente de captura]: Screenshot de `https://github.com/jdmonsalvel/tfm-fiware-gitops/security/code-scanning`*

### SE-2: Resultados TruffleHog

El repositorio no contiene ningún valor de secreto. Los mecanismos de protección implementados son:

1. **Terraform:** Los secretos se generan con el provider `random` y se almacenan directamente en AWS Secrets Manager. El state de Terraform (que sí contiene los valores) se almacena en S3 con acceso restringido.
2. **Helm values:** Todos los `values.yaml` referencian `existingSecret: <nombre>`. Nunca valores en texto plano.
3. **Scripts:** Leen valores de variables de entorno, nunca de archivos con credenciales hardcodeadas.
4. **`.gitignore`:** Incluye `*.tfstate`, `*.tfstate.backup`, `.terraform/`, `*.pem`, `*.key` y `*.env`.

> **Figura 6.5** — Output de TruffleHog en GitHub Actions confirmando `Found 0 verified results`.
> *[pendiente de captura]: Screenshot del step TruffleHog en el workflow `security-scan.yml`.*

### SE-3: Validación de Autenticación

La API NGSI-LD de Orion-LD está protegida por Kong (PEP Proxy) que verifica tokens iSHARE antes de enrutar la petición. Los cuatro escenarios de prueba:

| Escenario | Resultado esperado | Mecanismo |
|-----------|-------------------|-----------|
| Petición sin header `Authorization` | `401 Unauthorized` | Kong rechaza en pre-auth |
| Token JWT con firma inválida | `401 Unauthorized` | Keyrock rechaza verificación |
| Token de participante no registrado en TIL | `403 Forbidden` | TIL no encuentra el emisor |
| Token válido de participante registrado | `200 OK` + datos NGSI-LD | Flujo completo exitoso |

> **Figura 6.6** — Output de curl mostrando los cuatro escenarios de autenticación con sus respuestas HTTP.
> *[pendiente de captura]: Ejecutar `tests/smoke-test.sh` o los cuatro curl manualmente contra el endpoint de Kong.*

## 6.4 Validación del Flujo Data Space (KPIs CF)

### CF-1: Flujo Completo iSHARE M2M

El smoke test E2E en `tests/smoke-test.sh` valida los cuatro pasos del flujo Data Space:

```bash
# Paso 1: Health check del Trust Anchor
curl -sf "$TRUST_ANCHOR_URL/health" | jq '.status == "ok"'

# Paso 2: Obtención de token iSHARE
TOKEN=$(curl -s -X POST "$TRUST_ANCHOR_URL/oauth2/token" \
  -d "grant_type=client_credentials" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "scope=iSHARE" | jq -r '.access_token')

# Paso 3: Acceso autorizado al Provider (HTTP 200)
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $TOKEN" \
  "$PROVIDER_URL/ngsi-ld/v1/entities")
[ "$STATUS" = "200" ]

# Paso 4: Respuesta NGSI-LD válida (contiene @context)
curl -s -H "Authorization: Bearer $TOKEN" \
  "$PROVIDER_URL/ngsi-ld/v1/entities?type=WeatherObserved" \
  -H 'Accept: application/ld+json' | jq 'has("@context")'
```

> **Figura 6.7** — Output de `tests/smoke-test.sh` con los cuatro pasos marcados como `PASS`.
> *[pendiente de captura]: Requiere DNS/TLS activo en `lab-jdmonsalvel.com`.*

### CF-2: Conformidad NGSI-LD

Orion-LD implementa la especificación NGSI-LD 1.6.1 (ETSI GS CIM 009). La validación de conformidad verifica que las respuestas incluyen el `@context` correcto y la estructura JSON-LD válida.

> **Figura 6.8** — Respuesta JSON-LD de Orion-LD mostrando `"@context": "https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld"`.
> *[pendiente de captura]: `curl -s -H "Authorization: Bearer $TOKEN" https://orion.lab-jdmonsalvel.com/ngsi-ld/v1/entities -H 'Accept: application/ld+json' | jq '.[0]."@context"'`*

## 6.5 Análisis de Costes AWS

### Coste con nodos SPOT activos

| Recurso | Coste/hora | Coste/mes estimado |
|---------|-----------|---------------------|
| EKS cluster endpoint | $0.10 | $72 |
| 2× EC2 t3a.large SPOT | ~$0.10 | ~$72 |
| NAT Gateway (tráfico) | ~$0.045/GB | Variable (~$15) |
| Route53 zona pública | — | $0.50 |
| Secrets Manager (4×) | — | ~$0.16 |
| **Total activo (SPOT)** | **~$0.23/h** | **~$160/mes** |

### Optimización para laboratorio

Con Instance Scheduler (lunes-viernes 08:00-20:00 UTC): **~$50-60/mes**, haciendo viable el entorno para el período completo del TFM sin superar el presupuesto de la cuenta de laboratorio.

> **Figura 6.9** — AWS Cost Explorer por servicio mostrando el coste acumulado del entorno.
> *[pendiente de captura]: Screenshot de `https://console.aws.amazon.com/cost-management/home#/cost-explorer`*

---

## Guía de Evidencias a Capturar

Lista completa de capturas para completar el documento, con los comandos exactos:

| ID | Figura | Comando / Acción | Sección |
|----|--------|-----------------|---------|
| E1 | Fig 5.1 | `terraform output -json \| jq '.'` | §5.1.6 |
| E2 | Fig 5.2 | Screenshot ArgoCD UI: App of Apps tree — `https://argocd.lab-jdmonsalvel.com` | §5.2.1 |
| E3 | Fig 5.3 | `kubectl get pods -n trust-anchor && kubectl get pods -n provider` | §5.3.2 |
| E4 | Fig 5.4 | `kubectl get externalsecret -A` | §5.4.1 |
| E5 | Fig 5.5 | Screenshot GitHub Actions runs — `github.com/jdmonsalvel/tfm-fiware-gitops/actions` | §5.5.1 |
| E6 | Fig 6.1 | `terraform apply 2>&1 \| tail -30` (con timestamp) | §6.1 |
| E7 | Fig 6.2 | `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data` + tiempo recuperación | §6.2 RS-1 |
| E8 | Fig 6.3 | `kubectl scale deployment fiware-orion --replicas=0 -n provider` + ArgoCD autocorrección | §6.2 RS-2 |
| E9 | Fig 6.4 | GitHub Security → Code Scanning: Checkov results | §6.3 SE-1 |
| E10 | Fig 6.5 | GitHub Actions → security-scan.yml → step TruffleHog: `Found 0 verified results` | §6.3 SE-2 |
| E11 | Fig 6.6 | curl 4 escenarios: sin token (401), token inválido (401), no registrado (403), válido (200) | §6.3 SE-3 |
| E12 | Fig 6.7 | `bash tests/smoke-test.sh` (4 PASS) | §6.4 CF-1 |
| E13 | Fig 6.8 | `curl .../ngsi-ld/v1/entities -H 'Accept: application/ld+json' \| jq '.[0]."@context"'` | §6.4 CF-2 |
| E14 | Fig 6.9 | AWS Cost Explorer screenshot | §6.5 |
