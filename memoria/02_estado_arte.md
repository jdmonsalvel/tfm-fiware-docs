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

El **Data Governance Act** (DGA) constituye el instrumento más directamente relevante para el trabajo: introduce la figura del **intermediario de datos** —entidad que facilita el intercambio entre proveedores y consumidores sin apropiarse de los datos— y establece requisitos técnicos y organizativos para su operación. El presente trabajo implementa precisamente un intermediario de datos conforme con esta figura, dado que la plataforma FIWARE actúa como facilitador del intercambio sin retener los datos fuera del perímetro del proveedor.

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

**Gaia-X** (Gaia-X, 2021) complementa el enfoque IDSA con un marco de confianza fundamentado en la verificación de atributos de participantes mediante *Verifiable Credentials* (W3C VC) y en un catálogo federado de servicios cloud conformes, definiendo tres planos funcionales: datos, control y confianza. La convergencia entre el modelo IDSA y Gaia-X se materializa en el **DSBA Technical Convergence Framework** (DSBA, 2023), que define la arquitectura de referencia para Data Spaces basados en FIWARE y establece los componentes específicos que deben implementarse para la conformidad con los estándares europeos.

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

FIWARE (FIWARE Foundation, 2023) es una iniciativa de código abierto, originalmente financiada por la Unión Europea en el programa FP7, que proporciona componentes reutilizables (*Generic Enablers*, GE) para el desarrollo de plataformas de datos de contexto. Su especificación técnica central es la API NGSI-LD, estandarizada por ETSI en el documento ETSI GS CIM 009 v1.6 (ETSI, 2023). NGSI-LD extiende el modelo anterior (NGSI v2) incorporando semántica formal basada en JSON-LD y RDF, lo que permite la representación de conocimiento contextual interoperable mediante vocabularios compartidos (*context*).

El modelo de datos NGSI-LD define tres tipos de atributos para una entidad:

- **Property:** Valor primitivo (número, cadena, booleano) con metadatos opcionales de unidad y observedAt.
- **Relationship:** Referencia a otra entidad, expresada como URI, que materializa relaciones semánticas en el grafo de conocimiento.
- **GeoProperty:** Coordenadas geográficas en formato GeoJSON para soporte de operaciones geoespaciales.

> **Figura 2.1** — Modelo de datos NGSI-LD: estructura de una entidad con sus tres tipos de atributos (ver `docs/diagrams/`).
> *Fuente: Elaboración propia basada en ETSI GS CIM 009 v1.6 (ETSI, 2023).*

**Componentes FIWARE del stack implementado**

Los tres componentes FIWARE desplegados en el presente trabajo cumplen roles arquitectónicamente diferenciados:

**Orion-LD Context Broker** (v1.10.0) constituye la implementación de referencia de la API NGSI-LD: gestiona el ciclo de vida de entidades de contexto, ofrece notificaciones en tiempo real mediante *publish-subscribe* con soporte para filtros NGSI-LD, y persiste los datos en MongoDB con indexación geoespacial. Su versión 1.10.0 implementa la especificación ETSI GS CIM 009 v1.6 con soporte completo para *temporal representation*, *multi-attribute* y *scope* de *@context* (FIWARE Foundation, 2023b).

**Keyrock Identity Manager** (v8.3.3) implementa la gestión de identidades con soporte para OAuth2 (*authorization_code*, *client_credentials*, *implicit*, *resource_owner*), OpenID Connect y SAML2. Actúa como Authorization Server del Data Space, integrando el marco iSHARE mediante evaluación de políticas XACML con el motor AuthzForce CE embebido. En el contexto del TFM, Keyrock desempeña el doble rol de **Trust Anchor** (emisor de credenciales verificables) y **IdP** del proveedor de datos (FIWARE Foundation, 2023c).

**Kong API Gateway** (v3.x) desempeña el rol de *Policy Enforcement Point* (PEP) conforme a la arquitectura XACML, interceptando todas las solicitudes entrantes a Orion-LD y delegando la decisión de autorización en Keyrock antes de enrutar la petición. En la implementación desarrollada, Kong se configura en modo DB-less con configuración declarativa en un ConfigMap de Kubernetes, sin dependencia de base de datos externa, minimizando el consumo de recursos en el entorno de laboratorio.

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

