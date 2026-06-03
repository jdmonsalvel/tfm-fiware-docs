# Anexo D. Repositorios de Código del Proyecto

El código fuente completo del trabajo se encuentra disponible públicamente en GitHub bajo la cuenta del autor. Los tres repositorios están configurados con la rama `main` protegida: se prohíben los *force pushes* y las eliminaciones de rama, y cualquier colaborador externo debe abrir un *pull request* con al menos una aprobación antes de poder fusionar cambios. El autor (propietario del repositorio) puede realizar *push* directo a `main` como administrador, lo que permite el flujo de desarrollo continuo del TFM sin fricción.

---

## D.1 Repositorio de Infraestructura y GitOps

**URL:** [https://github.com/jdmonsalvel/tfm-fiware-gitops](https://github.com/jdmonsalvel/tfm-fiware-gitops)

**Contenido principal:**

- `infra/environments/dev/terraform.tfvars` — Definición declarativa de toda la infraestructura AWS (VPC, EKS, IAM, Secrets Manager, DNS, Lambda scheduler)
- `.github/workflows/` — Cuatro pipelines de GitHub Actions (validación Terraform, despliegue con aprobación manual, validación GitOps, escaneo de seguridad)
- `gitops/apps/fiware/` — Applications ArgoCD para cada componente FIWARE (keyrock, mysql, til, ccs, orion, kong) con Sync Waves
- `gitops/values/` — Helm values parametrizados para cada componente
- `gitops/cluster-config/` — ClusterIssuer, ClusterSecretStore, ExternalSecrets e Ingress de Kong
- `scripts/` — Scripts de bootstrap, configuración DNS y teardown
- `tests/smoke-test.sh` — Test E2E del flujo completo del Data Space

**Rama principal:** `main` (protegida)

---

## D.2 Repositorio del Framework Terraform

**URL:** [https://github.com/jdmonsalvel/tfm-terraform-framework](https://github.com/jdmonsalvel/tfm-terraform-framework)

**Contenido principal:**

- `modules/aws/` — 30 módulos Terraform reutilizables (vpc, subnet, security-group, nat-gw, eks, iam, secrets-manager, s3, rds, ecr, route53, acm, kms, etc.)
- `modules/aws/eks/bootstrap/` — Submódulo para instalación de addons de plataforma vía Helm (cert-manager, ESO, ingress-nginx, AWS LBC)
- `modules/aws/eks/scheduler.tf` — Lambda + EventBridge para apagado/encendido automático de nodos
- `modules/cloudflare/dns/` — Módulo para gestión de registros DNS en Cloudflare

Todos los módulos siguen el patrón uniforme descrito en §4.2.1: variables `map(object({...}))`, recursos con `for_each` y outputs planos `{ nombre → id }`.

**Rama principal:** `main` (protegida)

---

## D.3 Repositorio de Documentación Académica

**URL:** [https://github.com/jdmonsalvel/tfm-fiware-docs](https://github.com/jdmonsalvel/tfm-fiware-docs)

**Contenido principal:**

- `memoria/` — Capítulos de la memoria en formato Markdown (00_abstract a 05_conclusiones, bibliografía y cuatro anexos)
- `memoria/Imagenes/` — Diagramas arquitectónicos: C4 Level 1 y 2, topología de red AWS, flujo iSHARE M2M, patrón App of Apps, flujo ESO+Secrets Manager, modelo de datos NGSI-LD

**Rama principal:** `main` (protegida)

---

## D.4 Configuración de protección de ramas

La protección de la rama `main` en los tres repositorios aplica las siguientes reglas:

| Regla | Configuración | Efecto |
|-------|--------------|--------|
| `enforce_admins` | `false` | El propietario puede hacer push directo (flujo de desarrollo del TFM) |
| `allow_force_pushes` | `false` (bloqueado) | Nadie puede reescribir el historial de `main` |
| `allow_deletions` | `false` (bloqueado) | La rama `main` no puede borrarse |
| `required_approving_review_count` | `1` | Colaboradores externos necesitan aprobación para mergear |
| `dismiss_stale_reviews` | `true` | Nuevos commits anulan aprobaciones previas |

Esta configuración garantiza la **integridad del historial** de los repositorios: cada commit en `main` es permanente, trazable y auditable, lo que cumple directamente con los requisitos de trazabilidad del *Data Governance Act* aplicados al ciclo de vida del sistema.

*Fuente:* Elaboración propia. Verificado en GitHub el 3 de junio de 2026.
