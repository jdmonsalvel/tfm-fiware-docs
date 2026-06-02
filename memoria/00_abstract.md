# Resumen / Abstract

---

## Resumen (Español)

El presente trabajo aborda el diseño, implementación y validación de un modelo de referencia arquitectónico para el despliegue automatizado, reproducible y auditable de una plataforma de *Data Space* basada en componentes FIWARE sobre infraestructura de nube pública (AWS), mediante la aplicación del paradigma GitOps con ArgoCD y Helm como mecanismo central de gestión del ciclo de vida.

La motivación se fundamenta en el marco normativo europeo de gobernanza de datos: el *Data Governance Act* (DGA, Reglamento UE 2022/868), el *Data Act* (Reglamento UE 2023/2854) y la Directiva de Datos Abiertos (Directiva UE 2019/1024) configuran un ecosistema regulatorio que exige a organizaciones públicas y privadas la capacidad de compartir datos de forma segura, interoperable y conforme. En este contexto, FIWARE —respaldada por la Unión Europea y alineada con la especificación NGSI-LD (ETSI GS CIM 009)— se posiciona como la alternativa de código abierto más madura para la implementación de intermediarios de datos interoperables.

La contribución principal del trabajo consiste en la definición e implementación de un modelo integrado que combina cuatro elementos: Terraform para el aprovisionamiento reproducible de clústeres Amazon EKS, ArgoCD con el patrón *App of Apps* para la gestión declarativa de aplicaciones, el marco de confianza iSHARE/DSBA para el control de acceso federado mediante XACML y JWT, y pipelines de GitHub Actions con validación estática de seguridad mediante Checkov y TruffleHog. La plataforma se valida sobre un clúster EKS compuesto por dos nodos `t3a.large` en modalidad SPOT en la región `eu-west-1`.

**Palabras clave:** GitOps, FIWARE, Data Space, Kubernetes, Infrastructure as Code.

---

## Abstract (English)

This Master's Thesis addresses the design, implementation, and validation of a reference architectural model for the automated, reproducible, and auditable deployment of a Data Space platform based on FIWARE components on public cloud infrastructure (AWS), through the application of the GitOps paradigm using ArgoCD and Helm as the central lifecycle management mechanism.

The motivation stems from the European data governance regulatory framework: the Data Governance Act (DGA, EU Regulation 2022/868), the Data Act (EU Regulation 2023/2854), and the Open Data Directive (EU Directive 2019/1024) constitute a regulatory ecosystem that requires public and private organisations to share data in a secure, interoperable, and compliant manner. In this context, FIWARE—backed by the European Union and aligned with the NGSI-LD specification (ETSI GS CIM 009)—represents the most mature open-source alternative for implementing interoperable data intermediaries.

The main contribution consists of the definition and implementation of an integrated model combining four elements: Terraform for reproducible Amazon EKS cluster provisioning, ArgoCD with the App of Apps pattern for declarative application management, the iSHARE/DSBA trust framework for federated access control via XACML and JWT, and GitHub Actions pipelines with static security validation through Checkov and TruffleHog. The platform is validated on an EKS cluster composed of two `t3a.large` SPOT nodes in the `eu-west-1` region.

**Keywords:** GitOps, FIWARE, Data Space, Kubernetes, Infrastructure as Code.