La decisión de seleccionar Orion-LD se fundamenta en la combinación de soporte nativo NGSI-LD, integración oficial con el DSBA Technical Convergence Framework, disponibilidad de Helm chart mantenido y adopción verificada en proyectos industriales europeos.

### 2.1.4 GitOps: Paradigma, Madurez y Herramientas

El término GitOps fue acuñado por Weaveworks en 2017 (Limoncelli, 2018) para describir un modelo operacional en el que el estado deseado de los sistemas de producción se define de forma declarativa en un repositorio Git, y un agente de software garantiza la convergencia continua del estado real hacia dicha definición. Los cuatro principios fundamentales de GitOps, formalizados en la especificación OpenGitOps v1.0 (CNCF, 2022), son:

1. **Declaratividad:** El sistema se describe en términos de *qué* debe existir, no de *cómo* crearlo. Esto elimina la ambigüedad de los procedimientos operativos manuales.
2. **Versionado e inmutabilidad:** El historial de Git actúa como registro de auditoría inmutable de todos los cambios aplicados al sistema.
3. **Modelo *pull-based*:** El agente GitOps extrae activamente el estado deseado desde el repositorio, en lugar de recibir instrucciones de un sistema externo, eliminando la necesidad de acceso de escritura externo al clúster.
4. **Reconciliación continua:** El agente monitoriza constantemente las divergencias entre el estado deseado (Git) y el estado real (clúster) y las corrige automáticamente.

En el contexto de los Data Spaces, estos principios adquieren relevancia adicional: la auditabilidad inherente al historial de Git —cada cambio en la infraestructura o configuración del Data Space queda firmado y trazable— responde directamente a los requisitos de trazabilidad y transparencia del DGA.

**Madurez industrial de GitOps**

El informe CNCF GitOps Working Group (2023) documenta que el 75% de las organizaciones que adoptan Kubernetes incorporan prácticas GitOps en sus flujos de despliegue. Gartner identifica GitOps como una *hype* que ha alcanzado el *Slope of Enlightenment* en el ciclo tecnológico de 2024, indicando madurez suficiente para adopción en producción con riesgo bajo.

**Análisis comparativo ArgoCD vs FluxCD**

| Criterio | ArgoCD v2.11 | FluxCD v2.3 |
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

La selección de ArgoCD se justifica por su interfaz gráfica —relevante para la demostración académica y la supervisión operacional del Data Space—, su soporte nativo para el patrón App of Apps sin dependencias adicionales y su mayor penetración en adopción empresarial, que incrementa la transferibilidad del modelo propuesto.

**Sync Waves: gestión de dependencias en GitOps**

El mecanismo de *Sync Waves* de ArgoCD permite expresar dependencias de despliegue sin código imperativo: cada recurso lleva una anotación `argocd.argoproj.io/sync-wave` con un número entero, y ArgoCD no avanza a la ola siguiente hasta que todos los recursos de la ola actual alcanzan el estado `Healthy`. En la arquitectura del Data Space, este mecanismo es crítico: el Trust Anchor (Keyrock, TIL, CCS) debe estar operativo antes de que Kong intente configurar sus políticas de validación, y las bases de datos deben estar disponibles antes de que los servicios que las consumen inicien.

### 2.1.5 Infrastructure as Code y Gestión de Recursos Compute

**Terraform y el modelo de módulos reutilizables**

Terraform (HashiCorp, 2014) es la herramienta IaC más ampliamente adoptada en entornos cloud heterogéneos, con más de 1.500 *providers* disponibles y una comunidad de más de 100.000 módulos públicos en el Terraform Registry (HashiCorp, 2023). Su modelo de ejecución basado en grafos de dependencias, junto con la gestión de estado remoto y el ecosistema de módulos reutilizables, lo posicionan como estándar de facto para el aprovisionamiento de infraestructura reproducible.

El framework de módulos desarrollado en el presente trabajo sigue el patrón de diseño `map(object({...}))` para la definición de múltiples instancias del mismo recurso en un único bloque declarativo, lo que maximiza la reutilización sin sacrificar la flexibilidad de configuración. Esta aproximación contrasta con el patrón habitual de módulos Terraform públicos, que generalmente crean una única instancia del recurso, requiriendo iterar manualmente en el código raíz.

