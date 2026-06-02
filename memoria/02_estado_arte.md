# 2. Estado del Arte

## 2.1 Espacios de Datos Europeos: Fundamentos y Marco Normativo

### 2.1.1 La Estrategia Europea de Datos

La Comisión Europea define un espacio de datos como «un marco de acuerdos técnicos y normativos que permite a personas y organizaciones compartir datos de forma segura y eficiente, manteniendo el control sobre los propios datos» (European Commission, 2020). Esta definición encierra tres principios que condicionan directamente las decisiones de diseño técnico: la soberanía sobre los datos, la interoperabilidad entre participantes y la aplicación de reglas de acceso verificables y auditables.

El marco regulatorio que materializa esta estrategia descansa en cuatro instrumentos principales:

| Instrumento | Referencia | Año | Relevancia para el trabajo |
|-------------|-----------|-----|----------------------------|
| Data Governance Act (DGA) | Reglamento UE 2022/868 | 2022 | Define los intermediarios de datos y sus obligaciones |
| Data Act | Reglamento UE 2023/2854 | 2023 | Regula el acceso a datos generados por dispositivos IoT |
| Directiva Open Data | Directiva UE 2019/1024 | 2019 | Reutilización de datos del sector público |
| AI Act | Reglamento UE 2024/1689 | 2024 | Gobernanza de datos para sistemas de inteligencia artificial |

### 2.1.2 Iniciativas de Referencia: IDSA y Gaia-X

El **International Data Spaces Reference Architecture Model** (IDSA RAM v4, IDSA, 2022) define los componentes lógicos de un Data Space mediante una arquitectura de capas: datos, servicios, conectores y gobernanza. El componente central es el *IDS Connector*, un intermediario técnico que implementa los protocolos de intercambio seguro con soporte para políticas de uso expresadas en ODRL (*Open Digital Rights Language*).

**Gaia-X** (Gaia-X, 2021) complementa el enfoque IDSA con un marco de confianza fundamentado en la verificación de atributos de participantes mediante *Verifiable Credentials* (W3C VC) y en un catálogo federado de servicios cloud conformes. Su arquitectura de referencia define tres planos funcionales: datos, control y confianza (*trust plane*).

### 2.1.3 Marco de Confianza iSHARE

iSHARE (iSHARE Foundation, 2023) es un esquema de confianza concebido originalmente para el sector logístico holandés y adoptado progresivamente como referencia técnica por la Data Spaces Business Alliance (DSBA). Define un conjunto de convenciones sobre OAuth2/OpenID Connect que habilitan la autenticación y autorización federada entre participantes que no comparten necesariamente un directorio de identidades común.

Los elementos de iSHARE con incidencia directa en el presente trabajo son los siguientes:

- **Trusted List / Satellite:** Registro de participantes certificados que actúa como ancla de confianza del ecosistema
- **iSHARE JWT:** Token de autenticación firmado con certificado eIDAS (X.509)
- **Delegation Evidence:** Mecanismo para la delegación de permisos de acceso entre participantes
- **Autorización M2M:** Flujo *client_credentials* de OAuth2 adaptado para identidades de máquina

## 2.2 FIWARE y la Especificación NGSI-LD

### 2.2.1 El Ecosistema FIWARE

FIWARE (FIWARE Foundation, 2023) es una iniciativa de código abierto, originalmente financiada por la Unión Europea en el programa FP7, que proporciona componentes reutilizables (*Generic Enablers*, GE) para el desarrollo de plataformas de datos de contexto. Su especificación técnica central es la API NGSI-LD, estandarizada por ETSI en el documento ETSI GS CIM 009 v1.6 (ETSI, 2023).

NGSI-LD extiende el modelo anterior (NGSI v2) incorporando semántica formal basada en JSON-LD y el estándar de linked data RDF, lo que permite la representación de conocimiento contextual interoperable mediante vocabularios compartidos (*context*). El modelo de datos define tres tipos de atributos para una entidad: *Property*, *Relationship* y *GeoProperty*.

> **Figura 2.1** — Modelo de datos NGSI-LD: estructura de una entidad con sus tres tipos de atributos (ver `docs/diagrams/`).

### 2.2.2 Componentes FIWARE Utilizados

