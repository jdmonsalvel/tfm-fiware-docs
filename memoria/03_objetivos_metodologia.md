# 3. Objetivos y Metodología de Trabajo

El presente capítulo define los objetivos del trabajo y describe el marco metodológico adoptado para alcanzarlos. En primer lugar se formula el objetivo general que orienta el conjunto de la investigación, seguido de los seis objetivos específicos que lo descomponen en contribuciones concretas y verificables. A continuación se describe la metodología de trabajo: el paradigma de investigación Design Science Research y las cuatro fases iterativas de desarrollo. El capítulo cierra con la definición de los diez indicadores clave de rendimiento (KPIs) que operacionalizan la evaluación del modelo, organizados en cuatro dimensiones, y con el inventario de herramientas y tecnologías utilizadas con su justificación de selección.

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

El presente trabajo combina dos dimensiones metodológicas complementarias. La primera es la **dimensión de investigación**, que determina el paradigma académico bajo el que se concibe y evalúa la contribución: el Design Science Research (DSR), un enfoque consolidado en Ingeniería de Sistemas de Información orientado a la creación y evaluación de artefactos tecnológicos novedosos (Hevner et al., 2004). La segunda es la **dimensión de desarrollo**, que define el proceso de construcción del sistema: una secuencia de cuatro fases iterativas que van desde el análisis y diseño hasta la validación, siguiendo el ciclo de vida propio del DSR.

La elección del DSR como paradigma se justifica por la naturaleza del problema: no se trata de un estudio descriptivo de fenómenos existentes, sino de la construcción de un artefacto técnico —el modelo de referencia arquitectónico— que resuelve un problema de ingeniería concreto y cuya contribución se evalúa en términos de su utilidad práctica y su rigor técnico. Esta combinación de relevancia práctica y rigor académico es precisamente la característica distintiva del DSR frente a otros paradigmas de investigación en Ciencias de la Computación.

El proceso de desarrollo sigue un modelo iterativo en el que las fases no son estrictamente secuenciales: los resultados de la fase de validación retroalimentan el diseño y la implementación en ciclos sucesivos. En la práctica, esto se materializa en el flujo GitOps adoptado: cada *commit* al repositorio desencadena una validación automática mediante los pipelines de CI/CD, y las discrepancias detectadas generan correcciones que se integran en el siguiente ciclo de despliegue.

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

En el paradigma Design Science Research, la evaluación del artefacto es un componente metodológico de primer orden: a diferencia de la investigación descriptiva, donde los resultados se analizan cualitativamente, el DSR requiere operacionalizar los criterios de éxito antes de comenzar la implementación, de modo que la valoración de la contribución sea objetiva y reproducible (Hevner et al., 2004). En el presente trabajo, este principio se materializa en un conjunto de diez indicadores clave de rendimiento (KPIs) definidos a priori, organizados en cuatro dimensiones que cubren los aspectos críticos del modelo propuesto: la reproducibilidad del despliegue, la resiliencia ante fallos, la postura de seguridad y la conformidad con los estándares de Data Spaces europeos.

Cada KPI incluye una descripción operacional unívoca y un umbral de aceptación cuantitativo que actúa como criterio de éxito. Los resultados obtenidos frente a estos KPIs se presentan en §4.3, donde se contrastan las mediciones del sistema en producción contra los umbrales aquí definidos. Este diseño de evaluación responde directamente al objetivo específico OE-6 y permite al evaluador del trabajo verificar de forma independiente el cumplimiento de los objetivos declarados.

La validación del modelo propuesto se realiza mediante indicadores clave de rendimiento (KPIs) organizados en cuatro dimensiones:

**Dimensión 1 — Reproducibilidad**

**Tabla 3.1.**
*KPIs de la dimensión Reproducibilidad del despliegue*

| KPI | Descripción | Umbral aceptable |
|-----|-------------|------------------|
| RD-1 | Tiempo de despliegue completo desde `terraform apply` hasta plataforma operativa | < 30 minutos |
| RD-2 | Número de pasos manuales requeridos en el despliegue | ≤ 2 |
| RD-3 | Éxito en re-despliegue tras destrucción total (teardown + bootstrap) | 100% |

*Fuente:* Elaboración propia.

**Dimensión 2 — Resiliencia**

**Tabla 3.2.**
*KPIs de la dimensión Resiliencia del sistema*

| KPI | Descripción | Umbral aceptable |
|-----|-------------|------------------|
| RS-1 | *Recovery Time Objective* (RTO) tras simulación de fallo de nodo | < 5 minutos |
| RS-2 | Tiempo de re-sincronización de ArgoCD tras *drift* manual en el clúster | < 3 minutos |

*Fuente:* Elaboración propia.

**Dimensión 3 — Seguridad**

**Tabla 3.3.**
*KPIs de la dimensión Seguridad*

| KPI | Descripción | Umbral aceptable |
|-----|-------------|------------------|
| SE-1 | Hallazgos críticos de Checkov sobre el código Terraform | 0 |
| SE-2 | Secretos expuestos detectados por TruffleHog en el repositorio | 0 |
| SE-3 | Solicitudes sin token JWT válido rechazadas por Kong | 100% de rechazos |

*Fuente:* Elaboración propia.

**Dimensión 4 — Conformidad con el Data Space**

**Tabla 3.4.**
*KPIs de la dimensión Conformidad con el Data Space*

| KPI | Descripción | Umbral aceptable |
|-----|-------------|------------------|
| CF-1 | Validación del flujo completo iSHARE (token → acceso a datos) | Exitoso |
| CF-2 | Respuesta correcta a consulta NGSI-LD v1.6 (`/entities`) | HTTP 200 + JSON-LD |

*Fuente:* Elaboración propia.

## 3.5 Herramientas y Tecnologías

La consecución de los objetivos del trabajo requiere la combinación de herramientas de distintos dominios tecnológicos que actúan de forma coordinada. La selección de cada herramienta responde a criterios de madurez industrial, conformidad con los estándares europeos de Data Spaces, disponibilidad de Helm charts mantenidos para Kubernetes y compatibilidad con los principios de IaC y GitOps adoptados. Las alternativas consideradas y los motivos de exclusión se analizan en detalle en §2.2; aquí se presenta el inventario final con la versión empleada y el rol que cada herramienta desempeña en las fases del proyecto descritas en §3.3.2.

Las herramientas se agrupan en tres bloques funcionales que se corresponden con las tres capas del sistema. El primer bloque cubre la **infraestructura cloud**: Terraform aprovisiona los recursos AWS (VPC, EKS, IAM, Secrets Manager) de forma declarativa y reproducible, con el estado almacenado de forma remota en S3. El segundo bloque cubre la **capa GitOps y orquestación**: Kubernetes (EKS 1.34) proporciona la plataforma de contenedores; ArgoCD actúa como operador GitOps con el patrón App of Apps; y Helm empaqueta y parametriza las aplicaciones FIWARE. El tercer bloque cubre los **componentes del Data Space**: Orion-LD como Context Broker NGSI-LD, Keyrock como gestor de identidades e implementación del protocolo iSHARE, Kong como Policy Enforcement Point, y External Secrets Operator para la proyección de secretos desde AWS Secrets Manager. Transversalmente, los pipelines de GitHub Actions integran la validación de seguridad con Checkov y TruffleHog en cada ciclo de integración continua.

**Tabla 3.5.**
*Herramientas y tecnologías utilizadas en el proyecto con justificación de selección*

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

*Fuente:* Elaboración propia.
