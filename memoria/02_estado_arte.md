# 2. Contexto y Estado del Arte

El presente capítulo tiene por objetivo establecer el marco de conocimiento sobre el que se fundamenta el trabajo, identificar las tecnologías disponibles en cada dominio de la solución, y justificar las decisiones de selección y exclusión adoptadas. Su lectura debe proporcionar al evaluador una comprensión sólida del estado actual del campo, la brecha que el trabajo se propone cubrir y la ventaja de la propuesta presentada frente a trabajos relacionados.

El capítulo se organiza en cuatro secciones. La §2.1 revisa el marco normativo europeo de los Data Spaces y las arquitecturas de referencia que lo materializan técnicamente (IDSA RAM, Gaia-X, DSBA), así como las tecnologías de los cuatro dominios del trabajo: gestión de identidades y confianza (iSHARE), datos de contexto (FIWARE/NGSI-LD), GitOps (ArgoCD) e Infrastructure as Code (Terraform/EKS). La §2.2 justifica explícitamente la exclusión de tecnologías relevantes en cada dominio, analizando Eclipse Dataspace Connector, FluxCD, HashiCorp Vault, Pulumi y las alternativas de plataforma de cómputo. La §2.3 analiza los trabajos relacionados identificados en la revisión de la literatura. La §2.4 presenta las conclusiones del estado del arte y establece la contribución original del trabajo.

---

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

El **Data Governance Act** (DGA) constituye el instrumento más directamente relevante para el trabajo: introduce la figura del **intermediario de datos** —entidad que facilita el intercambio entre proveedores y consumidores sin apropiarse de los datos— y establece requisitos técnicos y organizativos para su operación. Conforme al artículo 12 del DGA, el intermediario debe garantizar la trazabilidad de las operaciones de intercambio, la separación del acceso propio a los datos de los datos de sus clientes, y la no utilización de los datos intercambiados para fines distintos a los declarados. El presente trabajo implementa precisamente un intermediario de datos conforme con esta figura: la plataforma FIWARE actúa como facilitador del intercambio sin retener los datos fuera del perímetro del proveedor, y el historial Git actúa como registro de auditoría de todos los cambios en la configuración del sistema.

**Arquitecturas de referencia para Data Spaces**

Desde la perspectiva técnica, dos iniciativas articulan los estándares de referencia. El **International Data Spaces Reference Architecture Model** (IDSA RAM v4, IDSA, 2022) estructura los componentes lógicos de un Data Space en cinco capas:

| Capa | Responsabilidad | Componentes representativos |
|------|----------------|----------------------------|
| Datos | Almacenamiento y semántica | Context Brokers, Data Catalogs |
| Servicios | APIs de acceso y transformación | API Gateways, Connectors |
| Procesamiento | Ejecución de contratos y políticas | Policy Decision Points |
| Confianza | Identidad y certificación | Trust Anchors, Satellite |
| Gobernanza | Reglas del ecosistema | Certificación, auditoría |

El componente central del modelo IDSA es el **IDS Connector**, un intermediario técnico que implementa los protocolos de intercambio seguro con soporte para políticas de uso expresadas en ODRL (*Open Digital Rights Language*). A diferencia de los brokers de mensajería convencionales, el IDS Connector incorpora la negociación y aplicación de contratos de uso de datos, garantizando que los acuerdos entre partes se cumplen técnicamente de forma verificable.

**Gaia-X** (Gaia-X, 2021) complementa el enfoque IDSA con un marco de confianza fundamentado en la verificación de atributos de participantes mediante *Verifiable Credentials* (W3C, 2022a) y en un catálogo federado de servicios cloud conformes, definiendo tres planos funcionales: datos, control y confianza. La convergencia entre el modelo IDSA y Gaia-X se materializa en el **DSBA Technical Convergence Framework** (DSBA, 2023), que define la arquitectura de referencia para Data Spaces basados en FIWARE y establece los componentes específicos que deben implementarse para la conformidad con los estándares europeos.

### 2.1.2 Marco de Confianza iSHARE

