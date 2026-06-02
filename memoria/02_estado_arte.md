# 2. Contexto y Estado del Arte

## 2.1 Contextualización y Antecedentes

### 2.1.1 Espacios de Datos Europeos: Marco Normativo y Arquitecturas de Referencia

La Comisión Europea define un espacio de datos como «un marco de acuerdos técnicos y normativos que permite a personas y organizaciones compartir datos de forma segura y eficiente, manteniendo el control sobre los propios datos» (European Commission, 2020). Esta definición encierra tres principios que condicionan directamente las decisiones de diseño técnico: la soberanía sobre los datos, la interoperabilidad entre participantes y la aplicación de reglas de acceso verificables y auditables.

El marco regulatorio que materializa esta estrategia descansa en cuatro instrumentos principales:

| Instrumento | Referencia | Año | Relevancia para el trabajo |
|-------------|-----------|-----|----------------------------|
| Data Governance Act (DGA) | Reglamento UE 2022/868 | 2022 | Define los intermediarios de datos y sus obligaciones |
| Data Act | Reglamento UE 2023/2854 | 2023 | Regula el acceso a datos generados por dispositivos IoT |
| Directiva Open Data | Directiva UE 2019/1024 | 2019 | Reutilización de datos del sector público |
| AI Act | Reglamento UE 2024/1689 | 2024 | Gobernanza de datos para sistemas de inteligencia artificial |

Desde la perspectiva técnica, dos iniciativas articulan los estándares de referencia. El **International Data Spaces Reference Architecture Model** (IDSA RAM v4, IDSA, 2022) define los componentes lógicos de un Data Space en capas: datos, servicios, conectores y gobernanza. El componente central es el *IDS Connector*, un intermediario técnico que implementa los protocolos de intercambio seguro con soporte para políticas de uso expresadas en ODRL (*Open Digital Rights Language*). Por su parte, **Gaia-X** (Gaia-X, 2021) complementa el enfoque IDSA con un marco de confianza fundamentado en la verificación de atributos de participantes mediante *Verifiable Credentials* (W3C VC) y en un catálogo federado de servicios cloud conformes, definiendo tres planos funcionales: datos, control y confianza.

### 2.1.2 Marco de Confianza iSHARE

iSHARE (iSHARE Foundation, 2023) es un esquema de confianza concebido originalmente para el sector logístico holandés y adoptado progresivamente como referencia técnica por la Data Spaces Business Alliance (DSBA). Define un conjunto de convenciones sobre OAuth2/OpenID Connect que habilitan la autenticación y autorización federada entre participantes que no comparten necesariamente un directorio de identidades común.

Los elementos de iSHARE con incidencia directa en el presente trabajo son:

- **Trusted List / Satellite:** Registro de participantes certificados que actúa como ancla de confianza del ecosistema.
- **iSHARE JWT:** Token de autenticación firmado con certificado eIDAS (X.509).
- **Delegation Evidence:** Mecanismo para la delegación de permisos de acceso entre participantes.
- **Autorización M2M:** Flujo *client_credentials* de OAuth2 adaptado para identidades de máquina.

### 2.1.3 FIWARE y la Especificación NGSI-LD

FIWARE (FIWARE Foundation, 2023) es una iniciativa de código abierto, originalmente financiada por la Unión Europea en el programa FP7, que proporciona componentes reutilizables (*Generic Enablers*, GE) para el desarrollo de plataformas de datos de contexto. Su especificación técnica central es la API NGSI-LD, estandarizada por ETSI en el documento ETSI GS CIM 009 v1.6 (ETSI, 2023). NGSI-LD extiende el modelo anterior (NGSI v2) incorporando semántica formal basada en JSON-LD y RDF, lo que permite la representación de conocimiento contextual interoperable mediante vocabularios compartidos (*context*). El modelo de datos define tres tipos de atributos para una entidad: *Property*, *Relationship* y *GeoProperty*.

> **Figura 2.1** — Modelo de datos NGSI-LD: estructura de una entidad con sus tres tipos de atributos (ver `docs/diagrams/`).
> *Fuente: Elaboración propia basada en ETSI GS CIM 009 v1.6 (ETSI, 2023).*

Los componentes FIWARE utilizados en el presente trabajo son tres. **Orion-LD Context Broker** constituye la implementación de referencia de la API NGSI-LD: gestiona el ciclo de vida de entidades de contexto y ofrece notificaciones en tiempo real mediante *publish-subscribe*, con persistencia en MongoDB (FIWARE Foundation, 2023b). **Keyrock Identity Manager** implementa la gestión de identidades con soporte para OAuth2, OpenID Connect y SAML2, actuando como Authorization Server e integrando el marco iSHARE mediante evaluación de políticas XACML con AuthzForce CE (FIWARE Foundation, 2023c). **Kong**, por su parte, desempeña el rol de *Policy Enforcement Point* (PEP) y API Gateway, interceptando las solicitudes entrantes, verificando su conformidad con el flujo iSHARE y reenviando o rechazando las peticiones hacia el Context Broker.

**Análisis comparativo de alternativas a FIWARE**

| Criterio | FIWARE (Orion-LD) | Eclipse Ditto | FROST-Server |
|---------|-------------------|---------------|-------------|
| Especificación | ETSI NGSI-LD | W3C WoT / JSON-PATCH | OGC SensorThings API |
| Modelo semántico | JSON-LD / RDF | Digital Twin Description | OGC O&M |
| Soporte NGSI-LD | Nativo | Parcial (extensión) | No |
| Integración iSHARE | Sí (Keyrock + Kong) | No nativa | No nativa |
| Licencia | AGPL-3.0 | EPL-2.0 | LGPL-3.0 |
| Madurez (producción) | Alta | Alta | Media |
| Soporte EU Dataspaces | Oficial (DSBA) | En desarrollo | No |

