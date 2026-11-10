# Defensa TFM — Automatización GitOps de FIWARE Data Spaces

Defensa: lunes 2 nov 2026, 09:15 CET · 15 min de exposición + 10 min de preguntas.
Estado verificado el 1 nov 2026, ~01:00 CET.

---

## 1. Cómo quedó implementado

### Infraestructura (Terraform, `tfm-terraform-framework` v1.0.19)

| Pieza | Estado real |
|---|---|
| Red | VPC 10.0.0.0/16, 3 capas (public / app / data) × 3 AZ = 9 subredes, 1 NAT, NACL, 4 SG |
| Cómputo | EKS **1.35** · 2 nodos `t3a.large` SPOT en eu-west-1a y eu-west-1b (kubelet 1.34, compatible) |
| Identidad | OIDC de EKS + IRSA (ESO, cert-manager, AWS LBC) · OIDC de GitHub Actions → `github-actions-terraform-role` (sin claves estáticas) |
| Secretos | 4 secretos en AWS Secrets Manager (`/fiware/*`, JSON `{"password":…}`) + token Cloudflare (`/fiware/cloudflare/api-token`) |
| DNS / TLS | Zona Route53 + ACM por Terraform; CNAME públicos en Cloudflare **por Terraform** (`module.cloudflare_dns`) → NLB; 5 certificados Let's Encrypt (DNS-01) |
| Addons (bootstrap) | cert-manager 1.17.2, external-secrets 0.14.0, ingress-nginx 4.10.1, AWS LBC 2.10.0, metrics-server |
| Framework | 26 módulos AWS; tag `v1.0.19` con los arreglos de este re-despliegue |

### GitOps (ArgoCD v2.14.11, `tfm-fiware-gitops`)

App of Apps `fiware-data-space` con sync waves:

| Ola | Recurso |
|---|---|
| −2 | ClusterIssuers (Let's Encrypt prod/staging) |
| −1 | ClusterSecretStore (AWS Secrets Manager vía IRSA) |
| 0 | ExternalSecrets, MySQL |
| 1 | Keyrock (IdP), Trusted Issuers List (TIL/TIR), Credentials Config Service |
| 2 | Orion-LD 1.10.0 + MongoDB |
| 3 | Kong 3.9 (PEP, DB-less) |

8/8 Applications `Synced/Healthy`, `selfHeal: true`, `prune: true`.

### Flujo de autorización (Kong como PEP)

1. Plugin `jwt`: valida firma HS256 y `exp` contra el consumer cuyo `key` = claim `iss`.
2. Plugin `post-function` (fase access, después del `jwt`): `GET /issuer/{iss}` al TIL interno.
   200 → pasa a Orion-LD · otro código → **403** · TIL caído → **503** (falla cerrado).

| Escenario (Tabla 26) | Respuesta real |
|---|---|
| Sin `Authorization` | `401 {"message":"Unauthorized"}` |
| Firma inválida | `401 {"message":"Invalid signature"}` |
| Emisor no registrado en TIL | `403 {"message":"Forbidden: issuer not registered in Trusted Issuers List"}` |
| Participante registrado | `200` Orion-LD `1.10.0` |

### CI/CD (GitHub Actions)

- `gitops-validate.yml`: Helm Lint + kubeconform en PR y push.
- `security-scan.yml`: Checkov + TruffleHog.
- `infra-deploy.yml`: push en `infra/environments/**` → clona el framework en la versión del tfvars → `backend-setup.sh` → plan → apply → `post-apply.sh`. Última ejecución en verde con v1.0.19.
- `infra-destroy.yml`: manual, con confirmación `DESTROY`.
- Framework: `terraform-validate.yml` (fmt, validate, Checkov).

### Mediciones nuevas (31 oct 2026)

| KPI | Umbral | Medido | Evidencia |
|---|---|---|---|
| RS-2 selfHeal tras `kubectl scale --replicas=0` | < 60 s (texto) / < 3 min (tabla) | **3 s** réplica restaurada · **6,8 s** HTTP 200 vía Kong | `evidencias/rs2-20261031T2351Z.log` |
| RS-1 `kubectl drain` del nodo con Kong, ingress, TIL y Mongo | < 5 min | gateway caído 4,8 s → 64,8 s · plataforma completa **95 s** · smoke-test 9/9 a 101 s | `evidencias/rs1-20261031T2353Z.log` |
| SE-3 / CF-1 (Tabla 26) | 100 % rechazos / exitoso | 401 · 401 · 403 · 200 | `tests/smoke-test.sh` → 9 OK / 0 FAIL |

---

## 2. Hallazgos

### 2.1 Encontrados al re-desplegar desde cero (y ya corregidos)

El entorno se destruyó tras la entrega y se re-desplegó 5 meses después. **Eso es la prueba de reproducibilidad real**: la deriva de dependencias apareció y se corrigió con cambios pequeños y trazables (PR en Git).

| # | Hallazgo | Causa | Corrección |
|---|---|---|---|
| 1 | Bootstrap de addons fallaba | helm provider 3.x cambió su esquema; nulls en `region`/`assume_role_arn`; ruta relativa | framework PR #1: `helm ~> 2.15`, `coalesce`, `realpath` |
| 2 | No se creaba el NLB | el módulo `subnet` ignoraba los `tags` por subred → sin `kubernetes.io/role/elb` | `merge(tags, each.value.tags)` (coincide con §4.2.1 de la memoria) |
| 3 | AWS LBC: `AccessDenied` | política IAM desactualizada frente a LBC v2.10 (listeners, ListenerAttributes, GetSecurityGroupsForVpc) | alineada con `iam_policy.json` oficial v2.10.0 |
| 4 | ESO sin acceso a Secrets Manager | ClusterSecretStore apuntaba al SA en ns `platform`; el bootstrap lo instala en `external-secrets` | namespace corregido |
| 5 | ExternalSecret de Cloudflare en error | ola −2, antes que su ClusterSecretStore (ola −1) | movida a ola 0 (PR #3) |
| 6 | Keyrock/MySQL sin arrancar | Terraform guarda contraseñas en texto plano y las ExternalSecrets esperan `{"password":…}` | secretos re-escritos en JSON |
| 7 | `cluster-config` OutOfSync permanente | el webhook de ESO añade campos por defecto | declarados en Git (PR #4) |
| 8 | `setup-dns.sh` fallaba | namespace `platform` → `ingress-nginx`; ruta relativa con `-chdir` | PR #4 |
| 9 | El escenario 403 de la Tabla 26 no estaba en el código | se validó a mano y no quedó versionado | `post-function` en Kong + consumer no registrado + smoke-test (PR #5) |
| 10 | El scheduler apagaba los nodos de 22:00 a 14:00 UTC | coincide con la defensa | desactivado en tfvars (PR #6) |

### 2.2 Diferencias con la memoria (se defienden, no se cambian)

| Tema | Qué dice la memoria / propuesta | Qué hay | Argumento |
|---|---|---|---|
| Helm Umbrella DSC | La propuesta habla del umbrella oficial | Applications independientes con sync waves | Control y health por componente; dependencias entre subcharts mal documentadas; retirada de Bitnami de Docker Hub; presupuesto de 2 nodos. Umbrella como trabajo futuro |
| Keyrock como PDP | §4.3.3 describe el patrón PEP-PDP | Kong valida en local y consulta el TIL; Keyrock emite tokens pero no está en el camino de los datos | Delegación XACML = arquitectura objetivo; sandbox sin eIDAS (Limitaciones) |
| HS256 / iSHARE | Flujo iSHARE | Sandbox con secreto compartido | Declarado en Intro y §5.1 Limitaciones |
| RD-1 | < 30 min | ~40 min | **No se cumple**; ~17 min son la creación de EKS, que no depende del modelo GitOps |
| RS-1 / réplicas | HA | réplicas = 1, se mide recuperación | RTO 95 s < 5 min; HA real (réplicas + PDB + anti-affinity) es deuda |
| Reconciliación 30 s | selfHeal < 60 s | 3 s medido | selfHeal reacciona por eventos de watch, no por el periodo |
| Tabla 27 "lista vacía" | TIL/TIR vacíos | ahora hay 1 emisor | Medición previa al alta del emisor |
| DNS | Route53 | Route53 + ACM por Terraform; CNAME públicos en Cloudflare (zona autoritativa del laboratorio) | Paso de delegación NS documentado en la Tabla 24 |
| EKS / AZ | 1.34, nodos en 1b/1c | 1.35, nodos en 1a/1b | Actualización = una línea en tfvars → prueba de la reproducibilidad |
| Branch protection (Anexo D) | PR con revisión | merges con `--admin` de un único autor | Proyecto individual; los checks sí son obligatorios |

### 2.3 Deuda técnica y riesgos (reconocerlos si preguntan)

1. **API de escritura del TIL pública y sin autenticación** (`POST https://til.lab-jdmonsalvel.com/issuer`). Es el riesgo más serio. En producción: solo interna o detrás de Kong con autenticación.
2. **TIL en H2 en memoria**: pierde los emisores en cada reinicio del pod. El smoke-test los vuelve a registrar. Soluciones: `initData` del chart (emisores declarados en Git, PostSync) y `database.persistence` contra MySQL/RDS.
3. **MySQL y MongoDB con `emptyDir`**, sin PVC: un reinicio pierde datos. En producción: RDS / DocumentDB o PVC con EBS por AZ.
4. **Réplicas = 1** en todos los componentes FIWARE.
5. **Secreto JWT de demo en Git** (`kong.yaml`). En producción por ESO, como el resto.
6. **Formato de secretos**: Terraform los crea en texto plano y ESO espera JSON. Si se recrean, hay que repetir la conversión.
7. **Drift de tags** entre `aws_subnet` y `aws_ec2_tag` (`kubernetes.io/cluster`) en las subredes de app.
8. **Sin `.terraform.lock.hcl`** en el framework: CI y local resuelven versiones de provider distintas.
9. **Release del framework**: release-please falla porque Actions no puede crear PR en el repo; los tags se crean a mano.
10. **Contraseñas de respaldo fijas** en `scripts/post-apply.sh` (solo si el secreto no existe).

---

## 3. Guion de la exposición (15 min, 14 diapositivas)

| # | Diapositiva | Tiempo | Qué decir |
|---|---|---|---|
| 1 | Portada | 0:30 | Título, autor, máster, director. "Automatizar con GitOps un Data Space FIWARE en AWS EKS." |
| 2 | Contexto y problema | 1:00 | Data Spaces europeos (Gaia-X, DGA). FIWARE se despliega hoy a mano o con Helm directo → poco reproducible, sin trazabilidad. Pregunta: ¿se puede desplegar y operar un Data Space FIWARE solo desde Git? |
| 3 | Objetivos | 1:00 | Objetivo general + OE-1…OE-6 (los 6 cumplidos, Tabla 29). Cuatro dimensiones de KPI: despliegue, resiliencia, seguridad, conformidad. |
| 4 | Metodología y stack | 1:00 | Iterativa en 4 entregas. Terraform → EKS; ArgoCD App of Apps; GitHub Actions con OIDC; ESO + Secrets Manager; cert-manager. |
| 5 | Arquitectura de referencia | 1:30 | VPC de 3 capas en 3 AZ, EKS con 2 nodos SPOT, NLB → ingress-nginx. Trust Anchor (Keyrock, TIL/TIR, CCS, MySQL) y Provider (Kong → Orion-LD → MongoDB). |
| 6 | Infraestructura como código | 1:00 | Framework propio de 26 módulos versionado por tags; el entorno es un `terraform.tfvars`. El bootstrap instala los addons con IRSA. Ejemplo: subir EKS a 1.35 = una línea. |
| 7 | GitOps: App of Apps y sync waves | 1:30 | Git como única fuente de verdad. Olas −2 → 3: emisores TLS → almacén de secretos → secretos y BD → IdP y TIL → broker → gateway. selfHeal + prune. |
| 8 | CI/CD y seguridad | 1:00 | 4 workflows. Checkov, TruffleHog, kubeconform, Helm Lint. Sin claves AWS estáticas (OIDC). Secretos fuera de Git (ESO). |
| 9 | Flujo de autorización | 1:30 | Kong como PEP: JWT → consulta al TIL → Orion-LD. Los cuatro casos 401/401/403/200 de la Tabla 26. Falla cerrado si el TIL no responde. |
| 10 | Resultados (KPIs) | 1:30 | Tabla resumen. Decir claramente que RD-1 (~40 min) no cumple y por qué. RS-1 95 s, RS-2 6,8 s, SE-1/SE-2 = 0, SE-3 100 %, CF-1/CF-2 OK. |
| 11 | Evidencia / demo | 1:00 | Smoke-test 9/9 y ArgoCD en verde (capturas o vídeo de respaldo). Mencionar que el entorno se re-desplegó desde cero esta semana. |
| 12 | Decisiones de diseño | 1:00 | Por qué Applications independientes en lugar del umbrella; HS256 en sandbox; Cloudflare para la zona pública. |
| 13 | Limitaciones y deuda técnica | 0:45 | Réplicas = 1, almacenamiento efímero, TIL en memoria y API pública, sin eIDAS, sin conector IDS. Dicho por el autor antes de que lo pregunte el tribunal. |
| 14 | Conclusiones, trabajo futuro y preguntas | 0:45 | GitOps + IaC hacen el Data Space reproducible y auditable. Futuro: multi-clúster con ApplicationSets, conector EDC, OpenTelemetry, pruebas DGA. "Gracias, quedo atento a sus preguntas." |

Total ≈ 15:00. Si el tiempo aprieta, fusionar 4 con 3 y 12 con 13.

### Checklist del lunes 2 nov

- 07:30 `kubectl get nodes` (2 Ready) y `kubectl get applications -n argocd` (8 Healthy).
- `bash tests/smoke-test.sh` → 9 OK. **Siempre antes de cualquier `curl` manual**: re-registra el emisor en el TIL.
- Port-forward de ArgoCD abierto y vídeo de respaldo a mano.
- Tras la defensa: destroy solo con confirmación explícita; reactivar el scheduler si el entorno sigue en pie.

---

## 4. Prompt para Claude Design

Ver el bloque de abajo; se pega tal cual y se adjuntan la plantilla y la memoria.

```text
Hola Claude, me han programado la defensa de mi TFM del Máster Universitario en Desarrollo y Operaciones (DevOps) de UNIR. Necesito la presentación de defensa.

## Formato de la defensa
- 15 minutos de exposición + 10 minutos de preguntas del tribunal.
- Entre 12 y 15 diapositivas (objetivo: 14). Idioma: español.
- Usa la plantilla adjunta (plantilla_defensa) para colores, tipografías, logotipos, portada y pie de página. No inventes una identidad visual nueva.

## Material adjunto
1. Plantilla de la universidad (plantilla_defensa).
2. Memoria entregada: tfm_automatizacion_gitops_de_fiware_data_spaces.pdf. Es la fuente de verdad del contenido; no la contradigas.
3. Este guion con los datos verificados del entorno.

## Propuesta original del TFM (contexto)
[pegar aquí el texto de la propuesta: descripción y justificación, objetivos, metodología]

## Lo que realmente se construyó (usar estos datos, son los verificados)
- Infraestructura como código: framework Terraform propio de 26 módulos (tag v1.0.19). VPC de 3 capas en 3 AZ (9 subredes), EKS 1.35 con 2 nodos t3a.large SPOT, IRSA, Secrets Manager, Route53 + ACM, CNAME públicos en Cloudflare gestionados por Terraform, NLB → ingress-nginx. Addons: cert-manager, External Secrets Operator, AWS Load Balancer Controller.
- GitOps: ArgoCD v2.14 con App of Apps y sync waves: −2 ClusterIssuers → −1 ClusterSecretStore → 0 ExternalSecrets + MySQL → 1 Keyrock, Trusted Issuers List, Credentials Config Service → 2 Orion-LD 1.10.0 + MongoDB → 3 Kong 3.9. selfHeal y prune activos. 8/8 aplicaciones Synced/Healthy.
- Seguridad / CI-CD: GitHub Actions con OIDC (sin claves estáticas). Workflows: GitOps Validate (Helm Lint + kubeconform), Security Scan (Checkov + TruffleHog), Infra Deploy (plan/apply al cambiar el tfvars), Infra Destroy (manual con confirmación). Secretos fuera de Git mediante ESO.
- Flujo de autorización: Kong actúa como PEP. Valida el JWT (HS256, claim iss y exp) y después consulta la Trusted Issuers List; si el emisor no está registrado devuelve 403. Resultados reales:
  - Sin token → 401 Unauthorized
  - Firma inválida → 401 Invalid signature
  - Emisor no registrado en TIL → 403 Forbidden: issuer not registered in Trusted Issuers List
  - Participante registrado → 200 (Orion-LD 1.10.0)

## KPIs (tabla de resultados)
| KPI | Umbral | Resultado |
| RD-1 Tiempo de despliegue completo | < 30 min | ~40 min (no cumple; ~17 min son la creación de EKS) |
| RD-2 Pasos manuales | ≤ 2 | 2 (aprobación en GitHub Environments y delegación NS, una vez) |
| RD-3 Re-despliegue tras destrucción total | 100 % | Cumple: re-desplegado desde cero 5 meses después de la entrega |
| RS-1 RTO tras fallo de nodo (kubectl drain) | < 5 min | 95 s |
| RS-2 Re-sincronización de ArgoCD tras drift | < 3 min | 6,8 s (réplica restaurada en 3 s) |
| SE-1 Hallazgos críticos de Checkov | 0 | 0 |
| SE-2 Secretos expuestos (TruffleHog) | 0 | 0 |
| SE-3 Peticiones sin JWT válido rechazadas | 100 % | 100 % |
| CF-1 Flujo token → acceso a datos | Exitoso | Exitoso (401/401/403/200) |
| CF-2 Consulta NGSI-LD /entities | HTTP 200 + JSON-LD | HTTP 200 |
Marca RD-1 con un indicador de "no cumple" o "parcial": quiero ser transparente.

## Estructura de diapositivas (respétala; el tiempo es orientativo)
1. Portada (0:30)
2. Contexto y problema: Data Spaces europeos (Gaia-X, Data Governance Act), FIWARE desplegado hoy a mano (1:00)
3. Objetivo general y los 6 objetivos específicos OE-1…OE-6, todos cumplidos (1:00)
4. Metodología (4 entregas iterativas) y stack tecnológico, con logotipos (1:00)
5. Arquitectura de referencia: diagrama AWS (VPC 3 capas, EKS, NLB) con el Trust Anchor (Keyrock, TIL/TIR, CCS, MySQL) y el Provider (Kong → Orion-LD → MongoDB) (1:30)
6. Infraestructura como código: framework de módulos versionado, un tfvars por entorno, bootstrap de addons (1:00)
7. GitOps: diagrama App of Apps con las sync waves −2 → 3 (1:30)
8. CI/CD y seguridad: los 4 workflows como pipeline, OIDC, ESO (1:00)
9. Flujo de autorización: diagrama de secuencia Consumidor → Kong (JWT) → TIL → Orion-LD, con los 4 casos 401/401/403/200 (1:30)
10. Resultados: tabla de KPIs con estado visual (1:30)
11. Evidencia: salida del smoke-test (9 OK / 0 FAIL) y ArgoCD en verde; dejar huecos para capturas que añadiré yo (1:00)
12. Decisiones de diseño frente a la propuesta: Applications independientes en lugar del Helm umbrella (control y health por componente, dependencias entre subcharts, retirada de imágenes Bitnami, presupuesto de 2 nodos); HS256 en sandbox en lugar de eIDAS/iSHARE (1:00)
13. Limitaciones y deuda técnica: réplicas = 1, almacenamiento efímero (MySQL/Mongo/TIL), sin certificados eIDAS, sin conector IDS, RD-1 por encima del umbral (0:45)
14. Conclusiones, trabajo futuro (multi-clúster con ApplicationSets, conector Eclipse EDC, OpenTelemetry, pruebas de conformidad DGA) y "Gracias / Preguntas" (0:45)

## Estilo
- Poco texto por diapositiva: máximo 5 viñetas cortas o un diagrama protagonista. Las explicaciones van en las notas del orador.
- Diagramas limpios (arquitectura, sync waves, secuencia de autorización, pipeline CI/CD) en lugar de párrafos.
- Cifras grandes y legibles para los KPIs (95 s, 6,8 s, 0 hallazgos, 401/403/200).
- Incluye notas del orador en cada diapositiva con lo que tengo que decir, ajustado al tiempo indicado.
- No inventes datos, cifras ni capturas que no estén aquí o en la memoria. Donde falte una captura, deja un marcador "[Captura: …]".

## Entregable
Presentación de 14 diapositivas sobre la plantilla, con notas del orador, descargable en .pptx.
```