iSHARE (iSHARE Foundation, 2023) es un esquema de confianza concebido originalmente para el sector logístico holandés y adoptado progresivamente como referencia técnica por la Data Spaces Business Alliance (DSBA). Define un conjunto de convenciones sobre OAuth2/OpenID Connect que habilitan la autenticación y autorización federada entre participantes que no comparten necesariamente un directorio de identidades común.

Los elementos de iSHARE con incidencia directa en el presente trabajo son:

- **Trusted List / Satellite:** Registro de participantes certificados que actúa como ancla de confianza del ecosistema. En la implementación desarrollada, la Trusted Issuers List (TIL) y el Trusted Issuers Registry (TIR) desempeñan este rol.
- **iSHARE JWT:** Token de autenticación firmado con certificado eIDAS (X.509) que acredita la identidad del participante ante otros nodos del ecosistema.
- **Delegation Evidence:** Mecanismo para la delegación de permisos de acceso entre participantes, basado en políticas expresadas en formato XACML.
- **Autorización M2M:** Flujo *client_credentials* de OAuth2 adaptado para identidades de máquina, eliminando la necesidad de intervención humana en el flujo de autenticación entre servicios.

**Comparativa con otros marcos de confianza**

| Criterio | iSHARE | SOVRIN/SSI | X.509 / PKI Clásica |
|---------|--------|------------|---------------------|
| Modelo de identidad | Federado (Satellite) | Descentralizado (DID) | Jerárquico (CA) |
| Estándar base | OAuth2/OIDC | W3C DID + VC | X.509 / PKIX |
| Adopción EU DataSpaces | Sí (DSBA recomendado) | Parcial (Gaia-X) | No (solo autenticación) |
| Granularidad políticas | Alta (XACML) | Alta (VC claims) | Baja (roles estáticos) |
| Tiempo de onboarding | Medio | Alto | Bajo |
| Certificación eIDAS | Sí (nativa) | En desarrollo | Parcial |

La selección de iSHARE sobre SSI puro obedece a su mayor madurez operacional y al respaldo institucional de la DSBA, que lo señala como el esquema de confianza de referencia para Data Spaces basados en FIWARE. La integración con certificados eIDAS garantiza la admisibilidad legal del flujo de autenticación en el contexto regulatorio europeo.

### 2.1.3 FIWARE y la Especificación NGSI-LD

FIWARE (FIWARE Foundation, 2023a) es una iniciativa de código abierto, originalmente financiada por la Unión Europea en el programa FP7, que proporciona componentes reutilizables (*Generic Enablers*, GE) para el desarrollo de plataformas de datos de contexto. Su especificación técnica central es la API NGSI-LD, estandarizada por ETSI en el documento ETSI GS CIM 009 v1.6 (ETSI, 2023). NGSI-LD extiende el modelo anterior (NGSI v2) incorporando semántica formal basada en JSON-LD y RDF, lo que permite la representación de conocimiento contextual interoperable mediante vocabularios compartidos (*context*).

El modelo de datos NGSI-LD define tres tipos de atributos para una entidad:

- **Property:** Valor primitivo (número, cadena, booleano) con metadatos opcionales de unidad y observedAt.
- **Relationship:** Referencia a otra entidad, expresada como URI, que materializa relaciones semánticas en el grafo de conocimiento.
- **GeoProperty:** Coordenadas geográficas en formato GeoJSON para soporte de operaciones geoespaciales.

> **Figura 2.1** — Modelo de datos NGSI-LD: estructura de una entidad con sus tres tipos de atributos.
> *Fuente: Elaboración propia basada en ETSI GS CIM 009 v1.6 (ETSI, 2023).*

**Componentes FIWARE del stack implementado**

Los componentes FIWARE desplegados en el presente trabajo cumplen roles arquitectónicamente diferenciados y complementarios:

**Orion-LD Context Broker** (v1.10.0) constituye la implementación de referencia de la API NGSI-LD: gestiona el ciclo de vida de entidades de contexto, ofrece notificaciones en tiempo real mediante *publish-subscribe* con soporte para filtros NGSI-LD, y persiste los datos en MongoDB con indexación geoespacial. Su versión 1.10.0 implementa la especificación ETSI GS CIM 009 v1.6 con soporte completo para *temporal representation*, *multi-attribute* y *scope* de *@context* (FIWARE Foundation, 2023b).

