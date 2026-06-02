# 5. Implementación

El presente capítulo describe la implementación técnica del sistema GitOps para FIWARE Data Spaces en AWS, estructurada en tres capas funcionales: aprovisionamiento de infraestructura mediante Terraform, orquestación GitOps a través de ArgoCD, y despliegue de los componentes FIWARE mediante Helm.

## 5.1 Aprovisionamiento de Infraestructura con Terraform

### 5.1.1 Framework de Módulos Reutilizables

La infraestructura se organiza mediante un framework de 25 módulos Terraform reutilizables ubicados en `tfm-terraform-framework/modules/aws/`. El patrón de diseño es uniforme en todos los módulos:

- **Variable de entrada:** `map(object({...}))` — permite definir múltiples instancias del recurso en un único bloque de configuración.
- **Recursos:** `for_each` sobre el mapa, generando un recurso por entrada.
- **Outputs planos:** `{ nombre → id }` y `{ nombre → arn }` — compatibles con el lookup directo desde el módulo raíz.
- **Tags:** `merge(var.tags, each.value.tags, { Name = each.value.name })` en todos los recursos.

El módulo raíz actúa como orquestador: instancia cada módulo con `count = length(var.<recurso>) > 0 ? 1 : 0`, resuelve los nombres a IDs en `locals.tf` y los pasa a los módulos dependientes:

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

Los módulos implementados cubren la totalidad de los recursos necesarios para el entorno de laboratorio:

| Módulo | Recurso principal |
|--------|-------------------|
| `vpc` | `aws_vpc` con Flow Logs opcionales |
| `subnet` | `aws_subnet` con asociación a ACL de red |
| `network-acl` | `aws_network_acl` con reglas dinámicas |
| `security-group` | `aws_security_group` con ingress/egress dinámicos |
| `subnet-route-table` | `aws_route_table` + asociaciones por subnet |
| `nat-gw` | `aws_nat_gateway` + EIP |
| `s3` | Buckets S3 con versionado y cifrado obligatorio |
| `acm` | Certificados ACM con validación DNS |
| `route53` | Zonas y registros Route53 |
| `secrets-manager` | Secretos en AWS Secrets Manager con generación de contraseñas |
| `iam` | Roles, políticas y usuarios IAM |
| `eks` | Clúster EKS + node groups + IRSA + bootstrap de addons Helm |

### 5.1.2 Arquitectura de Red en Tres Capas

La VPC `fiware-vpc` (`10.0.0.0/16`) en `eu-west-1` implementa tres capas con nueve subnets distribuidas en tres AZs:

```
fiware-vpc (10.0.0.0/16)  ·  eu-west-1
├── PÚBLICA  (10.0.101-103.0/24)  → Internet Gateway
│     Recursos: NLB (ingress-nginx), NAT Gateway EIPs
├── APLICACIÓN (10.0.1-3.0/24)   → NAT Gateway
│     SG: eks-node-sg  (todo el tráfico VPC - protocolo -1)
│     Recursos: nodos EKS (2× t3a.large SPOT)
└── DATOS (10.0.11-13.0/24)      → NAT Gateway
      SG: data-sg  (ingress exclusivo desde eks-node-sg)
           ├── 27017/TCP  MongoDB  (Orion-LD)
           ├── 3306/TCP   MySQL    (Keyrock)
           └── 5432/TCP   PostgreSQL
```

Las reglas entre Security Groups se gestionan con `aws_vpc_security_group_ingress_rule` a nivel del módulo raíz, después de que el módulo `security-group` ha creado todos los SGs. Este orden evita dependencias circulares:

```hcl
resource "aws_vpc_security_group_ingress_rule" "cross_sg" {
  for_each = var.security_group_rules

  security_group_id            = module.security_group.security_group_ids[each.value.sg_name]
  referenced_security_group_id = module.security_group.security_group_ids[each.value.source_sg_name]
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  ip_protocol = each.value.ip_protocol
}
```

### 5.1.3 Gestión de Estado Remoto

El estado de Terraform se almacena en S3 con las siguientes características de seguridad:

- **Bucket:** `devops-575124957370-terraform-state-bucket`
- **Key:** `terraform-aws-tfm-lab-eu-west-1.tfstate`
- **Versionado:** habilitado (recuperación ante corrupción de estado)
- **Cifrado:** SSE-S3 (Server-Side Encryption)
- **Bloqueo:** DynamoDB tabla `terraform-lock`
- **Acceso:** restringido mediante política de bucket a la identidad IAM del pipeline CI/CD

### 5.1.4 Gestión de Secretos en Terraform