**Amazon EKS: justificación y dimensionamiento**

Amazon EKS proporciona un plano de control Kubernetes gestionado, eximiendo al operador de la complejidad de `etcd`, `kube-apiserver` y `kube-controller-manager`, según el modelo de responsabilidad compartida de AWS (AWS, 2023). La decisión de utilizar EKS frente a alternativas como GKE (Google) o AKS (Azure) responde a tres criterios:

| Criterio | EKS | GKE | AKS |
|---------|-----|-----|-----|
| Residencia datos UE | Sí (eu-west-1, eu-central-1) | Sí | Sí |
| Integración IAM nativa | Sí (IRSA) | Sí (Workload Identity) | Sí (AAD Pod Identity) |
| SPOT Managed Node Groups | Sí | Sí | Sí |
| Costo plano de control | $0.10/h | Gratuito | Gratuito |
| IRSA sin webhook externo | Sí (nativo) | Parcial | Parcial |
| Madurez ESO integración | Alta | Alta | Media |

El mayor costo del control plane de EKS frente a GKE/AKS se justifica por la mayor madurez de la integración IAM/IRSA sin necesidad de webhooks externos, lo que simplifica el modelo de seguridad.

**Dimensionamiento de nodos: justificación técnica**

La selección del tipo de instancia `t3a.large` (2 vCPU, 8 GB RAM) responde al análisis de los requisitos de memoria del stack FIWARE completo. El sizing fue determinado midiendo el consumo real de cada componente en el entorno desplegado:

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

La memoria *allocatable* por nodo `t3a.large` es de 7.1 GB (8 GB – overhead del sistema operativo y kubelet). Con dos nodos, la capacidad total asciende a 14.2 GB allocatable, proporcionando un margen del 56% sobre los límites declarados. Este margen es suficiente para absorber picos de memoria de los componentes Java/Node.js (Keyrock, CCS) y garantizar la estabilidad ante SPOT interruptions en las que todos los pods migran temporalmente a un único nodo.

La selección de `t3a.large` sobre alternativas fue validada mediante la siguiente comparativa:

| Tipo | vCPU | RAM | Precio SPOT (eu-west-1) | Viabilidad |
|------|------|-----|------------------------|------------|
| t3.medium | 2 | 4 GB | ~$0.016/h | ❌ Insuficiente (OOM frecuente) |
| t3a.large | 2 | 8 GB | ~$0.025/h | ✅ Mínimo viable |
| t3a.xlarge | 4 | 16 GB | ~$0.050/h | ✅ Holgado (+50% coste) |
| t3a.2xlarge | 8 | 32 GB | ~$0.100/h | ✅ Excesivo para lab |

El tipo `t3.medium` (4 GB RAM) produce condiciones de *Out Of Memory* (OOM) cuando Keyrock y MongoDB arrancan simultáneamente, ya que Keyrock consiste en un proceso Node.js que carga el motor XACML de AuthzForce en memoria (~600 MB en frío). La elección de `t3a.large` (variante AMD, ~10% más económica que `t3`) como tipo mínimo viable está documentada en ADR-004 (§4.1.5).

**Gestión de secretos en Kubernetes**

El mecanismo nativo de Kubernetes —objetos *Secret* codificados en base64— resulta insuficiente para entornos de producción por carecer de cifrado en reposo por defecto y de mecanismos de rotación automática (Kubernetes, 2023). External Secrets Operator (ESO) resuelve esta limitación sincronizando secretos desde almacenes externos —AWS Secrets Manager, HashiCorp Vault, Azure Key Vault— hacia secretos nativos de Kubernetes, desacoplando el ciclo de vida de los secretos del ciclo de vida de las aplicaciones (External Secrets, 2023).

La integración entre ESO y AWS Secrets Manager se implementa mediante IRSA (*IAM Roles for Service Accounts*): el ServiceAccount del pod ESO asume un rol IAM con permisos de lectura restringidos a los secretos bajo el prefijo `/fiware/` en AWS Secrets Manager, sin necesidad de credenciales estáticas en el clúster.