**Keyrock Identity Manager** (v8.3.3) implementa la gestión de identidades con soporte para OAuth2, OpenID Connect y SAML2. Actúa como Authorization Server del Data Space, integrando el marco iSHARE mediante evaluación de políticas XACML con el motor AuthzForce CE embebido. En el contexto del TFM, Keyrock desempeña el doble rol de **Trust Anchor** y **IdP** del proveedor de datos (FIWARE Foundation, 2023c).

**Kong API Gateway** (v3.x) desempeña el rol de *Policy Enforcement Point* (PEP) conforme a la arquitectura XACML, interceptando todas las solicitudes entrantes a Orion-LD y delegando la decisión de autorización en Keyrock antes de enrutar la petición.

**Análisis comparativo de Context Brokers**

| Criterio | FIWARE Orion-LD | Eclipse Ditto | FROST-Server |
|---------|-----------------|---------------|-------------|
| Especificación | ETSI NGSI-LD v1.6 | W3C WoT / JSON-PATCH | OGC SensorThings API |
| Modelo semántico | JSON-LD / RDF | Digital Twin Description | OGC O&M |
| Soporte NGSI-LD | Nativo | Parcial (extensión) | No |
| Integración iSHARE | Sí (Keyrock + Kong) | No nativa | No nativa |
| Licencia | AGPL-3.0 | EPL-2.0 | LGPL-3.0 |
| Madurez (producción) | Alta | Alta | Media |
| Soporte EU Dataspaces | Oficial (DSBA) | En desarrollo | No |
| Helm chart oficial | Sí (fiware/orion) | No | No |

La decisión de seleccionar Orion-LD se fundamenta en la combinación de soporte nativo NGSI-LD, integración oficial con el DSBA TCF, disponibilidad de Helm chart mantenido y adopción verificada en proyectos industriales europeos.

### 2.1.4 GitOps: Paradigma, Madurez y Herramientas

El término GitOps fue acuñado por Weaveworks en 2017 (Limoncelli, 2018) para describir un modelo operacional en el que el estado deseado de los sistemas de producción se define de forma declarativa en un repositorio Git, y un agente de software garantiza la convergencia continua del estado real hacia dicha definición. Los cuatro principios fundamentales de GitOps, formalizados en la especificación OpenGitOps v1.0 (CNCF, 2022), son: declaratividad, versionado e inmutabilidad, modelo *pull-based* y reconciliación continua.

En el contexto de los Data Spaces, estos principios adquieren relevancia regulatoria adicional: la auditabilidad inherente al historial de Git responde directamente a los requisitos de trazabilidad y transparencia del DGA (artículo 12), y el modelo pull elimina la necesidad de conceder acceso de escritura externo al clúster, reduciendo la superficie de ataque del sistema.

**Madurez industrial de GitOps**

El informe CNCF (2023b) documenta que el 75% de las organizaciones que adoptan Kubernetes incorporan prácticas GitOps en sus flujos de despliegue. Los estudios de Forsgren et al. (2018) en *Accelerate* identifican el despliegue continuo y la infraestructura declarativa como los dos indicadores más correlacionados con el alto rendimiento de equipos de ingeniería, medido en términos de frecuencia de despliegue, tiempo de recuperación ante fallos y tasa de cambios fallidos.

**Análisis comparativo ArgoCD vs FluxCD**

| Criterio | ArgoCD v2.14 | FluxCD v2.3 |
|---------|-------------|------------|
| Interfaz gráfica | Sí (UI completa) | No (solo CLI) |
| Multi-tenancy | Sí (AppProjects) | Sí (Tenants) |
| Patrón App of Apps | Sí (nativo) | Sí (Kustomization) |
| SSO / RBAC | Sí (OIDC + Dex) | Parcial |
| Soporte Helm | Sí (nativo) | Sí (HelmRelease CRD) |
| CNCF Graduated | Sí (2022) | Sí (2022) |
| Adopción enterprise (2024) | ~60% mercado | ~40% mercado |
| Drift detection | Continua (30s) | Continua (configurable) |
| Rollback | Manual (UI/CLI) | Automático (HelmRelease) |
| Consumo RAM (baseline) | ~512 MB | ~256 MB |

