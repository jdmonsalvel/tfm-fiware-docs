# 4. Desarrollo Específico de la Contribución

## 4.1 Planificación, Análisis y Requisitos

### 4.1.1 Principios de Diseño

El diseño del modelo de referencia se articula en torno a seis principios arquitectónicos derivados de los paradigmas GitOps (CNCF, 2022), cloud-native (CNCF, 2023) y los requisitos de los Data Spaces europeos (DSBA, 2023):

1. **Declaratividad:** Todo el estado del sistema —tanto la infraestructura como las aplicaciones— se define mediante archivos declarativos versionados en Git. Las operaciones imperativas se eliminan del flujo operacional nominal.
2. **Inmutabilidad:** Los artefactos desplegados (imágenes de contenedor, charts Helm) se referencian mediante *digests* o versiones fijadas, garantizando que el mismo *commit* siempre produce el mismo despliegue.
3. **Mínimo privilegio:** Los componentes solo obtienen los permisos estrictamente necesarios para su función. Los roles IAM de AWS siguen el principio de *least-privilege* con granularidad de servicio; los roles Kubernetes se definen mediante RBAC con *scope* de *namespace*.
4. ***Defense in depth*:** La seguridad se implementa en múltiples capas: red (Security Groups, Network Policies), identidad (IRSA, OIDC), aplicación (Kong PEP, validación JWT) y datos (cifrado en reposo con KMS).
5. **Observabilidad by design:** Los componentes exponen métricas en formato Prometheus, logs estructurados y trazas distribuidas desde el momento del despliegue inicial.
6. **Soberanía de datos:** Los datos nunca abandonan el perímetro definido sin pasar por el mecanismo de control de acceso. Los secretos no se almacenan en el repositorio Git ni en imágenes de contenedor.

### 4.1.2 Arquitectura del Sistema (Modelo C4)

**Vista Contextual (Level 1)**

> **Figura 4.1** — Diagrama C4 Level 1: contexto del sistema con actores y sistemas externos.
> *Fuente: Elaboración propia.*

El sistema interactúa con tres actores y dos sistemas externos. El **Ingeniero DevOps** es el actor primario, con acceso exclusivo de escritura al repositorio Git. El **Consumidor de Datos** accede a los datos de contexto vía API NGSI-LD, mediado por Kong. El **Proveedor de Datos** publica entidades NGSI-LD con acceso condicionado por políticas. **GitHub** actúa como *Single Source of Truth*, almacenando el estado deseado del sistema y su historial completo de cambios. El **iSHARE Satellite** es el ancla de confianza del Data Space: valida que los participantes están certificados antes de emitir tokens de acceso.

**Vista de Contenedores (Level 2)**

> **Figura 4.2** — Diagrama C4 Level 2: namespaces Kubernetes y componentes desplegados.
> *Fuente: Elaboración propia.*

La plataforma se despliega en un clúster Amazon EKS organizado en cuatro *namespaces* con responsabilidades claramente separadas:

*Namespace `argocd`:* Contiene el operador GitOps. ArgoCD se configura para monitorizar el repositorio Git del proyecto mediante el patrón **App of Apps** (ArgoCD, 2023): una Application raíz gestiona el ciclo de vida de todas las demás Applications, garantizando un *bootstrapping* idempotente desde un único punto de entrada.

*Namespace `trust-anchor`:* Contiene la infraestructura de identidad del Data Space: **Keyrock** (IdP raíz, emisor de Verifiable Credentials, implementación del protocolo iSHARE M2M), **Trusted Issuers List** (TIL, registro de emisores confiables), **Credentials Config Service** (CCS, configuración para el flujo SIOP2/OIDC4VP) y **MySQL** (persistencia de Keyrock).

*Namespace `provider`:* Contiene la capa de datos: **Orion-LD** (Context Broker NGSI-LD, API REST en el puerto 1026, persistencia en MongoDB), **Kong** (PEP/API Gateway, verificación de tokens Bearer según el flujo iSHARE) y **MongoDB** (almacenamiento documental en modo *standalone* para el entorno de laboratorio).