### 2.1.6 Patrones de CI/CD para Infraestructura Cloud

Los pipelines de integración continua para infraestructura cloud introducen consideraciones de seguridad específicas que difieren de los pipelines de software convencionales (Forsgren et al., 2018). Los riesgos principales son tres: exposición de credenciales cloud en logs o artefactos, derivación de cambios no revisados aplicados directamente en producción, y fallos en la detección de configuraciones inseguras antes del despliegue.

La autenticación de pipelines CI/CD con proveedores cloud mediante **OIDC** (*OpenID Connect*) elimina el riesgo de credenciales estáticas long-lived: el runner de GitHub Actions obtiene un JWT de corta duración firmado por `token.actions.githubusercontent.com`, que AWS IAM verifica contra el proveedor OIDC registrado para asumir el rol `github-actions-terraform-role`. Este mecanismo es equivalente al que implementa IRSA para pods Kubernetes, aplicado al contexto de CI/CD.

El escaneo de código IaC con **Checkov** (Bridgecrew/Palo Alto, 2024) aplica más de 1.000 controles sobre recursos Terraform y manifests Kubernetes, cubriendo los requisitos de los benchmarks CIS AWS Foundations (v3.0) y CIS Kubernetes (v1.8). La integración de los resultados como SARIF en GitHub Security Code Scanning permite el seguimiento de hallazgos como parte del flujo de revisión de código.

**TruffleHog** (Truffle Security, 2024) escanea el historial completo de commits en busca de secretos con firmas verificables —tokens API, claves privadas, contraseñas en texto plano— proporcionando una capa de seguridad adicional frente a compromisos accidentales de credenciales.

## 2.2 Trabajos Relacionados

La revisión de la literatura permite identificar cuatro categorías de trabajos previos con relevancia para el presente estudio: despliegues FIWARE en entornos cloud, GitOps para plataformas IoT y cloud-native, arquitecturas técnicas de Data Spaces europeos e implementaciones de IaC para plataformas Kubernetes.

**Análisis sistemático de trabajos relacionados**

| Trabajo | Año | Tecnologías | Contribución | Limitaciones respecto al TFM |
|---------|-----|------------|-------------|------------------------------|
| Llorente et al. | 2023 | FIWARE, Kubernetes, AWS/Azure | Análisis comparativo multi-cloud | Sin GitOps, sin marcos de confianza europeos |
| Rahman et al. | 2022 | FluxCD, Kubernetes, IoT | GitOps para plataformas IoT | Sin Data Spaces, sin iSHARE |
| DSBA TCF | 2023 | FIWARE, iSHARE, DSBA | Arquitectura de referencia DSBA | Sin guías de implementación operacional |
| DSSC | 2023 | FIWARE, i4Trust | Piloto Data Space sector agroalimentario (i4Trust) | Implementación manual, sin reproducibilidad |
| HashiCorp | 2023 | Terraform, módulos reutilizables | State of the Cloud: adopción de IaC | Sin componentes FIWARE, sin marcos de confianza |

**Despliegues FIWARE en entornos cloud.** Llorente et al. (2023) presentan un análisis comparativo de despliegues FIWARE en entornos multi-cloud, evaluando aspectos de rendimiento y disponibilidad en AWS, Azure y GCP. El estudio identifica que los componentes de mayor consumo de recursos son Keyrock y MongoDB, y cuantifica el impacto del número de réplicas en la disponibilidad. Sin embargo, su trabajo no aborda el paradigma GitOps ni la integración con marcos de Data Spaces europeos, limitándose a la dimensión operacional del despliegue sin considerar la automatización del ciclo de vida.

**GitOps para plataformas IoT y Edge.** Rahman et al. (2022) proponen un modelo GitOps para plataformas IoT basadas en Kubernetes, demostrando la viabilidad del paradigma en entornos con dispositivos heterogéneos y alta rotación de componentes. Los autores emplean FluxCD con el patrón de *push-based notification* para acelerar la convergencia de estado en dispositivos edge. No obstante, su propuesta no considera el contexto específico de los Data Spaces europeos ni los requisitos de confianza federada que impone el marco iSHARE, y las plataformas analizadas no implementan control de acceso basado en Verifiable Credentials.