La selección de ArgoCD se justifica por su interfaz gráfica para la supervisión operacional y demostración académica, su soporte nativo para el patrón App of Apps sin dependencias adicionales y su mayor penetración en adopción empresarial. La exclusión de FluxCD se justifica en la §2.2.2.

### 2.1.5 Infrastructure as Code, Kubernetes y Gestión de Secretos

**Terraform**

Terraform (HashiCorp, 2014) es la herramienta IaC más ampliamente adoptada en entornos cloud heterogéneos, con más de 1.500 *providers* disponibles (HashiCorp, 2023). Su modelo de ejecución basado en grafos de dependencias, la gestión de estado remoto con bloqueo distribuido y el ecosistema de módulos reutilizables lo posicionan como estándar de facto para el aprovisionamiento reproducible. Humble y Farley (2010) identifican la infraestructura declarativa como un prerequisito fundamental para implementar Continuous Delivery con garantías de reproducibilidad entre entornos.

**Amazon EKS: justificación y dimensionamiento**

Amazon EKS proporciona un plano de control Kubernetes gestionado que abstrae la operación de `etcd`, `kube-apiserver` y `kube-controller-manager` (AWS, 2023). La decisión de utilizar EKS frente a alternativas se analiza en profundidad en la §2.2.3.

La selección del tipo de instancia `t3a.large` (2 vCPU, 8 GB RAM) responde al análisis de los requisitos reales de memoria del stack FIWARE completo:

| Componente | RAM request | RAM limit | Namespace |
|-----------|-------------|-----------|-----------|
| Keyrock | 512 Mi | 1 Gi | trust-anchor |
| MySQL | 256 Mi | 512 Mi | trust-anchor |
| TIL | 256 Mi | 512 Mi | trust-anchor |
| CCS | 256 Mi | 512 Mi | trust-anchor |
| Orion-LD | 256 Mi | 512 Mi | provider |
| MongoDB | 256 Mi | 512 Mi | provider |
| Kong | 256 Mi | 512 Mi | provider |
| cert-manager | 128 Mi | 256 Mi | cert-manager |
| ESO | 128 Mi | 256 Mi | platform |
| ingress-nginx | 128 Mi | 256 Mi | platform |
| ArgoCD (4 pods) | ~512 Mi | ~1 Gi | argocd |
| Sistema (kube-system) | ~400 Mi | — | kube-system |
| **Total requests** | **~3.3 Gi** | **~6.3 Gi** | — |

La memoria *allocatable* por nodo `t3a.large` es de 7.1 GB. Con dos nodos en AZs distintas, la capacidad total alcanza 14.2 GB, proporcionando un margen del 56% sobre los límites declarados. Este margen garantiza la estabilidad ante SPOT interruptions donde todos los pods migran temporalmente a un único nodo. La instancia `t3.medium` (4 GB) fue descartada empíricamente: produce condiciones OOM durante el arranque simultáneo de Keyrock y MongoDB, dado que el proceso Node.js de Keyrock carga el motor XACML de AuthzForce (~600 MB en frío).

**Gestión de secretos**

El mecanismo nativo de Kubernetes — objetos *Secret* codificados en base64— resulta insuficiente para entornos de producción por carecer de cifrado en reposo por defecto y de mecanismos de rotación automática (Kubernetes Authors, 2023). External Secrets Operator (ESO) resuelve esta limitación sincronizando secretos desde almacenes externos hacia secretos nativos de Kubernetes, mediante IRSA para la autenticación sin credenciales estáticas. La justificación de la exclusión de HashiCorp Vault como alternativa a AWS Secrets Manager se presenta en §2.2.4.

### 2.1.6 Patrones de CI/CD para Infraestructura Cloud

