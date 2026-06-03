# Anexo A. Inventario de Módulos del Framework Terraform

El presente anexo recoge el inventario completo de módulos del framework Terraform desarrollado en el trabajo (`tfm-terraform-framework`), con el recurso AWS principal que gestiona cada uno y su función en la arquitectura.

---

**Tabla A.1.**
*Módulos del framework Terraform — Inventario completo*

| Módulo | Recurso(s) AWS principal(es) | Función en la arquitectura |
|--------|------------------------------|---------------------------|
| `aws/vpc` | `aws_vpc` | VPC con Flow Logs opcionales y configuración DNS |
| `aws/subnet` | `aws_subnet`, `aws_network_acl_association` | Subredes con etiquetado de capa (pública, app, datos) |
| `aws/intenet-gw` | `aws_internet_gateway` | Internet Gateway para subredes públicas |
| `aws/nat-gw` | `aws_nat_gateway`, `aws_eip` | NAT Gateway + Elastic IP para salida de subredes privadas |
| `aws/regional-nat-gw` | `aws_nat_gateway`, `aws_eip` | NAT Gateway multi-región con EIP dedicada |
| `aws/network-acl` | `aws_network_acl`, `aws_network_acl_rule` | ACLs de red con reglas dinámicas entrada/salida |
| `aws/security-group` | `aws_security_group` | Security Groups con reglas ingress/egress parametrizadas |
| `aws/subnet-route-table` | `aws_route_table`, `aws_route`, `aws_route_table_association` | Tablas de rutas con asociación de subredes |
| `aws/dhcp` | `aws_vpc_dhcp_options`, `aws_vpc_dhcp_options_association` | Opciones DHCP personalizadas por VPC |
| `aws/transit-gw` | `aws_ec2_transit_gateway` | Transit Gateway para conectividad entre VPCs |
| `aws/transit-gw-attach` | `aws_ec2_transit_gateway_vpc_attachment` | Adjuntar VPC a Transit Gateway |
| `aws/s3` | `aws_s3_bucket` + 9 recursos de configuración | Buckets S3 con versionado, cifrado, CORS, replicación y logging |
| `aws/acm` | `aws_acm_certificate`, `aws_acm_certificate_validation` | Certificados ACM con validación DNS automática vía Route53 |
| `aws/route53` | `aws_route53_zone`, `aws_route53_record` | Zonas DNS y registros en Route53 |
| `aws/kms` | `aws_kms_key`, `aws_kms_alias` | Claves KMS para cifrado de datos en reposo |
| `aws/iam` | `aws_iam_role`, `aws_iam_policy`, `aws_iam_user`, `aws_iam_group` | Roles, políticas, usuarios y grupos IAM |
| `aws/secrets-manager` | `aws_secretsmanager_secret`, `random_password` | Secretos con generación aleatoria de contraseñas |
| `aws/db-subnet-group` | `aws_db_subnet_group` | Grupo de subredes para RDS/DocumentDB |
| `aws/rds` | `aws_db_instance` | Instancias RDS (MySQL, PostgreSQL) |
| `aws/ecr` | `aws_ecr_repository`, `aws_ecr_lifecycle_policy` | Registros de contenedores con políticas de ciclo de vida |
| `aws/keypair` | `aws_key_pair`, `tls_private_key` | Par de claves SSH con almacenamiento en SSM Parameter Store |
| `aws/ec2` | `aws_instance`, `aws_iam_role` | Instancias EC2 con perfil IAM |
| `aws/auto-scaling-group` | `aws_autoscaling_group`, `aws_lb`, `aws_lb_target_group` | Auto Scaling Groups con Load Balancer integrado |
| `aws/eks` | `aws_eks_cluster`, `aws_iam_role`, `aws_lambda_function` | Clúster EKS con addons, scheduler de nodos y OIDC |
| `aws/eks/modules/cluster` | `aws_eks_cluster`, `aws_kms_key` | Plano de control EKS con cifrado KMS |
| `aws/eks/modules/node-group` | `aws_eks_node_group`, `aws_launch_template` | Node Groups gestionados con configuración de instancia |
| `aws/eks/modules/iam` | `aws_iam_role` | Rol IAM del clúster y nodos EKS |
| `aws/eks/modules/irsa` | `aws_iam_role`, `aws_iam_policy` | IRSA (IAM Roles for Service Accounts) vía OIDC |
| `aws/eks/modules/access` | `aws_eks_access_entry`, `aws_eks_access_policy_association` | Control de acceso al clúster EKS |
| `aws/eks/bootstrap` | `helm_release`, `kubernetes_namespace_v1` | Instalación de addons de plataforma vía Helm |
| `cloudflare/dns` | `cloudflare_record` | Registros DNS en Cloudflare (CNAME, A, TXT) |

*Fuente:* Elaboración propia. Repositorio: `github.com/jdmonsalvel/tfm-terraform-framework`.

---

Todos los módulos siguen el patrón de diseño uniforme descrito en §4.2.1: variable de entrada `map(object({...}))`, recursos con `for_each`, outputs planos `{ nombre → id }` y etiquetado mediante `merge()`. La instanciación de recursos se realiza exclusivamente a través de archivos `terraform.tfvars`, sin modificar el código de los módulos.