El módulo `secrets-manager` genera contraseñas con el provider `random` y las almacena en AWS Secrets Manager. La clave del diseño es `lifecycle { ignore_changes = [secret_string] }`: garantiza que Terraform no sobreescriba contraseñas rotadas manualmente tras el primer despliegue.

```hcl
resource "random_password" "generated" {
  for_each = { for k, v in var.secrets_manager_secrets : k => v if v.generate_password }
  length   = 32
  special  = false   # solo alfanumérico — compatible con cadenas de conexión MySQL/MongoDB
}

resource "aws_secretsmanager_secret_version" "secret" {
  for_each      = var.secrets_manager_secrets
  secret_id     = aws_secretsmanager_secret.secret[each.key].id
  secret_string = each.value.generate_password ? random_password.generated[each.key].result : each.value.secret_string
  lifecycle {
    ignore_changes = [secret_string]
  }
}
```

Se crean cuatro secretos FIWARE bajo el prefijo `/fiware/`:

| Secreto | Uso |
|---------|-----|
| `/fiware/keyrock/admin-password` | Contraseña del administrador de Keyrock |
| `/fiware/keyrock/db-password` | Contraseña de la base de datos de Keyrock |
| `/fiware/mysql/root-password` | Contraseña root de MySQL |
| `/fiware/mongodb/root-password` | Contraseña root de MongoDB |

### 5.1.5 Autenticación AWS en CI/CD (OIDC)

La autenticación entre GitHub Actions y AWS se implementa mediante OpenID Connect (OIDC), eliminando la necesidad de credenciales estáticas en los secretos del repositorio. El flujo es:

1. GitHub Actions solicita un token JWT firmado por el proveedor OIDC `token.actions.githubusercontent.com`
2. AWS IAM verifica el token contra el proveedor OIDC registrado en la cuenta `575124957370`
3. Se asume el rol `github-actions-terraform-role` mediante `AssumeRoleWithWebIdentity`
4. Terraform ejecuta con las credenciales temporales del rol asumido

```yaml
- name: Configure AWS credentials (OIDC)
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::575124957370:role/github-actions-terraform-role
    aws-region: eu-west-1
    role-session-name: github-actions-terraform
```

### 5.1.6 Bootstrap de Addons de Plataforma vía Terraform

El módulo EKS incluye un sub-módulo `bootstrap/` que se ejecuta como un segundo root de Terraform después de crear el clúster. Instala los componentes de plataforma directamente via Helm, sin pasar por ArgoCD. Este diseño resuelve el problema de bootstrap: los addons son prerrequisitos para que ArgoCD funcione, por lo que no pueden ser gestionados por el propio ArgoCD.

| Addon | Helm Chart | Namespace |
|-------|-----------|-----------|
| AWS Load Balancer Controller | `eks/aws-load-balancer-controller` | `kube-system` |
| cert-manager | `jetstack/cert-manager` | `cert-manager` |
| External Secrets Operator | `external-secrets/external-secrets` | `platform` |
| ingress-nginx | `ingress-nginx/ingress-nginx` | `platform` |
| metrics-server | `metrics-server/metrics-server` | `kube-system` |

El bootstrap se ejecuta mediante `terraform_data.local-exec` dentro del módulo EKS, con el script `scripts/bootstrap.sh` del framework:

```bash
# Fragmento de scripts/bootstrap.sh
bash "scripts/bootstrap.sh" \
  "${cluster_name}" \
  "${module_path}/bootstrap" \
  "${module_path}/bootstrap/generated/${cluster_name}.tfvars.json"
```

> **Figura 5.1** — Output de `terraform apply` con EKS desplegado, mostrando recursos creados y outputs con `eks_cluster_endpoint` e IRSAs.
> *Capturar con: `terraform output -json | jq '.'`*

## 5.2 Bootstrap del Operador GitOps (ArgoCD)

### 5.2.1 Instalación de ArgoCD

ArgoCD se instala mediante `scripts/bootstrap.sh` del repositorio gitops en el namespace `argocd`. El script está diseñado para ser idempotente: verifica si cada componente ya existe antes de crearlo.

```bash
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
helm repo add argo https://argoproj.github.io/argo-helm && helm repo update

helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --version "7.*" \
  --wait --timeout 300s

# Aplicar la Application raíz — desencadena la sincronización de todo el stack
kubectl apply -f gitops/apps/app-of-apps.yaml
```

> **Figura 5.2** — ArgoCD UI mostrando el App of Apps con todas las Applications en estado Synced/Healthy.
> *URL: `https://argocd.lab-jdmonsalvel.com` — capturar screenshot de la vista de árbol.*

### 5.2.2 Patrón App of Apps