Los pipelines CI/CD para infraestructura cloud introducen vectores de riesgo específicos: exposición de credenciales cloud en logs, derivación de cambios no revisados hacia producción, y fallos en la detección temprana de configuraciones inseguras (Forsgren et al., 2018). Burns et al. (2016), en su análisis de la gestión de infraestructura a escala en Google, identifican la validación automatizada previa al despliegue como el mecanismo más efectivo para prevenir incidentes de seguridad en sistemas distribuidos.

La autenticación mediante **OIDC** elimina el riesgo de credenciales estáticas *long-lived*: GitHub Actions obtiene un JWT de corta duración que AWS IAM verifica para asumir el rol de despliegue. El escaneo con **Checkov** aplica controles CIS sobre el código Terraform y los manifests Kubernetes. **TruffleHog** escanea el historial completo de commits en busca de secretos con firmas verificables (Truffle Security, 2024). La justificación de la exclusión de Jenkins y GitLab CI se presenta en §2.2.5.

---

## 2.2 Análisis de Tecnologías Alternativas y Justificación de Exclusiones

Esta sección justifica de forma explícita la exclusión de tecnologías relevantes en cada dominio del trabajo. Para cada dominio se identifican las alternativas consideradas, se analizan sus características y se argumenta la razón de su no adopción en el contexto específico del trabajo.

### 2.2.1 Eclipse Dataspace Connector (EDC) vs. FIWARE/iSHARE

**Contexto de la decisión.** El Eclipse Dataspace Connector (EDC), desarrollado en el marco de la Eclipse Foundation con el respaldo del consorcio Gaia-X y del proyecto IDSA, es la implementación de referencia del protocolo IDS para el intercambio de datos B2B conforme al IDSA RAM v4. Su arquitectura se basa en el protocolo IDS Messaging Protocols y soporta políticas de uso expresadas en ODRL (W3C, 2022c). EDC es la alternativa técnica más directamente comparable al stack FIWARE/iSHARE seleccionado.

**Análisis comparativo**

| Criterio | FIWARE + iSHARE | Eclipse EDC |
|---------|-----------------|-------------|
| Especificación de datos | ETSI NGSI-LD (estándar ETSI) | Sin especificación de modelo de datos propia |
| Protocolo de intercambio | iSHARE JWT + XACML | IDS Messaging Protocols |
| Respaldo EU DataSpaces | DSBA (oficial, revisado 2023) | Gaia-X + IDSA (en convergencia) |
| Madurez Helm chart | Alta (FIWARE Foundation) | Media (en desarrollo activo) |
| Integración NGSI-LD | Nativa (Orion-LD) | No nativa (requiere adaptador) |
| Modelo de despliegue | Microservicios Kubernetes | JVM monolítico (en migración) |
| Comunidad UE | FIWARE iHubs, DSSC, i4Trust | Eclipse Foundation, Catena-X |
| Adopción en smart cities | Muy alta | Baja (foco industrial/automotriz) |

**Justificación de exclusión.** La selección de FIWARE/iSHARE frente a EDC obedece a tres razones: (1) la especificación NGSI-LD es un estándar ETSI que proporciona un modelo de datos semánticamente rico, mientras que EDC no define un modelo de datos propio; (2) el DSBA TCF (DSBA, 2023) establece explícitamente FIWARE/iSHARE como la arquitectura de referencia recomendada para Data Spaces europeos en los ámbitos de smart cities, IoT y datos de contexto; (3) la disponibilidad de Helm charts mantenidos por la FIWARE Foundation facilita el despliegue declarativo en Kubernetes, que es el objetivo central del trabajo. La integración entre FIWARE y EDC está documentada en el DSBA TCF como un área de trabajo futuro (interoperabilidad entre ecosistemas), no como un prerrequisito actual.

### 2.2.2 FluxCD como Alternativa a ArgoCD

**Contexto de la decisión.** FluxCD v2 (CNCF Graduated, 2022) es el segundo operador GitOps más adoptado. Implementa el modelo pull-based mediante el controlador `source-controller` y soporta Helm mediante el CRD `HelmRelease`.