**Orion-LD Context Broker** constituye la implementación de referencia de la API NGSI-LD. Gestiona el ciclo de vida de entidades de contexto —creación, actualización y suscripciones— y ofrece capacidades de notificación en tiempo real mediante el patrón *publish-subscribe*. La persistencia se realiza en MongoDB a través del driver oficial `ngsi-orion` (FIWARE Foundation, 2023b).

**Keyrock Identity Manager** implementa la gestión de identidades con soporte para OAuth2, OpenID Connect y SAML2. En el contexto de los Data Spaces actúa como servidor de autorización y evalúa políticas de control de acceso mediante el motor XACML AuthzForce CE. Su integración con iSHARE permite la validación de participantes certificados (FIWARE Foundation, 2023c).

**Kong** desempeña el rol de *Policy Enforcement Point* (PEP) y API Gateway delante de Orion-LD. Intercepta la totalidad de las solicitudes entrantes, verifica la validez del token Bearer conforme al flujo iSHARE y, en función del veredicto obtenido de Keyrock, reenvía o rechaza la solicitud hacia el Context Broker.

### 2.2.3 Análisis Comparativo: Alternativas a FIWARE

| Criterio | FIWARE (Orion-LD) | Eclipse Ditto | FROST-Server |
|---------|-------------------|---------------|-------------|
| Especificación | ETSI NGSI-LD | W3C WoT / JSON-PATCH | OGC SensorThings API |
| Modelo semántico | JSON-LD / RDF | Digital Twin Description | OGC O&M |
| Soporte NGSI-LD | Nativo | Parcial (extensión) | No |
| Integración iSHARE | Sí (Keyrock + Kong) | No nativa | No nativa |
| Licencia | AGPL-3.0 | EPL-2.0 | LGPL-3.0 |
| Madurez (producción) | Alta | Alta | Media |
| Soporte EU Dataspaces | Oficial (DSBA) | En desarrollo | No |

Del análisis comparativo se concluye que FIWARE es la alternativa más alineada con los requisitos del presente trabajo, particularmente por su integración oficial con el DSBA Technical Convergence Framework y el soporte nativo para NGSI-LD.

## 2.3 GitOps: Principios, Herramientas y Adopción

### 2.3.1 Fundamentos del Paradigma GitOps

El término GitOps fue acuñado por Weaveworks en 2017 (Limoncelli, 2018) para describir un modelo operacional en el que el estado deseado de los sistemas de producción se define de forma declarativa en un repositorio Git, y un agente de software garantiza la convergencia continua del estado real hacia dicha definición mediante bucles de reconciliación. Los cuatro principios fundamentales de GitOps, formalizados en la especificación OpenGitOps v1.0 (CNCF, 2022), son:

1. **Declarativo:** El estado del sistema se define mediante manifests declarativos, no mediante scripts imperativos.
2. **Versionado e inmutable:** El estado deseado se almacena en Git, con historial completo y capacidad de reversión.
3. ***Pull-based*:** El agente de reconciliación extrae los cambios del repositorio, en lugar de recibirlos desde sistemas externos mediante mecanismos *push*.
4. **Reconciliación continua:** El agente detecta y corrige de forma autónoma cualquier desviación entre el estado deseado y el estado real del sistema.

### 2.3.2 Comparativa ArgoCD vs FluxCD

| Criterio | ArgoCD v2.11 | FluxCD v2.3 |
|---------|-------------|------------|
| Interfaz gráfica | Sí (UI completa) | No (solo CLI) |
| Multi-tenancy | Sí (AppProjects) | Sí (Tenants) |
| Patrón App of Apps | Sí (nativo) | Sí (Kustomization) |
| Notificaciones | Plugin notifications | Sí (Alert CRD) |
| SSO / RBAC | Sí (OIDC + Dex) | Parcial |
| Soporte Helm | Sí (nativo) | Sí (HelmRelease CRD) |
| CNCF Graduated | Sí (2022) | Sí (2022) |
| Adopción enterprise | Muy alta | Alta |

La selección de ArgoCD para el presente trabajo se justifica por tres razones principales: su interfaz gráfica —que facilita la demostración y supervisión visual del estado de sincronización—, el soporte nativo para el patrón App of Apps sin dependencias adicionales, y su amplia adopción empresarial, que incrementa la transferibilidad del modelo propuesto a otros contextos organizacionales.