La Application raíz (`gitops/apps/app-of-apps.yaml`) apunta al directorio `gitops/apps/` con `directory.recurse: true`. ArgoCD detecta automáticamente todos los manifests de tipo `Application` en ese directorio y los gestiona como árbol jerárquico.

```yaml
# gitops/apps/app-of-apps.yaml
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

La política `automated.selfHeal: true` garantiza que cualquier desviación entre el estado del clúster y el repositorio Git sea corregida automáticamente — el principio de reconciliación continua de GitOps en acción.

### 5.2.3 Sincronización por Olas (Sync Waves)

Las dependencias entre componentes se gestionan con la anotación `argocd.argoproj.io/sync-wave`. ArgoCD no avanza a la siguiente ola hasta que todos los recursos de la ola actual están en estado `Healthy`:

| Ola | Componentes | Razón |
|-----|------------|-------|
| 0 | MySQL (trust-anchor), MongoDB (provider) | Bases de datos deben estar listas antes de los servicios |
| 1 | Keyrock, Trusted Issuers List, Credentials Config Service | IdP y registro de emisores antes del broker |
| 2 | Orion-LD | El Context Broker requiere MongoDB inicializado |

```yaml
# Ejemplo: fiware-keyrock.yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"
```

Esta secuencia evita errores de conexión durante el arranque: Keyrock no intenta conectar a MySQL hasta que el pod está `Running`, y Orion-LD no conecta a MongoDB hasta que la base de datos está disponible.

## 5.3 Despliegue de Componentes FIWARE

### 5.3.1 Trust Anchor (namespace: `trust-anchor`)

El Trust Anchor comprende tres componentes que implementan la infraestructura de identidad del Data Space:

**Keyrock** actúa como Identity Provider (IdP) raíz. Emite Verifiable Credentials e implementa el protocolo iSHARE para autenticación M2M. Las credenciales se referencian desde un Secret Kubernetes proyectado por ESO — nunca van en texto plano en Git:

```yaml
# gitops/values/trust-anchor/keyrock.yaml
existingSecret: keyrock-credentials   # K8s Secret proyectado por ESO desde AWS Secrets Manager
db:
  host: mysql
  user: keyrock
statefulset:
  resources:
    requests:
      memory: 512Mi
      cpu: 100m
    limits:
      memory: 1Gi
      cpu: 500m
```

**Trusted Issuers List (TIL)** mantiene el registro de emisores de credenciales confiables del Data Space, implementando la lista de autoridades reconocidas.

**Credentials Config Service (CCS)** proporciona la configuración de credenciales requerida por el flujo de autorización SIOP2/OIDC4VP.

### 5.3.2 Proveedor de Datos (namespace: `provider`)

**Orion-LD** es el Context Broker NGSI-LD que almacena y sirve los datos del Data Space. La cadena de conexión a MongoDB se inyecta desde un Kubernetes Secret gestionado por ESO:

```yaml
# gitops/values/provider/orion.yaml
mongodb:
  hosts: fiware-orion-mongo
  existingSecret: mongodb-credentials
replicaSet: false   # standalone en entorno de laboratorio
resources:
  requests:
    memory: 512Mi
    cpu: 250m
  limits:
    memory: 1Gi
    cpu: 500m
```

**Kong** actúa como PEP/API Gateway delante de Orion-LD, interceptando todas las peticiones y verificando que el token Bearer presentado es válido según el flujo iSHARE antes de enrutar la solicitud al Context Broker.

> **Figura 5.3** — Estado de los pods FIWARE: todos en estado `Running 1/1`.
> *Capturar con: `kubectl get pods -n trust-anchor && kubectl get pods -n provider`*

### 5.3.3 Bases de Datos (ola 0)

**MySQL** (`mysql:8.0.40`) proporciona el almacenamiento relacional para Keyrock, desplegado en el namespace `trust-anchor` en la ola 0. Utiliza un PersistentVolumeClaim gestionado por EBS CSI Driver (instalado vía IRSA en el módulo EKS).

**MongoDB** (`mongo:7.0` via subchart `fiware-orion-mongo`) proporciona el almacenamiento documental para Orion-LD, desplegado en el namespace `provider` en la ola 0 en modo standalone.

## 5.4 Gestión de Secretos (External Secrets Operator)

### 5.4.1 Arquitectura ESO

External Secrets Operator sincroniza los secretos desde AWS Secrets Manager al clúster Kubernetes en tres capas:

1. **AWS Secrets Manager:** Almacén canónico. Creados por Terraform con contraseñas generadas aleatoriamente. Nunca accesibles desde Git.
2. **ClusterSecretStore:** CRD de ESO que define la conexión al backend de AWS Secrets Manager, usando IRSA para autenticación sin credenciales estáticas.
3. **ExternalSecret:** CRD por namespace que define qué secreto de AWS proyectar como `Secret` nativo de Kubernetes, con qué nombre y con qué `refreshInterval`.

```yaml
# ClusterSecretStore
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: aws-secrets-manager
spec:
  provider:
    aws:
      service: SecretsManager
      region: eu-west-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets
            namespace: platform