**Justificación de exclusión.** FluxCD fue excluido por tres razones técnicas concretas: (1) carece de interfaz gráfica, lo que limita la observabilidad visual del estado del Data Space durante la demostración académica y la supervisión operacional; (2) el patrón App of Apps se implementa en FluxCD mediante `Kustomization` con dependencias explícitas entre objetos, añadiendo complejidad frente al soporte nativo de ArgoCD; (3) FluxCD no soporta Sync Waves con la misma semántica de espera activa que ArgoCD, lo que es crítico en el despliegue del Data Space donde el Trust Anchor debe estar operativo antes de que Kong configure sus políticas. El mayor consumo de RAM de ArgoCD (~512 MB frente a ~256 MB de Flux) se considera aceptable en el contexto del dimensionamiento del clúster.

### 2.2.3 Alternativas de Plataforma de Cómputo: GKE, AKS, k3s y ECS

**Google Kubernetes Engine (GKE) y Azure Kubernetes Service (AKS).** Ambas plataformas ofrecen planos de control Kubernetes gestionados con coste de control plane gratuito. GKE fue descartado por la necesidad de mantener los datos en jurisdicción de la UE conforme a los requisitos del DGA, y aunque GKE dispone de regiones europeas, la integración entre AWS IAM e IRSA es más madura que Workload Identity de GKE para el escenario específico de ESO con AWS Secrets Manager. AKS fue descartado por la menor madurez de la integración con el ecosistema de herramientas FIWARE en entornos Azure.

**k3s / Kubernetes auto-gestionado.** k3s es una distribución ligera de Kubernetes mantenida por Rancher/SUSE, apropiada para entornos edge y de laboratorio con recursos limitados. Fue evaluado inicialmente por su menor coste operativo (~$20/mes frente a ~$160/mes para EKS). Sin embargo, la ausencia de soporte para managed node groups con SPOT, la inexistencia de integración IRSA nativa y la mayor complejidad operacional del plano de control auto-gestionado justifican la preferencia por EKS como entorno de validación del modelo de referencia, cuyo objetivo es demostrar viabilidad en un entorno de producción representativo.

**Amazon ECS (Elastic Container Service).** ECS fue descartado en favor de EKS porque el ecosistema FIWARE y las herramientas GitOps (ArgoCD, ESO, cert-manager) están diseñadas para Kubernetes. Portarlas a ECS requeriría adaptaciones significativas que desviarían el foco del trabajo.

### 2.2.4 HashiCorp Vault vs. AWS Secrets Manager + ESO

**Contexto de la decisión.** HashiCorp Vault es la solución de gestión de secretos empresarial más extendida, con capacidades de rotación dinámica, generación de credenciales bajo demanda y soporte para múltiples backends de autenticación (Beyer et al., 2016).

**Justificación de exclusión.** Vault fue excluido por tres razones: (1) requiere su propio despliegue y operación en el clúster (o acceso a un servidor Vault externo), añadiendo ~512 MB de RAM y un componente de alta disponibilidad que excede el presupuesto de recursos del entorno de laboratorio; (2) la integración entre ESO y AWS Secrets Manager con IRSA proporciona las mismas garantías de seguridad —sin credenciales estáticas, con rotación automática— con menor complejidad operacional al reutilizar la capa de identidad IAM de AWS; (3) en un entorno 100% AWS como el del trabajo, AWS Secrets Manager es la opción nativa con menor superficie de ataque. En un escenario multi-cloud o on-premise, Vault sería la opción preferida.

### 2.2.5 Jenkins y GitLab CI como Alternativas a GitHub Actions

**Contexto de la decisión.** Jenkins es el servidor de CI/CD más ampliamente adoptado históricamente, con un ecosistema de plugins extenso. GitLab CI es la solución CI/CD nativa de GitLab, que integra repositorio y pipeline en una sola plataforma.

