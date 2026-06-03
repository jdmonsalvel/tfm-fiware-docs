# Anexo B. Estructura de Repositorios y Comandos de Operación

## B.1 Repositorios del Proyecto

El proyecto se distribuye en tres repositorios públicos en GitHub bajo la organización del autor:

| Repositorio | URL | Contenido |
|------------|-----|-----------|
| `tfm-fiware-gitops` | `github.com/jdmonsalvel/tfm-fiware-gitops` | IaC Terraform + manifests GitOps ArgoCD + scripts |
| `tfm-terraform-framework` | `github.com/jdmonsalvel/tfm-terraform-framework` | Framework de módulos Terraform reutilizables |
| `tfm-fiware-docs` | `github.com/jdmonsalvel/tfm-fiware-docs` | Memoria académica y diagramas |

## B.2 Estructura de directorios — `tfm-fiware-gitops`

```
tfm-fiware-gitops/
├── .github/
│   └── workflows/
│       ├── terraform-validate.yml   # Lint + Checkov sobre infra/**
│       ├── infra-deploy.yml         # Terraform apply con aprobación manual
│       ├── gitops-validate.yml      # Helm lint + kubeconform sobre gitops/**
│       └── security-scan.yml        # TruffleHog + Checkov (todas las ramas)
├── infra/
│   └── environments/
│       └── dev/
│           └── terraform.tfvars     # Definición declarativa de toda la infraestructura
├── gitops/
│   ├── app-of-apps.yaml            # Application raíz ArgoCD
│   ├── apps/
│   │   ├── fiware/
│   │   │   ├── keyrock.yaml        # Application fiware-keyrock (wave 1)
│   │   │   ├── til.yaml            # Application fiware-til (wave 1)
│   │   │   ├── ccs.yaml            # Application fiware-ccs (wave 1)
│   │   │   ├── mysql.yaml          # Application fiware-mysql (wave 0)
│   │   │   ├── orion.yaml          # Application fiware-orion (wave 2)
│   │   │   └── kong.yaml           # Application fiware-kong (wave 3)
│   │   └── cluster-config/         # ClusterIssuer, ClusterSecretStore, ExternalSecrets
│   ├── values/
│   │   ├── trust-anchor/
│   │   │   └── keyrock.yaml        # Helm values de Keyrock
│   │   └── provider/
│   │       ├── orion.yaml          # Helm values de Orion-LD
│   │       ├── kong.yaml           # Helm values de Kong
│   │       └── mongodb.yaml        # Helm values de MongoDB
│   └── charts/                     # Charts Helm locales (keyrock, orion-ld, wilma)
├── scripts/
│   ├── bootstrap.sh                # Bootstrap ArgoCD + App of Apps
│   ├── setup-dns.sh                # Actualización DNS Cloudflare post-deploy
│   ├── create-secrets.sh           # Creación inicial de secretos en Secrets Manager
│   └── teardown.sh                 # Destrucción del entorno
└── tests/
    └── smoke-test.sh               # Test E2E del flujo completo del Data Space
```

## B.3 Comandos de operación del entorno

### Arranque del clúster (si los nodos están apagados)

```bash
# Escalar nodos a 2 manualmente
aws lambda invoke \
  --function-name tfm-dev-fiware-gitops-node-scheduler \
  --region eu-west-1 \
  --profile tfm-account-lab \
  --payload '{"action":"scale_up"}' \
  /dev/stdout

# Actualizar kubeconfig
aws eks update-kubeconfig \
  --name tfm-dev-fiware-gitops \
  --region eu-west-1 \
  --profile tfm-account-lab
```

### Estado del clúster

```bash
# Nodos
kubectl get nodes -o wide

# Todos los pods
kubectl get pods -A

# Solo pods con problemas
kubectl get pods -A --field-selector=status.phase!=Running

# Applications ArgoCD
kubectl get applications -n argocd

# Secretos sincronizados
kubectl get externalsecret -A
```

### Acceso a ArgoCD

```bash
# Acceso por URL pública (HTTPS)
# https://argocd.lab-jdmonsalvel.com
# usuario: admin
# password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Acceso por port-forward (fallback)
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Acceder en: https://localhost:8080
```

### Endpoints del Data Space

| Servicio | URL | Ruta de validación |
|---------|-----|-------------------|
| Keyrock | `https://keyrock.lab-jdmonsalvel.com` | `/` → Web UI |
| ArgoCD | `https://argocd.lab-jdmonsalvel.com` | `/` → UI GitOps |
| TIL | `https://til.lab-jdmonsalvel.com` | `/issuer` |
| TIR | `https://tir.lab-jdmonsalvel.com` | `/v4/issuers` |
| CCS | `https://ccs.lab-jdmonsalvel.com` | `/service` |
| Orion-LD | `https://orion.lab-jdmonsalvel.com` | `/ngsi-ld/v1/entities?type=X` |

### Apagado del clúster (ahorro de costes)

```bash
# Escalar nodos a 0 manualmente
aws lambda invoke \
  --function-name tfm-dev-fiware-gitops-node-scheduler \
  --region eu-west-1 \
  --profile tfm-account-lab \
  --payload '{"action":"scale_down"}' \
  /dev/stdout
```

*Nota:* El scheduler automático apaga los nodos a las 22:00 UTC (00:00 CEST) y los restaura a las 14:00 UTC (16:00 CEST) todos los días.

*Fuente:* Elaboración propia.
