# 3. Objetivos y Metodología de Trabajo

## 3.1 Objetivo General

Diseñar, implementar y validar un modelo de referencia arquitectónico para el despliegue automatizado de una plataforma de Data Space basada en componentes FIWARE sobre infraestructura AWS, aplicando el paradigma GitOps con ArgoCD como mecanismo central de gestión del ciclo de vida y garantizando reproducibilidad, trazabilidad y conformidad con los estándares europeos de interoperabilidad.

## 3.2 Objetivos Específicos

- **OE-1:** Analizar y comparar los estándares, marcos de referencia y tecnologías relevantes en el ámbito de los Data Spaces europeos, GitOps y FIWARE, identificando brechas y oportunidades de integración.
- **OE-2:** Definir una arquitectura de referencia que integre los principios GitOps con los componentes FIWARE (Orion-LD, Keyrock, Kong) y el marco de confianza iSHARE/DSBA sobre infraestructura AWS EKS.
- **OE-3:** Implementar la infraestructura cloud mediante Terraform (VPC, EKS, IAM, Secrets Manager) siguiendo principios de Infrastructure as Code con gestión de estado remoto seguro.
- **OE-4:** Desarrollar el repositorio GitOps con manifests Helm y configuración ArgoCD (patrón App of Apps) que permita el despliegue declarativo y reproducible de todos los componentes de la plataforma.
- **OE-5:** Integrar pipelines de integración continua (GitHub Actions) con validación estática de seguridad, lint de manifests y gates de aprobación para cambios de infraestructura.
- **OE-6:** Validar el modelo mediante un conjunto de pruebas funcionales y métricas operacionales que incluyan tiempo de despliegue, *Recovery Time Objective* (RTO), trazabilidad de cambios y conformidad de seguridad.

## 3.3 Metodología del Trabajo

### 3.3.1 Paradigma de Investigación: Design Science Research

El presente trabajo se enmarca en el paradigma **Design Science Research** (DSR), propuesto por Hevner et al. (2004) y ampliamente consolidado en la disciplina de Sistemas de Información y Computación. A diferencia de la investigación descriptiva —orientada a explicar fenómenos existentes—, el DSR tiene por objeto la creación y evaluación de artefactos tecnológicos novedosos que resuelven problemas de ingeniería bien definidos.

Hevner (2007) describe dos ciclos fundamentales en este paradigma:

- **Ciclo de Relevancia:** El problema abordado —el despliegue automatizado de plataformas FIWARE como Data Spaces— tiene su origen en la práctica profesional y en los requisitos regulatorios del ecosistema europeo de datos. Los resultados del trabajo se evalúan en función de su utilidad práctica para dicho contexto.
- **Ciclo de Rigor:** El diseño del artefacto se sustenta en la literatura académica revisada, los estándares técnicos vigentes y las mejores prácticas de la industria, y contribuye nuevo conocimiento al campo disciplinar.

El artefacto producido es un **modelo de referencia arquitectónico** que comprende: una arquitectura de sistema documentada, código de infraestructura como código reproducible, manifests GitOps versionados y un conjunto de métricas de evaluación operacional.

### 3.3.2 Fases del Proyecto

El desarrollo se estructura en cuatro fases iterativas siguiendo el ciclo de vida del DSR:

**Fase 1 — Análisis y Diseño (Semanas 1-2)**

Revisión sistemática de literatura sobre Data Spaces, FIWARE y GitOps; análisis de los estándares ETSI GS CIM 009, IDSA RAM v4 e iSHARE Framework; definición de requisitos funcionales y no funcionales; diseño de la arquitectura de referencia con el modelo C4; y documentación de las Decisiones de Arquitectura (ADR).

*Entregables:* Documento de arquitectura (§4.1), catálogo de diagramas.

**Fase 2 — Infraestructura (Semanas 2-3)**

Implementación de módulos Terraform para VPC (3 AZs), EKS 1.34 y roles IAM; configuración de estado remoto en S3 con bloqueo en DynamoDB; configuración de políticas IAM de mínimo privilegio y roles IRSA; y validación mediante `terraform plan` y escaneo de seguridad con Checkov.