**Justificación de exclusión.** Ambas alternativas fueron descartadas por razones de integración y coste operativo: (1) GitHub Actions ofrece integración OIDC nativa con AWS IAM, eliminando la necesidad de credenciales estáticas en el pipeline, característica disponible de forma más directa que en Jenkins o GitLab CI (Forsgren et al., 2018); (2) el repositorio del trabajo está alojado en GitHub, eliminando la latencia de sincronización entre repositorio y sistema CI; (3) Jenkins requiere su propio servidor de infraestructura, aumentando el coste y la complejidad operacional del entorno de laboratorio. La selección de GitHub Actions es, por tanto, la opción de menor fricción operacional para el alcance del trabajo.

### 2.2.6 Pulumi y AWS CDK como Alternativas a Terraform

**Contexto de la decisión.** Pulumi permite definir infraestructura en lenguajes de programación de propósito general (Python, TypeScript, Go), mientras que AWS CDK genera plantillas CloudFormation mediante código Python o TypeScript.

**Justificación de exclusión.** Terraform fue seleccionado frente a Pulumi por su mayor adopción en el ecosistema DevOps y la disponibilidad del framework de módulos ya desarrollado en el contexto del máster. AWS CDK fue descartado por su dependencia exclusiva de CloudFormation (AWS-específico), lo que contradice el objetivo de reproducibilidad multi-cloud del modelo de referencia. Terraform con el *provider* de AWS proporciona las mismas capacidades con menor acoplamiento al proveedor cloud, facilitando la portabilidad del modelo a entornos Azure o GCP en trabajos futuros.

---

## 2.3 Trabajos Relacionados

La revisión de la literatura permite identificar cuatro categorías de trabajos previos con relevancia para el presente estudio: despliegues FIWARE en entornos cloud, GitOps para plataformas IoT, arquitecturas técnicas de Data Spaces europeos e IaC para plataformas cloud-native.

**Análisis sistemático de trabajos relacionados**

| Trabajo | Año | Tecnologías | Contribución | Limitación frente al TFM |
|---------|-----|------------|-------------|--------------------------|
| Llorente et al. | 2023 | FIWARE, Kubernetes, AWS/Azure | Análisis comparativo multi-cloud | Sin GitOps ni marcos de confianza europeos |
| Rahman et al. | 2022 | FluxCD, Kubernetes, IoT | GitOps para plataformas IoT | Sin Data Spaces ni iSHARE |
| DSBA TCF | 2023 | FIWARE, iSHARE, DSBA | Arquitectura de referencia DSBA | Sin implementación operacional ni código reproducible |
| DSSC (i4Trust) | 2023 | FIWARE, i4Trust | Piloto Data Space en agroalimentación | Implementación manual, sin reproducibilidad |
| HashiCorp | 2023 | Terraform, módulos reutilizables | Adopción de IaC en industria | Sin componentes FIWARE ni marcos de confianza |

**Despliegues FIWARE en entornos cloud.** Llorente et al. (2023) presentan un análisis comparativo de despliegues FIWARE en entornos multi-cloud, evaluando rendimiento y disponibilidad en AWS, Azure y GCP. El estudio identifica que los componentes de mayor consumo de recursos son Keyrock y MongoDB, y cuantifica el impacto del número de réplicas en la disponibilidad, datos coherentes con los resultados de dimensionamiento del presente trabajo. Sin embargo, los autores no abordan el paradigma GitOps ni la integración con marcos de Data Spaces europeos, limitándose a la dimensión operacional sin considerar la automatización del ciclo de vida.

**GitOps para plataformas IoT.** Rahman et al. (2022) proponen un modelo GitOps para plataformas IoT basadas en Kubernetes, demostrando la viabilidad del paradigma en entornos con dispositivos heterogéneos. Sin embargo, su propuesta no considera el contexto de los Data Spaces europeos ni los requisitos de confianza federada que impone iSHARE, y las plataformas analizadas no implementan control de acceso basado en Verifiable Credentials. Este trabajo confirma la madurez del paradigma GitOps pero no resuelve la brecha de integración con los marcos europeos.