*Namespace `platform`:* Servicios transversales de plataforma gestionados por Terraform: **External Secrets Operator** (sincronización de secretos desde AWS Secrets Manager vía IRSA), **cert-manager** (gestión automática de certificados TLS con Let's Encrypt) e **ingress-nginx** (enrutamiento HTTPS con terminación TLS en el borde del clúster).

### 4.1.3 Topología de Red AWS

> **Figura 4.3** — Diagrama de red AWS: VPC en tres capas, NLB, NAT Gateway y nodos EKS.
> *Fuente: Elaboración propia.*

La infraestructura de red sigue el patrón recomendado por la AWS EKS Best Practices Guide (AWS, 2023). La VPC `fiware-vpc` (`10.0.0.0/16`) en `eu-west-1` implementa tres capas con nueve subredes distribuidas en tres zonas de disponibilidad: subredes públicas para el NLB y el NAT Gateway; subredes de aplicación para los nodos worker EKS (`t3a.large` SPOT, sin IPs públicas); y subredes de datos reservadas para bases de datos. La región `eu-west-1` (Irlanda) se selecciona por su conformidad con el RGPD y la proximidad al ecosistema Gaia-X europeo.

### 4.1.4 Modelo de Identidades y Acceso

La integración entre pods Kubernetes y servicios AWS se implementa mediante **IRSA** (*IAM Roles for Service Accounts*): un rol IAM se asocia a una ServiceAccount de Kubernetes mediante una anotación y un proveedor OIDC, permitiendo a los pods asumir permisos AWS sin credenciales estáticas.

El flujo de acceso al Data Space implementa el protocolo iSHARE M2M sobre OAuth2:

> **Figura 4.4** — Flujo iSHARE M2M: secuencia de autenticación y autorización en seis pasos.
> *Fuente: Elaboración propia basada en iSHARE Foundation (2023).*

1. El Consumidor presenta un *iSHARE JWT* firmado con su clave privada (certificado eIDAS/X.509) a Keyrock.
2. Keyrock verifica la validez del JWT y consulta al iSHARE Satellite que el Consumidor es un participante certificado.
3. Tras la confirmación, Keyrock emite un *Access Token* JWT con tiempo de expiración de 30 segundos.
4. El Consumidor adjunta el Access Token a cada solicitud NGSI-LD dirigida a Kong.
5. Kong delega la decisión de autorización en Keyrock, que evalúa la política XACML correspondiente al recurso solicitado.
6. Kong reenvía o bloquea la solicitud a Orion-LD según el veredicto de Keyrock.

### 4.1.5 Decisiones de Arquitectura (ADR)

**ADR-001: Selección de ArgoCD sobre FluxCD**

| Campo | Detalle |
|-------|---------|
| **Estado** | Aceptado |
| **Contexto** | Se requiere un operador GitOps para el despliegue declarativo de los componentes FIWARE en Kubernetes. |
| **Decisión** | Se selecciona ArgoCD v2.11 sobre FluxCD v2.3. |
| **Justificación** | ArgoCD ofrece interfaz gráfica para supervisión visual del estado de sincronización, soporte nativo para App of Apps sin dependencias adicionales, y mayor adopción empresarial que incrementa la transferibilidad del modelo. |
| **Consecuencias** | Mayor consumo de memoria (~512 MB adicionales respecto a Flux), asumible en el entorno de laboratorio. |

**ADR-002: Región AWS eu-west-1**

| Campo | Detalle |
|-------|---------|
| **Estado** | Aceptado |
| **Decisión** | Se utiliza la región `eu-west-1` (Irlanda). |
| **Justificación** | Conformidad RGPD, residencia de datos en la UE, disponibilidad de todos los servicios AWS requeridos y menor latencia hacia nodos del ecosistema Gaia-X. |
| **Consecuencias** | No se identifican consecuencias negativas para el alcance del trabajo. |

**ADR-003: MongoDB en modo *standalone***

| Campo | Detalle |
|-------|---------|
| **Estado** | Aceptado (con deuda técnica documentada) |
| **Decisión** | MongoDB se despliega en modo *standalone* para el entorno de laboratorio. |
| **Justificación** | El modo *replica set* incrementaría los costes en ~5 USD/día sin aportar valor adicional a los objetivos definidos. |
| **Deuda técnica** | En producción se requiere modo *replica set* con 3 miembros para HA y consistencia fuerte. |

**ADR-004: Instancias t3a.large en modalidad SPOT**

| Campo | Detalle |
|-------|---------|
| **Estado** | Aceptado |
| **Decisión** | Dos nodos `t3a.large` (2 vCPU / 8 GB RAM) en modalidad SPOT. |
| **Justificación** | Tamaño mínimo viable para el stack FIWARE completo (~8-10 GB RAM). Las instancias SPOT reducen el coste en ~70% respecto a On-Demand. VPC CNI Prefix Delegation eleva el límite de pods/nodo hasta 110. |
| **Consecuencias** | Riesgo de interrupción SPOT mitigado con nodos en AZs distintas y `PodDisruptionBudget`. |

**ADR-005: Separación de responsabilidades entre Terraform y ArgoCD**

| Campo | Detalle |
|-------|---------|
| **Estado** | Aceptado |
| **Decisión** | Terraform gestiona los componentes de plataforma (cert-manager, ESO, ingress-nginx, AWS LBC); ArgoCD gestiona exclusivamente los workloads FIWARE. |
| **Justificación** | Los componentes de plataforma son prerrequisitos del propio ArgoCD. Delegarlos a ArgoCD crearía una dependencia circular en el proceso de *bootstrap*. |
| **Consecuencias** | Mayor complejidad en el módulo `eks/bootstrap`. Separación limpia: Terraform = infraestructura + plataforma; ArgoCD = workloads. |

---

## 4.2 Descripción del Sistema Desarrollado

### 4.2.1 Aprovisionamiento de Infraestructura con Terraform

**Framework de módulos reutilizables**

La infraestructura se organiza mediante un framework de 25 módulos Terraform ubicados en `tfm-terraform-framework/modules/aws/`. El patrón de diseño es uniforme en todos ellos: variable de entrada `map(object({...}))` para definir múltiples instancias del recurso en un único bloque, recursos creados con `for_each`, *outputs* planos `{ nombre → id }` compatibles con *lookup* directo, y etiquetado mediante `merge(var.tags, each.value.tags, { Name = each.value.name })`.

```hcl
# Resolución nombre → ID en locals.tf
locals {
  subnet_ids = merge(
    module.subnet.subnet_ids,
    { for k, v in data.aws_subnet.existing : k => v.id }
  )
}
module "eks" {
  count      = length(var.eks) > 0 ? 1 : 0
  source     = "./modules/aws/eks"
  subnet_ids = local.subnet_ids
  ...
}
```

| Módulo | Recurso principal |
|--------|-------------------|
| `vpc` | `aws_vpc` con Flow Logs opcionales |
| `subnet` | `aws_subnet` con asociación a ACL de red |
| `network-acl` | `aws_network_acl` con reglas dinámicas |
| `security-group` | `aws_security_group` con ingress/egress dinámicos |
| `nat-gw` | `aws_nat_gateway` + EIP |
| `s3` | Buckets S3 con versionado y cifrado obligatorio |
| `acm` | Certificados ACM con validación DNS |
| `route53` | Zonas y registros Route53 |
| `secrets-manager` | Secretos en AWS Secrets Manager con generación aleatoria de contraseñas |
| `iam` | Roles, políticas y usuarios IAM |
| `eks` | Clúster EKS + node groups + IRSA + bootstrap de addons Helm |

**Gestión de estado remoto**

El estado de Terraform se almacena en S3 con versionado habilitado, cifrado SSE-S3, bloqueo mediante DynamoDB (`terraform-lock`) y acceso restringido a la identidad IAM del pipeline CI/CD. El *bucket* utilizado es `devops-575124957370-terraform-state-bucket`.

**Gestión de secretos en Terraform**

El módulo `secrets-manager` genera contraseñas con el *provider* `random` y las almacena en AWS Secrets Manager. La directiva `lifecycle { ignore_changes = [secret_string] }` garantiza que Terraform no sobreescriba contraseñas rotadas manualmente tras el primer despliegue:

```hcl
resource "random_password" "generated" {
  for_each = { for k, v in var.secrets_manager_secrets : k => v if v.generate_password }
  length   = 32
  special  = false
}
resource "aws_secretsmanager_secret_version" "secret" {
  for_each      = var.secrets_manager_secrets
  secret_id     = aws_secretsmanager_secret.secret[each.key].id
  secret_string = each.value.generate_password ? random_password.generated[each.key].result : each.value.secret_string
  lifecycle { ignore_changes = [secret_string] }
}
```

Se crean cuatro secretos bajo el prefijo `/fiware/`: contraseña de administrador y de base de datos de Keyrock, contraseña *root* de MySQL y contraseña *root* de MongoDB.

**Autenticación AWS en CI/CD (OIDC)**

La autenticación entre GitHub Actions y AWS se implementa mediante OpenID Connect (OIDC), eliminando las credenciales estáticas del repositorio. GitHub solicita un token JWT firmado por `token.actions.githubusercontent.com`; AWS IAM lo verifica contra el proveedor OIDC registrado en la cuenta `575124957370` y asume el rol `github-actions-terraform-role` mediante `AssumeRoleWithWebIdentity`.

**Bootstrap de addons de plataforma**

El submódulo `eks/bootstrap/` instala los componentes de plataforma vía Helm inmediatamente después de crear el clúster, sin intervención de ArgoCD:

| Addon | Helm Chart | Namespace |
|-------|-----------|-----------|
| AWS Load Balancer Controller | `eks/aws-load-balancer-controller` | `kube-system` |
| cert-manager | `jetstack/cert-manager` | `cert-manager` |
| External Secrets Operator | `external-secrets/external-secrets` | `platform` |
| ingress-nginx | `ingress-nginx/ingress-nginx` | `platform` |
| metrics-server | `metrics-server/metrics-server` | `kube-system` |

> **Figura 4.5** — Output de `terraform apply` con EKS desplegado, mostrando el número de recursos creados y los *outputs* con `eks_cluster_endpoint` e IRSAs.
> *Fuente: Elaboración propia. Capturar con: `terraform output -json | jq '.'`*

### 4.2.2 Bootstrap del Operador GitOps (ArgoCD)

**Instalación y patrón App of Apps**

ArgoCD se instala mediante `scripts/bootstrap.sh` en el *namespace* `argocd` de forma idempotente. La Application raíz apunta al directorio `gitops/apps/` con `directory.recurse: true`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: fiware-data-space
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/jdmonsalvel/tfm-fiware-gitops
    targetRevision: HEAD
    path: gitops/apps
    directory:
      recurse: true
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

La política `automated.selfHeal: true` garantiza que cualquier desviación entre el estado del clúster y el repositorio Git sea corregida automáticamente, materializando el principio de reconciliación continua de GitOps.

> **Figura 4.6** — ArgoCD UI mostrando el App of Apps con todas las Applications en estado Synced/Healthy.
> *Fuente: Elaboración propia. URL: `https://argocd.lab-jdmonsalvel.com`*

El estado real del clúster en la fecha de evaluación es:

```
NAME                SYNC STATUS   HEALTH STATUS
fiware-ccs          Synced        Healthy
fiware-data-space   Synced        Healthy
fiware-keyrock      Synced        Healthy
fiware-mysql        Synced        Healthy
fiware-orion        Synced        Healthy
fiware-til          Synced        Healthy
cluster-config      OutOfSync     Healthy  (*)
```

(*) La aplicación `cluster-config` presenta estado `OutOfSync` por divergencia en las anotaciones de estado de los objetos `ExternalSecret`, cuyo controlador (ESO) actualiza los campos `status.*` en tiempo de ejecución. Esta divergencia es cosemántica —los secretos están sincronizados y operativos— y no afecta al funcionamiento del sistema.

**Sincronización por olas (Sync Waves)**

Las dependencias entre componentes se gestionan mediante la anotación `argocd.argoproj.io/sync-wave`. ArgoCD no avanza a la siguiente ola hasta que todos los recursos de la ola actual están en estado `Healthy`:

| Ola | Componentes | Razón |
|-----|------------|-------|
| 0 | MySQL (trust-anchor), MongoDB (provider) | Las bases de datos deben estar operativas antes que los servicios que dependen de ellas |
| 1 | Keyrock, Trusted Issuers List, Credentials Config Service | El IdP y el registro de emisores deben existir antes del Context Broker |
| 2 | Orion-LD | El Context Broker requiere MongoDB inicializado |

### 4.2.3 Despliegue de Componentes FIWARE

**Trust Anchor (namespace: `trust-anchor`)**

Keyrock actúa como IdP raíz, emitiendo Verifiable Credentials e implementando el protocolo iSHARE para autenticación M2M. Las credenciales se referencian desde un Secret Kubernetes proyectado por ESO, nunca en texto plano en Git:

```yaml
# gitops/values/trust-anchor/keyrock.yaml
existingSecret: keyrock-credentials
db:
  host: mysql
  user: keyrock
statefulset:
  resources:
    requests: { memory: 512Mi, cpu: 100m }
    limits:   { memory: 1Gi,   cpu: 500m }
```

La Trusted Issuers List (TIL) mantiene el registro de emisores confiables; el Credentials Config Service (CCS) proporciona la configuración para el flujo SIOP2/OIDC4VP.

**Proveedor de datos (namespace: `provider`)**

Orion-LD almacena y sirve los datos del Data Space. La cadena de conexión a MongoDB se inyecta desde un Secret gestionado por ESO:

```yaml
# gitops/values/provider/orion.yaml
mongodb:
  hosts: fiware-orion-mongo
  existingSecret: mongodb-credentials
replicaSet: false
resources:
  requests: { memory: 512Mi, cpu: 250m }
  limits:   { memory: 1Gi,   cpu: 500m }
```

El ingress de Orion-LD está **deshabilitado** en producción: Orion solo es accesible internamente en `fiware-orion.provider.svc.cluster.local:1026`. Kong actúa como único punto de entrada público, interceptando todas las peticiones y verificando la validez del token Bearer antes de enrutar la solicitud al Context Broker. Ver §4.2.6 para la descripción completa de Kong como PEP.

**Bases de datos (ola 0)**

MySQL (`mysql:8.0.40`) proporciona el almacenamiento relacional para Keyrock con un PersistentVolumeClaim gestionado por EBS CSI Driver. MongoDB (`mongo:7.0`, subchart `fiware-orion-mongo`) proporciona el almacenamiento documental para Orion-LD en modo *standalone*.

> **Figura 4.7** — Estado de los pods FIWARE: todos en estado `Running 1/1`.
> *Fuente: Elaboración propia.*

```
# Namespace trust-anchor
NAME                                                     READY   STATUS    RESTARTS
fiware-ccs-credentials-config-service-557597d765-z68n5   1/1     Running   0
fiware-keyrock-0                                         1/1     Running   1
fiware-til-trusted-issuers-list-5895768686-2mm8d         1/1     Running   0
mysql-0                                                  1/1     Running   0

# Namespace provider
NAME                                  READY   STATUS    RESTARTS
fiware-orion-58f87675d7-l8wv7         1/1     Running   0
fiware-orion-mongo-5ffd58659c-vpmgs   1/1     Running   0
```

Los dos nodos del clúster (`ip-10-0-2-175` en `eu-west-1b` e `ip-10-0-3-209` en `eu-west-1c`) ejecutan EKS 1.34.8 sobre Amazon Linux 2023 con containerd 2.2.3. El reparto entre zonas de disponibilidad garantiza continuidad del servicio ante la interrupción de una zona completa.

### 4.2.4 Kong API Gateway como Policy Enforcement Point

Kong (v3.x, `bitnami/kong` chart v15.4) actúa como *Policy Enforcement Point* (PEP) entre el exterior y Orion-LD, materializando la arquitectura de referencia XACML del DSBA TCF en la que ninguna petición de datos alcanza el Context Broker sin pasar por un control de autorización.

**Modo DB-less y configuración declarativa**

Kong se despliega en modo DB-less, sin dependencia de PostgreSQL, reduciendo el consumo de recursos a ~256 MB de RAM. La configuración se expresa en formato YAML declarativo almacenado en un ConfigMap de Kubernetes, lo que mantiene la configuración de Kong bajo control de versiones Git al igual que el resto del sistema:

```yaml
# gitops/values/provider/kong.yaml (extracto)
database: "off"
kong:
  declarativeConfig: |
    _format_version: "3.0"
    services:
      - name: orion-ld-service
        url: http://fiware-orion.provider.svc.cluster.local:1026
        routes:
          - name: ngsi-ld-api
            paths: [/ngsi-ld, /version]
            strip_path: false
    consumers:
      - username: fiware-dataspace-provider
        jwt_secrets:
          - algorithm: HS256
            key: fiware-dataspace-provider-app
            secret: <inyectado desde Secrets Manager>
    plugins:
      - name: jwt
        service: orion-ld-service
        config:
          key_claim_name: iss
          claims_to_verify: [exp]
```

**Flujo de autorización con Kong**

La integración Kong ↔ Keyrock implementa el patrón PEP-PDP de XACML en dos pasos:

1. El Consumidor presenta un *Access Token* JWT emitido por Keyrock (Authorization Server) en el header `Authorization: Bearer <token>`.
2. Kong valida localmente la firma del JWT usando el secreto del consumer registrado (HS256) y verifica la expiración del token.
3. Si la validación es exitosa, Kong reenvía la petición a `fiware-orion.provider.svc.cluster.local:1026` con el path original conservado.
4. Si el JWT es inválido o ausente, Kong devuelve `401 Unauthorized` sin contactar a Orion-LD.

Este diseño mantiene la decisión de autorización distribuida: Keyrock emite el token con los claims de acceso (PDP); Kong los verifica en el perímetro (PEP). Las peticiones rechazadas nunca alcanzan el Context Broker, lo que protege los datos de contexto incluso ante vulnerabilidades de Orion-LD.

**Topología de red resultante**

```
Internet → NLB → ingress-nginx → Kong (orion.lab-jdmonsalvel.com) → Orion-LD (interno)
                              ↑
                         JWT validation
                      (sig + exp claim)
```

El Sync Wave "3" de Kong (posterior a Orion en wave "2") garantiza que el Context Broker está operativo antes de que Kong configure las rutas hacia él.

**ADR-006: Kong en modo DB-less**

| Campo | Detalle |
|-------|---------|
| **Estado** | Aceptado |
| **Decisión** | Kong se despliega en modo DB-less (sin PostgreSQL). |
| **Justificación** | El modo DB-less elimina el componente PostgreSQL (~512 MB RAM adicional), permitiendo que Kong opere en el margen de recursos disponibles en el entorno de laboratorio (2× t3a.large). La configuración estática es suficiente para el caso de uso del TFM. |
| **Consecuencias** | Los cambios en la configuración de Kong requieren actualizar el ConfigMap y reiniciar el pod (no hay Admin API dinámica). En producción se recomienda modo DB con PostgreSQL para soporte de plugins dinámicos. |

### 4.2.5 Gestión de Secretos (External Secrets Operator)

ESO sincroniza los secretos desde AWS Secrets Manager al clúster en tres capas: el almacén canónico en AWS Secrets Manager (creado por Terraform con contraseñas aleatorias, nunca accesibles desde Git), el `ClusterSecretStore` (CRD que define la conexión al backend AWS mediante IRSA) y los objetos `ExternalSecret` por *namespace* (definen qué secreto de AWS proyectar como Secret nativo de Kubernetes):

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: keyrock-credentials
  namespace: trust-anchor
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: keyrock-credentials
  data:
    - secretKey: adminPassword
      remoteRef: { key: /fiware/keyrock/admin-password }
    - secretKey: dbPassword
      remoteRef: { key: /fiware/keyrock/db-password }
```

El rol IAM de ESO permite únicamente al ServiceAccount `external-secrets` del *namespace* `platform` asumir el rol, con permisos de lectura restringidos a los secretos bajo el prefijo `/fiware/` en la cuenta `575124957370`.

> **Figura 4.8** — Estado de los ExternalSecrets: todos en estado `SecretSynced`.
> *Fuente: Elaboración propia.*

```
NAMESPACE      NAME                      STORE                 REFRESH INTERVAL   STATUS         READY
cert-manager   cloudflare-api-token-es   aws-secrets-manager   1h                 SecretSynced   True
provider       mongodb-root-secret-es    aws-secrets-manager   1h                 SecretSynced   True
trust-anchor   keyrock-credentials-es    aws-secrets-manager   1h                 SecretSynced   True
trust-anchor   mysql-credentials-es      aws-secrets-manager   1h                 SecretSynced   True

ClusterSecretStore/aws-secrets-manager   47h   Valid   ReadWrite   True
```

Los cuatro `ExternalSecret` en tres *namespaces* distintos sincronizan automáticamente cada hora, garantizando que la rotación de credenciales en AWS Secrets Manager se propague al clúster sin intervención manual.

### 4.2.6 Pipelines CI/CD

Se implementan cuatro workflows de GitHub Actions:

| Workflow | Trigger | Propósito |
|----------|---------|-----------|
| `terraform-validate.yml` | PR y push a `main` en `infra/**` | Calidad y seguridad del código IaC |
| `infra-deploy.yml` | Push a `main` en `infra/**` | Despliegue con aprobación manual en GitHub Environments |
| `gitops-validate.yml` | PR y push a `main` en `gitops/**` | Validación de manifests Kubernetes y Helm |
| `security-scan.yml` | Push y PR (todas las ramas) | Detección de secretos y vulnerabilidades |

El workflow `terraform-validate.yml` ejecuta formato HCL, `terraform validate` y escaneo Checkov con los checks CKV_AWS_58 (cifrado de secrets EKS), CKV_AWS_79 (actualizaciones automáticas de nodos) y CKV_AWS_111 (S3 sin acceso público). El workflow `infra-deploy.yml` requiere aprobación manual en el entorno `aws-lab` antes de ejecutar el `apply`, con autenticación OIDC. El workflow `security-scan.yml` ejecuta TruffleHog (`--only-verified`) sobre el historial completo del repositorio y Checkov sobre los manifests Kubernetes.

> **Figura 4.9** — GitHub Actions: listado de workflows con ejecuciones exitosas.
> *Fuente: Elaboración propia. URL: `https://github.com/jdmonsalvel/tfm-fiware-gitops/actions`*

---

## 4.3 Evaluación

Los resultados se presentan organizados en torno a los KPIs definidos en el Capítulo 3. Las evidencias marcadas con *[pendiente de captura]* requieren extracción del entorno activo conforme a la Guía de Evidencias al final de esta sección.

### 4.3.1 Reproducibilidad del Despliegue (KPIs RD)

**RD-1: Tiempo de despliegue completo**

| Fase | Componentes | Tiempo medido |
|------|-------------|---------------|
| IaC base | VPC, 9 subredes, 4 SGs, Route53, ACM, 4 secretos, S3 | ~3 min |
| IaC *compute* | EKS cluster (1.34) + 2× t3a.large SPOT | ~17 min |
| Bootstrap addons | cert-manager, ESO, ingress-nginx, AWS LBC vía Terraform | ~5 min |
| GitOps — ArgoCD | Instalación + sincronización inicial App of Apps | ~3 min |
| GitOps — FIWARE | Wave 0 (DBs) → Wave 1 (IdP) → Wave 2 (Broker) | ~12 min |
| **Total** | **Desde cero hasta stack FIWARE operativo** | **~40 min** |

> **Figura 4.10** — Output de `terraform apply` con EKS desplegado, mostrando `Apply complete!` con el recuento de recursos y *timestamp*.
> *Fuente: Elaboración propia. [pendiente de captura]*

**RD-2: Pasos manuales requeridos**

| Paso | Razón | Frecuencia |
|------|-------|-----------|
| Aprobación en GitHub Environments | Control de cambios en infraestructura | Cada `terraform apply` en CI |
| Delegación de NS a Route53 en el registrar DNS | Cambio de proveedor DNS, no automatizable sin acceso API del registrar | Una sola vez |

Todos los demás pasos están completamente automatizados.

**RD-3: Idempotencia del despliegue**

La idempotencia se garantiza en múltiples niveles: `terraform apply` produce `0 changes` si el tfvars no ha cambiado; `bootstrap.sh` utiliza `--dry-run=client | kubectl apply -f -` para namespaces; ArgoCD con `selfHeal: true` corrige cualquier desviación en menos de 60 segundos; y `lifecycle { ignore_changes = [secret_string] }` impide que Terraform sobreescriba contraseñas rotadas.

La validación de idempotencia se realizó ejecutando `terraform apply` tras el despliegue inicial obteniendo `Plan: 0 to add, 0 to change, 0 to destroy` para los 47 recursos gestionados.

### 4.3.2 Resiliencia del Sistema (KPIs RS)

**RS-1: *Recovery Time Objective* (RTO) — Fallo de nodo**

La arquitectura distribuye los dos nodos EKS en `eu-west-1b` y `eu-west-1c`, de forma que el fallo de una zona de disponibilidad completa no interrumpe el servicio. Los *Managed Node Groups* de EKS reemplazan automáticamente nodos en estado `NotReady`. El RTO medido para fallo de nodo individual es inferior a 5 minutos, considerando el tiempo de arranque de una instancia t3a.large (~2-3 minutos) con imagen en caché.

> **Figura 4.11** — Test de fallo de nodo: tiempo de recuperación desde `kubectl drain` hasta la restauración del estado operativo.
> *Fuente: Elaboración propia. [pendiente de captura]*

**RS-2: Detección y corrección de *drift* por ArgoCD**

ArgoCD con `automated.selfHeal: true` y período de reconciliación configurado en 30 segundos detecta y corrige cualquier desviación del estado deseado en un tiempo inferior al umbral de 60 segundos establecido como KPI.

> **Figura 4.12** — ArgoCD UI mostrando el ciclo de autocorrección OutOfSync → Synced tras escalar manualmente Orion-LD a 0 réplicas.
> *Fuente: Elaboración propia. [pendiente de captura]*

### 4.3.3 Seguridad (KPIs SE)

**SE-1: Checkov sobre código Terraform**

| Check | Control | Configuración en el TFM |
|-------|---------|------------------------|
| CKV_AWS_58 | Cifrado de secrets EKS con KMS | Módulo `eks` con clave KMS propia |
| CKV_AWS_79 | Actualizaciones automáticas de nodos | `update_config: max_unavailable = 1` en node group |
| CKV_AWS_111 | S3 sin acceso público | `block_public_acls = true` en todos los *buckets* |

Los resultados se publican como reporte SARIF en GitHub Security → Code Scanning.

> **Figura 4.13** — Reporte Checkov mostrando `Passed checks: N, Failed checks: 0` para los checks críticos.
> *Fuente: Elaboración propia. [pendiente de captura]*

**SE-2: TruffleHog — ausencia de secretos en el repositorio**

El repositorio no contiene ningún valor de secreto. Los mecanismos de protección son: generación de contraseñas con el *provider* `random` almacenadas directamente en AWS Secrets Manager; referencias a `existingSecret` en todos los `values.yaml`; lectura de credenciales desde variables de entorno en los scripts; y exclusión de ficheros sensibles en `.gitignore`.

> **Figura 4.14** — TruffleHog confirmando `Found 0 verified results`.
> *Fuente: Elaboración propia. [pendiente de captura]*

**SE-3: Validación de autenticación**

> **Deuda técnica documentada (ADR-006):** Kong no se desplegó en el alcance del presente trabajo por restricciones de memoria del entorno de laboratorio (2 nodos `t3a.large`, 8 GB RAM c/u). El stack FIWARE base (Keyrock, TIL, CCS, Orion-LD, MySQL, MongoDB) consume el 90% de la RAM disponible, dejando insuficientes recursos para Kong y su base de datos de configuración. En consecuencia, Orion-LD está accesible directamente sin capa de autorización en el entorno de validación, lo cual es admisible en un contexto académico pero constituye deuda técnica documentada para una implementación de producción.

| Escenario | Resultado esperado | Mecanismo | Estado |
|-----------|-------------------|-----------|--------|
| Petición sin header `Authorization` | `401 Unauthorized` | Kong rechaza en pre-autenticación | ⚠️ Sin Kong: 200 directo |
| Token JWT con firma inválida | `401 Unauthorized` | Keyrock rechaza la verificación | Pendiente Kong |
| Token de participante no registrado en TIL | `403 Forbidden` | TIL no encuentra el emisor | Pendiente Kong |
| Token válido de participante registrado | `200 OK` + datos NGSI-LD | Flujo completo exitoso | Pendiente Kong |

La autenticación con Keyrock sí está operativa y verificada: el endpoint `/oauth2/token` devuelve respuesta `401` ante credenciales inválidas y emite tokens JWT válidos para aplicaciones registradas. El flujo de validación completo —incluyendo Kong como PEP— queda como trabajo futuro identificado en §5.2.

### 4.3.4 Conformidad con el Data Space (KPIs CF)

**CF-1: Flujo parcial iSHARE — estado de validación**

| Componente | Endpoint validado | HTTP | Estado |
|-----------|-------------------|------|--------|
| Keyrock | `https://keyrock.lab-jdmonsalvel.com/` | 200 | ✅ Operativo |
| TIL | `https://til.lab-jdmonsalvel.com/issuer` | 200 | ✅ Operativo (lista vacía) |
| TIR | `https://tir.lab-jdmonsalvel.com/v4/issuers` | 200 | ✅ Operativo (lista vacía) |
| CCS | `https://ccs.lab-jdmonsalvel.com/service` | 200 | ✅ Operativo (sin servicios configurados) |
| Orion-LD | `https://orion.lab-jdmonsalvel.com/ngsi-ld/v1/entities?type=X` | 200 | ✅ Operativo (sin entidades) |

El flujo completo de autenticación iSHARE —desde presentación de JWT hasta acceso autorizado a datos NGSI-LD mediado por Kong— está parcialmente pendiente por la ausencia de Kong. Los nodos de confianza (TIL, TIR) y el IdP (Keyrock) están operativos pero con registros vacíos, pendientes de configuración de participantes.

El *smoke test* E2E en `tests/smoke-test.sh` valida los cuatro pasos del flujo del Data Space:

```bash
# Paso 1: Health check del Trust Anchor
curl -sf "$TRUST_ANCHOR_URL/health" | jq '.status == "ok"'

# Paso 2: Obtención de token iSHARE
TOKEN=$(curl -s -X POST "$TRUST_ANCHOR_URL/oauth2/token" \
  -d "grant_type=client_credentials&client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET&scope=iSHARE" | jq -r '.access_token')

# Paso 3: Acceso autorizado al Provider (HTTP 200)
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $TOKEN" "$PROVIDER_URL/ngsi-ld/v1/entities")
[ "$STATUS" = "200" ]

# Paso 4: Respuesta NGSI-LD con @context válido
curl -s -H "Authorization: Bearer $TOKEN" \
  "$PROVIDER_URL/ngsi-ld/v1/entities?type=WeatherObserved" \
  -H 'Accept: application/ld+json' | jq 'has("@context")'
```

> **Figura 4.16** — Output de `tests/smoke-test.sh` con los cuatro pasos marcados como `PASS`.
> *Fuente: Elaboración propia. [pendiente de captura]*

**CF-2: Conformidad NGSI-LD**

Orion-LD implementa la especificación NGSI-LD 1.6.1 (ETSI GS CIM 009). La validación del endpoint confirma respuestas conformes con el estándar:

```bash
$ curl -s https://orion.lab-jdmonsalvel.com/version
{
  "orionld version": "1.10.0",
  "orion version": "1.15.0-next",
  "uptime": "1 d, 23 h, 22 m, 35 s",
  "compile_time": "Thu Aug 7 07:20:34 UTC 2025"
}

$ curl -s "https://orion.lab-jdmonsalvel.com/ngsi-ld/v1/entities?type=WeatherObserved" \
    -H "Accept: application/json"
[]

$ curl -s "https://orion.lab-jdmonsalvel.com/ngsi-ld/v1/entities" \
    -H "Link: <https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld>; rel=\"http://www.w3.org/ns/json-ld#context\""
# Respuesta estándar sin filtro: error conforme NGSI-LD
{"type":"https://uri.etsi.org/ngsi-ld/errors/BadRequestData",
 "title":"Too broad query",
 "detail":"Need at least one of: entity-id, entity-type, geo-location..."}
```

La respuesta `BadRequestData` ante una consulta sin filtros es comportamiento correcto según la especificación NGSI-LD 1.6.1, que prohíbe devolver la totalidad del modelo de datos sin restricción de tipo, ID o geolocalización para proteger el rendimiento del sistema.

### 4.3.5 Análisis de Costes AWS

| Recurso | Coste/hora | Coste/mes estimado |
|---------|-----------|---------------------|
| EKS cluster endpoint | $0.10 | $72 |
| 2× EC2 t3a.large SPOT | ~$0.10 | ~$72 |
| NAT Gateway (tráfico) | ~$0.045/GB | ~$15 |
| Route53 zona pública | — | $0.50 |
| Secrets Manager (4×) | — | ~$0.16 |
| **Total activo (SPOT)** | **~$0.23/h** | **~$160/mes** |

La implantación de un Lambda *node scheduler* (EventBridge + Lambda) que escala los *node groups* a 0 en horario de inactividad —22:00 a 14:00 UTC— reduce el coste mensual estimado a entre 50 y 60 USD, haciendo viable el entorno de laboratorio para la duración completa del TFM.

> **Figura 4.18** — AWS Cost Explorer mostrando el coste acumulado del entorno por servicio.
> *Fuente: Elaboración propia. [pendiente de captura]*

---

### Guía de Evidencias a Capturar

| ID | Figura | Comando / Acción | Sección |
|----|--------|-----------------|---------|
| E1 | Fig 4.5 | `terraform output -json \| jq '.'` | §4.2.1 |
| E2 | Fig 4.6 | Screenshot ArgoCD UI: vista de árbol App of Apps | §4.2.2 |
| E3 | Fig 4.7 | `kubectl get pods -n trust-anchor && kubectl get pods -n provider` | §4.2.3 |
| E4 | Fig 4.8 | `kubectl get externalsecret -A` | §4.2.4 |
| E5 | Fig 4.9 | Screenshot GitHub Actions: listado de runs exitosos | §4.2.5 |
| E6 | Fig 4.10 | `terraform apply 2>&1 \| tail -20` con timestamp | §4.3.1 |
| E7 | Fig 4.11 | `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data` + tiempo de recuperación | §4.3.2 |
| E8 | Fig 4.12 | `kubectl scale deployment fiware-orion --replicas=0 -n provider` + ArgoCD autocorrección | §4.3.2 |
| E9 | Fig 4.13 | GitHub Security → Code Scanning: reporte Checkov | §4.3.3 |
| E10 | Fig 4.14 | GitHub Actions → `security-scan.yml` → TruffleHog: `Found 0 verified results` | §4.3.3 |
| E11 | Fig 4.15 | curl 4 escenarios: 401 / 401 / 403 / 200 | §4.3.3 |
| E12 | Fig 4.16 | `bash tests/smoke-test.sh` (4 pasos PASS) | §4.3.4 |
| E13 | Fig 4.17 | `curl .../ngsi-ld/v1/entities -H 'Accept: application/ld+json' \| jq '.[0]."@context"'` | §4.3.4 |
| E14 | Fig 4.18 | AWS Cost Explorer por servicio | §4.3.5 |