*Entregables:* Módulos Terraform funcionales, clúster EKS operativo.

**Fase 3 — Plataforma GitOps y FIWARE (Semanas 3-5)**

Bootstrap de ArgoCD con el patrón App of Apps; desarrollo de Helm values para Orion-LD, Keyrock y Kong; configuración de External Secrets Operator con AWS Secrets Manager; integración del flujo de autenticación iSHARE; y configuración de ingress-nginx con TLS mediante cert-manager y Let's Encrypt.

*Entregables:* Plataforma FIWARE desplegada y accesible vía HTTPS.

**Fase 4 — Validación y Documentación (Semanas 5-6)**

Ejecución de pruebas funcionales E2E del ciclo completo del Data Space; medición de métricas de evaluación (KPIs definidos); recopilación de evidencias del sistema en producción; y redacción final de la memoria académica.

*Entregables:* Memoria completa, repositorio GitHub con evidencias documentadas.

## 3.4 Criterios de Evaluación y KPIs

La validación del modelo propuesto se realiza mediante indicadores clave de rendimiento (KPIs) organizados en cuatro dimensiones:

**Dimensión 1 — Reproducibilidad**

| KPI | Descripción | Umbral aceptable |
|-----|-------------|------------------|
| RD-1 | Tiempo de despliegue completo desde `terraform apply` hasta plataforma operativa | < 30 minutos |
| RD-2 | Número de pasos manuales requeridos en el despliegue | ≤ 2 |
| RD-3 | Éxito en re-despliegue tras destrucción total (teardown + bootstrap) | 100% |

**Dimensión 2 — Resiliencia**

| KPI | Descripción | Umbral aceptable |
|-----|-------------|------------------|
| RS-1 | *Recovery Time Objective* (RTO) tras simulación de fallo de nodo | < 5 minutos |
| RS-2 | Tiempo de re-sincronización de ArgoCD tras *drift* manual en el clúster | < 3 minutos |

**Dimensión 3 — Seguridad**

| KPI | Descripción | Umbral aceptable |
|-----|-------------|------------------|
| SE-1 | Hallazgos críticos de Checkov sobre el código Terraform | 0 |
| SE-2 | Secretos expuestos detectados por TruffleHog en el repositorio | 0 |
| SE-3 | Solicitudes sin token JWT válido rechazadas por Kong | 100% de rechazos |

**Dimensión 4 — Conformidad con el Data Space**

| KPI | Descripción | Umbral aceptable |
|-----|-------------|------------------|
| CF-1 | Validación del flujo completo iSHARE (token → acceso a datos) | Exitoso |
| CF-2 | Respuesta correcta a consulta NGSI-LD v1.6 (`/entities`) | HTTP 200 + JSON-LD |

## 3.5 Herramientas y Tecnologías

| Categoría | Herramienta | Versión | Justificación |
|-----------|-------------|---------|---------------|
| IaC | Terraform | ≥ 1.7 | Estándar de industria; framework de módulos propio desarrollado en el trabajo |
| Orquestación | Kubernetes / EKS | 1.34 | Versión LTS disponible en AWS EKS en el momento del despliegue |
| GitOps | ArgoCD | 7.x (Helm chart) | CNCF Graduated; UI completa; soporte nativo para App of Apps |
| Empaquetado | Helm | ≥ 3.14 | Estándar para la distribución de charts en Kubernetes |
| Context Broker | Orion-LD | 1.x | Implementación de referencia NGSI-LD v1.6 |
| Identity Manager | Keyrock | 8.x | Compatible con iSHARE; Authorization Server con XACML |
| PEP / API Gateway | Kong | 3.x | API Gateway con plugin JWT para control de acceso |
| Gestión de secretos | External Secrets Operator | 0.9.x | Integración nativa con AWS Secrets Manager vía IRSA |
| CI/CD | GitHub Actions | — | Integración nativa con el repositorio; soporte para OIDC con AWS |
| Seguridad IaC | Checkov | ≥ 3.x | Escaneo de código Terraform y manifests Kubernetes |
| Seguridad Git | TruffleHog | ≥ 3.x | Detección de secretos en el historial de commits |