## 2.4 Infrastructure as Code y Kubernetes en AWS

### 2.4.1 Terraform como Herramienta IaC

Terraform (HashiCorp, 2014) es la herramienta de Infrastructure as Code más ampliamente adoptada en entornos cloud heterogéneos (HashiCorp, 2023). Su modelo de ejecución basado en grafos de dependencias, junto con la gestión de estado remoto y el ecosistema de módulos reutilizables disponibles en Terraform Registry, lo posicionan como estándar de facto para el aprovisionamiento de infraestructura reproducible. En el contexto del presente trabajo se ha desarrollado un framework de 25 módulos Terraform siguiendo las recomendaciones de la AWS EKS Best Practices Guide (AWS, 2023).

### 2.4.2 Amazon EKS y el Modelo de Responsabilidad Compartida

Amazon Elastic Kubernetes Service (EKS) proporciona un plano de control Kubernetes gestionado por AWS, eximiendo al cliente de la complejidad operacional asociada a los componentes `etcd`, `kube-apiserver` y `kube-controller-manager`. La responsabilidad del cliente se circunscribe a la gestión de los grupos de nodos (*node groups*), la configuración de red (VPC, subnets, Security Groups), las políticas IAM y la configuración de los complementos del clúster (CSI drivers, CoreDNS, kube-proxy).

## 2.5 Gestión de Secretos en Entornos Kubernetes

El mecanismo nativo de gestión de secretos en Kubernetes —objetos *Secret* codificados en base64— resulta insuficiente para entornos de producción, dado que carece de cifrado en reposo por defecto y de mecanismos de rotación automática. External Secrets Operator (ESO) resuelve esta limitación mediante la sincronización de secretos desde almacenes externos —AWS Secrets Manager, HashiCorp Vault, Azure Key Vault— hacia secretos nativos de Kubernetes, desacoplando el ciclo de vida de los secretos del ciclo de vida de las aplicaciones (External Secrets, 2023).

## 2.6 Trabajos Relacionados

La revisión de la literatura permite identificar tres categorías de trabajos previos con relevancia para el presente estudio:

- **Despliegues FIWARE en entornos cloud:** Llorente et al. (2023) presentan un análisis de despliegues FIWARE en entornos multi-cloud, sin abordar el paradigma GitOps ni la integración con marcos de Data Spaces europeos.
- **GitOps para plataformas IoT y Edge:** Rahman et al. (2022) proponen un modelo GitOps para plataformas IoT basadas en Kubernetes, sin considerar el contexto específico de los Data Spaces ni los marcos de confianza iSHARE.
- **Arquitecturas técnicas de Data Spaces:** El DSBA Technical Convergence Framework (DSBA, 2023) define la arquitectura de referencia para Data Spaces basados en FIWARE, pero no incluye guías de implementación operacional automatizada.

## 2.7 Conclusiones del Estado del Arte

Del análisis realizado se desprenden tres conclusiones que orientan el diseño del trabajo:

En primer lugar, existe una brecha significativa entre las arquitecturas de referencia para Data Spaces —IDSA RAM, Gaia-X, DSBA— y las guías de implementación operacional disponibles. Las arquitecturas definen *qué* debe existir, pero no *cómo* desplegarlo de forma reproducible y auditable.

En segundo lugar, si bien el paradigma GitOps ha demostrado su viabilidad en contextos de IoT y plataformas cloud nativas, su aplicación específica al dominio de los Data Spaces europeos —con los requisitos de confianza federada que impone iSHARE— no ha sido objeto de estudio sistemático en la literatura revisada.

En tercer lugar, FIWARE emerge como la única pila tecnológica con soporte institucional explícito por parte de la DSBA para la construcción de Data Spaces conformes con los estándares europeos, lo que justifica su selección frente a las alternativas analizadas.

El presente trabajo contribuye a cubrir la intersección de estos tres ámbitos, aportando un modelo de referencia que integra la implementación operacional GitOps con los componentes FIWARE y los marcos de confianza requeridos por el ecosistema europeo de espacios de datos.