**Arquitecturas técnicas de Data Spaces.** El DSBA TCF (DSBA, 2023) define la arquitectura de referencia para Data Spaces basados en FIWARE, estableciendo los componentes, protocolos y patrones de integración recomendados. Es el documento más directamente relacionado con el presente trabajo. Sin embargo, el TCF no incluye guías de implementación operacional automatizada, no aborda la integración con herramientas GitOps o IaC, y no proporciona código reproducible. La relación entre el TFM y el DSBA TCF es complementaria: el TCF define *qué* debe implementarse; el TFM define *cómo* implementarlo de forma automatizada y reproducible.

**Pilotos industriales de Data Spaces.** El DSSC (2023) documenta la implementación del piloto i4Trust, que validó flujos de intercambio de datos con iSHARE en el sector agroalimentario. El piloto confirma la viabilidad de FIWARE en producción real pero la implementación fue manual y ad hoc, sin abstracción en patrones reutilizables.

**IaC para plataformas cloud-native.** HashiCorp (2023) documenta que el 75% de los equipos de infraestructura utilizan módulos reutilizables en Terraform, confirmando la relevancia del enfoque del framework desarrollado en el TFM. Sin embargo, el informe no incorpora componentes FIWARE ni marcos de confianza europeos.

---

## 2.4 Conclusiones del Estado del Arte

Del análisis realizado se derivan tres conclusiones que orientan directamente el diseño del presente trabajo:

**Primera conclusión.** Existe una **brecha de implementación** verificable entre las arquitecturas de referencia europeas para Data Spaces (IDSA RAM, Gaia-X, DSBA TCF) y las guías de implementación operacional disponibles. Las arquitecturas definen *qué* componentes deben existir, pero ninguno de los trabajos revisados proporciona un modelo completo que muestre *cómo* desplegarlos de forma reproducible, automatizada y auditable en infraestructura cloud real. Esta brecha es el problema que el presente trabajo se propone resolver.

**Segunda conclusión.** El paradigma GitOps ha demostrado madurez industrial suficiente (CNCF, 2023b; Forsgren et al., 2018) pero su aplicación específica al dominio de los Data Spaces europeos —con los requisitos de confianza federada de iSHARE y las obligaciones regulatorias del DGA— no ha sido objeto de estudio sistemático. La intersección entre GitOps, FIWARE e iSHARE constituye un **ámbito de contribución original** no cubierto por ningún trabajo previo identificado.

**Tercera conclusión.** De entre las tecnologías analizadas, la combinación FIWARE/iSHARE/ArgoCD/Terraform es la más adecuada para el objetivo del trabajo. FIWARE es la única pila con soporte institucional explícito de la DSBA para Data Spaces conformes con los estándares europeos; ArgoCD es el operador GitOps con mejor soporte para el patrón App of Apps y Sync Waves, necesarios para gestionar las dependencias del Data Space; Terraform es el estándar de facto para IaC multi-cloud con mejor ecosistema de módulos. Las alternativas analizadas en §2.2 presentan limitaciones específicas —ausencia de NGSI-LD en EDC, falta de interfaz en FluxCD, dependencia AWS en CDK— que las hacen menos adecuadas para el alcance del trabajo.

**Ventaja frente a trabajos relacionados.** El presente trabajo supone un avance sustancial respecto a los trabajos analizados en §2.3 en tres dimensiones: (1) **reproducibilidad**: a diferencia de los pilotos i4Trust o los despliegues analizados por Llorente et al. (2023), el modelo del TFM es completamente reproducible desde código fuente mediante un único comando; (2) **integración completa**: a diferencia del DSBA TCF, que define la arquitectura pero no la implementa, el TFM proporciona el código completo, versionado y auditado en Git; (3) **conformidad GitOps**: a diferencia de Rahman et al. (2022), que aplican GitOps a IoT genérico, el TFM lo aplica específicamente al contexto de Data Spaces europeos con sus requisitos de confianza federada y trazabilidad regulatoria.

Las conclusiones de este capítulo fundamentan directamente las decisiones de diseño del Capítulo 4: la selección de ArgoCD con Sync Waves responde a la necesidad de gestionar las dependencias del Trust Anchor; la selección del patrón App of Apps responde a la necesidad de un único punto de entrada reproducible; y la selección de IRSA + ESO responde al requisito de gestión de secretos sin credenciales estáticas que impone el DGA.