---
# ExternalSecret para Keyrock
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
      remoteRef:
        key: /fiware/keyrock/admin-password
    - secretKey: dbPassword
      remoteRef:
        key: /fiware/keyrock/db-password
```

> **Figura 5.4** — Estado de los ExternalSecrets: todos en estado `SecretSynced`.
> *Capturar con: `kubectl get externalsecret -A`*

### 5.4.2 IRSA para ESO

El rol IAM de ESO se crea automáticamente por el módulo EKS. Tiene una política de confianza que permite únicamente al Service Account `external-secrets` del namespace `platform` asumir el rol, con permisos de solo lectura a secretos bajo el prefijo `/fiware/`:

```json
{
  "Effect": "Allow",
  "Action": ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
  "Resource": "arn:aws:secretsmanager:eu-west-1:575124957370:secret:/fiware/*"
}
```

## 5.5 Pipeline CI/CD

### 5.5.1 Visión General

Se implementan cuatro workflows de GitHub Actions que cubren el ciclo de vida completo del repositorio:

| Workflow | Trigger | Propósito |
|----------|---------|-----------|
| `terraform-validate.yml` | PR y push a `main` en `infra/**` | Calidad y seguridad del código IaC |
| `infra-deploy.yml` | Push a `main` en `infra/**` | Despliegue automático con aprobación manual |
| `gitops-validate.yml` | PR y push a `main` en `gitops/**` | Validación de manifests Kubernetes y Helm |
| `security-scan.yml` | Push y PR (todas las ramas) | Detección de secretos y vulnerabilidades |

> **Figura 5.5** — GitHub Actions: listado de workflows con ejecuciones exitosas (check verde).
> *Capturar screenshot desde: `https://github.com/jdmonsalvel/tfm-fiware-gitops/actions`*

### 5.5.2 `terraform-validate.yml`

Ejecutado en pull requests y pushes sobre `infra/**`. Realiza tres validaciones en secuencia:

```yaml
steps:
  - name: Terraform Format Check
    run: terraform fmt -check -recursive

  - name: Terraform Init (no backend)
    run: terraform init -backend=false

  - name: Terraform Validate
    run: terraform validate

  - name: Run Checkov
    uses: bridgecrewio/checkov-action@v12
    with:
      framework: terraform
      check: CKV_AWS_58,CKV_AWS_79,CKV_AWS_111,CKV_AWS_115,CKV_AWS_116,CKV_AWS_117
```

Los checks de Checkov verifican: cifrado de secrets EKS con KMS (CKV_AWS_58), actualizaciones automáticas de nodos (CKV_AWS_79) y acceso público bloqueado en S3 (CKV_AWS_111).

### 5.5.3 `infra-deploy.yml`

Ejecutado exclusivamente en push a `main` en `infra/**`. Requiere aprobación manual en el entorno `aws-lab` de GitHub Environments antes de ejecutar el `apply`:

```yaml
jobs:
  apply:
    environment: aws-lab    # bloquea hasta aprobación manual en GitHub UI
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::575124957370:role/github-actions-terraform-role
          aws-region: eu-west-1
      - run: terraform plan -var-file="environments/dev/terraform.tfvars" -out=tfplan
      - run: terraform apply tfplan
      - run: terraform output -json 2>/dev/null || true
```

### 5.5.4 `gitops-validate.yml`

Valida todos los manifests Kubernetes y charts Helm antes de que ArgoCD los aplique al clúster:

```yaml
steps:
  - name: Helm Lint (trust-anchor)
    run: helm lint gitops/values/trust-anchor/ --strict

  - name: Kubeconform
    run: |
      kubeconform -schema-location default \
        -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
        -kubernetes-version 1.34.0 \
        gitops/apps/
```

### 5.5.5 `security-scan.yml`

TruffleHog en cada push detecta secretos comprometidos en el historial Git completo; Checkov sobre manifests Kubernetes verifica configuraciones de seguridad:

```yaml
steps:
  - name: TruffleHog OSS
    uses: trufflesecurity/trufflehog@main
    with:
      path: ./
      base: ${{ github.event.repository.default_branch }}
      extra_args: --debug --only-verified

  - name: Checkov K8s manifests
    uses: bridgecrewio/checkov-action@v12
    with:
      directory: gitops/
      framework: kubernetes
```