**Arquitecturas técnicas de Data Spaces.** El DSBA Technical Convergence Framework (DSBA, 2023) define la arquitectura de referencia para Data Spaces basados en FIWARE, estableciendo los componentes, protocolos y patrones de integración recomendados, incluyendo el flujo iSHARE M2M y la estructura del Trust Anchor. Este documento de referencia es el más directamente relacionado con el presente trabajo. Sin embargo, el TCF no incluye guías de implementación operacional automatizada, no aborda la integración con herramientas de tipo GitOps o IaC, y no proporciona código reproducible para el despliegue de la arquitectura descrita.

**Pilotos industriales de Data Spaces.** El Data Spaces Support Centre (DSSC, 2023) documenta la implementación del piloto i4Trust, un programa financiado por la Comisión Europea en el marco de la convocatoria NGI orientado a la creación de Data Spaces sectoriales basados en FIWARE. El piloto del sector agroalimentario integró más de veinte participantes y validó flujos de intercambio de datos verificados con iSHARE en condiciones de producción real. Sin embargo, la implementación se realizó de forma manual y específica para el contexto del piloto, sin abstracción en patrones reutilizables ni automatización del ciclo de vida mediante GitOps.

**IaC para plataformas cloud-native.** HashiCorp (2023) publica anualmente el informe *State of the Cloud*, que recoge patrones de adopción de IaC en entornos cloud heterogéneos. El informe documenta que el 75% de los equipos de infraestructura utilizan módulos reutilizables como principal mecanismo de abstracción en Terraform, y que la separación entre definición de recursos (módulos) y configuración de instancias (tfvars) es el patrón dominante para organizaciones con múltiples entornos. El framework de módulos desarrollado en el presente trabajo sigue este patrón de forma coherente, añadiendo la integración específica con componentes FIWARE y marcos de confianza que el informe no contempla.

## 2.3 Conclusiones del Estado del Arte

Del análisis realizado se derivan tres conclusiones que orientan directamente el diseño del presente trabajo:

**Primera conclusión.** Existe una brecha significativa entre las arquitecturas de referencia para Data Spaces —IDSA RAM, Gaia-X, DSBA TCF— y las guías de implementación operacional disponibles. Las arquitecturas definen *qué* debe existir en un espacio de datos, pero no *cómo* desplegarlo de forma reproducible, automatizada y auditable en infraestructura cloud real. Esta brecha es precisamente el problema que el presente trabajo se propone resolver: el DSBA TCF proporciona la arquitectura lógica; el TFM proporciona la implementación técnica concreta.

**Segunda conclusión.** El paradigma GitOps ha demostrado su viabilidad en contextos de IoT y plataformas cloud-nativas (Rahman et al., 2022; CNCF, 2023), pero su aplicación específica al dominio de los Data Spaces europeos —con los requisitos de confianza federada que impone iSHARE y las obligaciones regulatorias del DGA— no ha sido objeto de estudio sistemático en la literatura revisada. La intersección entre GitOps y los marcos de confianza europeos constituye, por tanto, un ámbito de contribución original.

**Tercera conclusión.** De entre las tecnologías analizadas, FIWARE emerge como la única pila con soporte institucional explícito por parte de la DSBA para la construcción de Data Spaces conformes con los estándares europeos. Su integración oficial con el DSBA TCF, el soporte nativo para NGSI-LD y la compatibilidad con iSHARE mediante Keyrock justifican su selección frente a las alternativas consideradas (Eclipse Ditto, FROST-Server). Los trabajos previos (Llorente et al., 2023; DSSC, 2023) confirman la viabilidad de FIWARE en producción pero sin la capa de automatización GitOps que el presente trabajo aporta.

El presente trabajo contribuye a cubrir la intersección de estos tres ámbitos, aportando un modelo de referencia que integra la automatización GitOps, el aprovisionamiento IaC y los componentes FIWARE con los marcos de confianza requeridos por el ecosistema europeo de espacios de datos. La novedad de la contribución reside no en cada elemento por separado —todos ellos son tecnologías maduras— sino en su integración coherente y reproducible como sistema completo, documentado con suficiente detalle para ser adoptado por organizaciones sin experiencia previa en Data Spaces.