### 2.1.4 GitOps: Paradigma y Herramientas

El término GitOps fue acuñado por Weaveworks en 2017 (Limoncelli, 2018) para describir un modelo operacional en el que el estado deseado de los sistemas de producción se define de forma declarativa en un repositorio Git, y un agente de software garantiza la convergencia continua del estado real hacia dicha definición. Los cuatro principios fundamentales de GitOps, formalizados en la especificación OpenGitOps v1.0 (CNCF, 2022), son: declaratividad, versionado e inmutabilidad, modelo *pull-based* y reconciliación continua.

La selección entre ArgoCD y FluxCD —los dos operadores GitOps más adoptados— es una decisión arquitectónica relevante:

| Criterio | ArgoCD v2.11 | FluxCD v2.3 |
|---------|-------------|------------|
| Interfaz gráfica | Sí (UI completa) | No (solo CLI) |
| Multi-tenancy | Sí (AppProjects) | Sí (Tenants) |
| Patrón App of Apps | Sí (nativo) | Sí (Kustomization) |
| SSO / RBAC | Sí (OIDC + Dex) | Parcial |
| Soporte Helm | Sí (nativo) | Sí (HelmRelease CRD) |
| CNCF Graduated | Sí (2022) | Sí (2022) |
| Adopción enterprise | Muy alta | Alta |

### 2.1.5 Infrastructure as Code y Gestión de Secretos en Kubernetes

Terraform (HashiCorp, 2014) es la herramienta IaC más ampliamente adoptada en entornos cloud heterogéneos (HashiCorp, 2023). Su modelo de ejecución basado en grafos de dependencias, junto con la gestión de estado remoto y el ecosistema de módulos reutilizables, lo posicionan como estándar de facto para el aprovisionamiento de infraestructura reproducible. Amazon EKS, por su parte, proporciona un plano de control Kubernetes gestionado, eximiendo al cliente de la complejidad operacional de `etcd`, `kube-apiserver` y `kube-controller-manager`, según el modelo de responsabilidad compartida de AWS.

En lo que respecta a la gestión de secretos, el mecanismo nativo de Kubernetes —objetos *Secret* codificados en base64— resulta insuficiente para entornos de producción por carecer de cifrado en reposo por defecto y de mecanismos de rotación automática. External Secrets Operator (ESO) resuelve esta limitación sincronizando secretos desde almacenes externos —AWS Secrets Manager, HashiCorp Vault, Azure Key Vault— hacia secretos nativos de Kubernetes, desacoplando el ciclo de vida de los secretos del ciclo de vida de las aplicaciones (External Secrets, 2023).

## 2.2 Trabajos Relacionados

La revisión de la literatura permite identificar tres categorías de trabajos previos con relevancia para el presente estudio:

**Despliegues FIWARE en entornos cloud.** Llorente et al. (2023) presentan un análisis comparativo de despliegues FIWARE en entornos multi-cloud, evaluando aspectos de rendimiento y disponibilidad. Sin embargo, su trabajo no aborda el paradigma GitOps ni la integración con marcos de Data Spaces europeos, limitándose a la dimensión operacional del despliegue.

**GitOps para plataformas IoT y Edge.** Rahman et al. (2022) proponen un modelo GitOps para plataformas IoT basadas en Kubernetes, demostrando la viabilidad del paradigma en entornos con dispositivos heterogéneos. No obstante, su propuesta no considera el contexto específico de los Data Spaces europeos ni los requisitos de confianza federada que impone el marco iSHARE.

**Arquitecturas técnicas de Data Spaces.** El DSBA Technical Convergence Framework (DSBA, 2023) define la arquitectura de referencia para Data Spaces basados en FIWARE, estableciendo los componentes, protocolos y patrones de integración recomendados. Sin embargo, este documento de referencia no incluye guías de implementación operacional automatizada ni aborda la integración con herramientas de tipo GitOps o IaC.

## 2.3 Conclusiones del Estado del Arte

Del análisis realizado se derivan tres conclusiones que orientan directamente el diseño del presente trabajo:

**Primera conclusión.** Existe una brecha significativa entre las arquitecturas de referencia para Data Spaces —IDSA RAM, Gaia-X, DSBA— y las guías de implementación operacional disponibles. Las arquitecturas definen *qué* debe existir en un espacio de datos, pero no *cómo* desplegarlo de forma reproducible, automatizada y auditable en infraestructura cloud real. Esta brecha es precisamente el problema que el presente trabajo se propone resolver.

**Segunda conclusión.** El paradigma GitOps ha demostrado su viabilidad en contextos de IoT y plataformas cloud nativas, pero su aplicación específica al dominio de los Data Spaces europeos —con los requisitos de confianza federada que impone iSHARE y las obligaciones regulatorias del DGA— no ha sido objeto de estudio sistemático en la literatura revisada. La intersección entre GitOps y los marcos de confianza europeos constituye, por tanto, un ámbito de contribución original.

**Tercera conclusión.** De entre las tecnologías analizadas, FIWARE emerge como la única pila con soporte institucional explícito por parte de la DSBA para la construcción de Data Spaces conformes con los estándares europeos. Su integración oficial con el DSBA Technical Convergence Framework, el soporte nativo para NGSI-LD y la compatibilidad con iSHARE mediante Keyrock justifican su selección frente a las alternativas consideradas (Eclipse Ditto, FROST-Server).

El presente trabajo contribuye a cubrir la intersección de estos tres ámbitos, aportando un modelo de referencia que integra la automatización GitOps, el aprovisionamiento IaC y los componentes FIWARE con los marcos de confianza requeridos por el ecosistema europeo de espacios de datos.
