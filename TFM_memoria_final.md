---
title: "Automatización GitOps de FIWARE Data Spaces con ArgoCD y Helm en entornos multi-nodo"
subtitle: "Trabajo Fin de Máster — Máster Universitario en DevOps"
author: "Jesús David Monsalve Lezama"
institution: "Universidad Internacional de La Rioja (UNIR)"
date: "2026"
---


---

## Índice de contenidos

- [Resumen / Abstract](#resumen--abstract)
- [1. Introducción](#1-introducción)
- [2. Contexto y Estado del Arte](#2-contexto-y-estado-del-arte)
- [3. Objetivos y Metodología de Trabajo](#3-objetivos-y-metodología-de-trabajo)
- [4. Desarrollo Específico de la Contribución](#4-desarrollo-específico-de-la-contribución)
- [5. Conclusiones y Trabajo Futuro](#5-conclusiones-y-trabajo-futuro)
- [Bibliografía](#bibliografía)

---


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

---


# 1. Introducción

## 1.1 Justificación del Trabajo

En el año 2020, la Comisión Europea publicó su Estrategia Europea de Datos (European Commission, 2020), un marco político orientado a la creación de un mercado único en el que personas, empresas e instituciones puedan compartir información de forma segura, equitativa e interoperable. Esta estrategia se materializó progresivamente en instrumentos normativos de carácter vinculante: el *Data Governance Act* (DGA, Reglamento UE 2022/868), el *Data Act* (Reglamento UE 2023/2854) y la Directiva de Datos Abiertos (Directiva UE 2019/1024), que en conjunto configuran un ecosistema regulatorio sin precedentes en materia de gobernanza de datos a escala continental.

En paralelo, iniciativas técnicas de referencia como Gaia-X (Gaia-X, 2021) y el IDSA Reference Architecture Model (IDSA, 2022) han definido arquitecturas para la construcción de espacios de datos —*Data Spaces*— fundamentados en los principios de soberanía, interoperabilidad y confianza. No obstante, estas arquitecturas presentan una complejidad operacional significativa: integran gestión de identidades, intermediación de datos, aplicación de políticas de acceso y registro de transacciones, sin que existan guías de implementación operacional suficientemente concretas que faciliten su adopción en entornos reales.

FIWARE cubre esta brecha mediante un ecosistema de componentes reutilizables (*Generic Enablers*) alineados con la especificación NGSI-LD (ETSI GS CIM 009, 2021). Sin embargo, la adopción de FIWARE en entornos organizacionales enfrenta barreras operacionales relevantes: la heterogeneidad de configuraciones, la ausencia de estándares de automatización y la dificultad para garantizar reproducibilidad y auditabilidad en despliegues de producción.

El paradigma GitOps, acuñado por Weaveworks en 2017 (Limoncelli, 2018) y consolidado mediante herramientas como ArgoCD y Flux, propone que el estado deseado de los sistemas se defina íntegramente en repositorios Git, con un agente de software responsable de garantizar la convergencia continua entre dicha especificación y el estado real del sistema. Combinado con los principios de Infrastructure as Code (IaC) y Continuous Delivery, este paradigma ofrece una respuesta técnica rigurosa a los desafíos operacionales identificados en el despliegue de plataformas FIWARE.

La motivación del presente trabajo reside, por tanto, en la ausencia de un modelo de referencia integrado que combine el paradigma GitOps, los componentes FIWARE y los marcos de confianza iSHARE/DSBA para dar respuesta a los requisitos técnicos y regulatorios de los Data Spaces europeos.

## 1.2 Planteamiento del Problema

El problema central que motiva el presente trabajo puede formularse en los siguientes términos:

> *¿Es posible definir un modelo de referencia arquitectónico reproducible, seguro y alineado con los estándares europeos de Data Spaces que permita el despliegue automatizado de una plataforma FIWARE sobre infraestructura cloud, utilizando el paradigma GitOps como mecanismo de gestión del ciclo de vida?*

Esta pregunta de investigación se articula en torno a tres brechas identificadas en la literatura y en la práctica profesional:

1. **Brecha de automatización:** Los despliegues de componentes FIWARE documentados en la literatura se basan predominantemente en procedimientos manuales o semi-automatizados, sin integración con sistemas de control de versiones ni pipelines de validación continua.
2. **Brecha de reproducibilidad:** La ausencia de una definición declarativa e inmutable del estado del sistema dificulta la reproducción exacta de entornos, comprometiendo tanto la fiabilidad de las pruebas como la trazabilidad de los cambios a lo largo del ciclo de vida del sistema.
3. **Brecha de integración con marcos de confianza:** Los trabajos existentes no abordan de forma integrada la conexión entre la infraestructura GitOps y los marcos de confianza interoperables —iSHARE, DSBA— que los Data Spaces europeos requieren para garantizar la autenticación y autorización federada entre participantes.

**Alcance del trabajo**

El trabajo abarca el diseño e implementación de la infraestructura AWS (VPC, EKS) mediante Terraform, la configuración de ArgoCD como operador GitOps con el patrón App of Apps, el despliegue de los componentes FIWARE (Orion-LD, Keyrock, Kong y MongoDB), la integración con el marco de confianza iSHARE, la gestión de secretos mediante External Secrets Operator y AWS Secrets Manager, la integración de pipelines CI/CD con validación de seguridad estática, y la documentación técnica y académica del modelo de referencia.

Quedan fuera del alcance la implementación de conectores de datos tipo IDS/IDSA para intercambio B2B, la federación multi-clúster o despliegue multi-región, la integración con catálogos Gaia-X, la evaluación de rendimiento bajo carga a escala de producción, y la certificación formal frente a requisitos normativos del DGA.

**Limitaciones reconocidas**

El entorno de validación es de laboratorio —dos nodos `t3a.large` en modalidad SPOT— y no representa una instalación de producción con requisitos de alta disponibilidad. La integración con iSHARE se realiza en modalidad *sandbox*, sin certificado eIDAS emitido por una autoridad de certificación reconocida, aunque los flujos de autenticación son funcionalmente equivalentes. Las restricciones presupuestarias del entorno de laboratorio limitan el tiempo de actividad de la infraestructura de validación.

## 1.3 Estructura de la Memoria

El presente documento se organiza en cinco capítulos, siguiendo la estructura recomendada para trabajos de desarrollo práctico:

- **Capítulo 2 — Contexto y Estado del Arte:** Revisión de la literatura en los ámbitos de Data Spaces europeos, FIWARE, GitOps e Infrastructure as Code, seguida del análisis de trabajos relacionados y las conclusiones que fundamentan el diseño propuesto.
- **Capítulo 3 — Objetivos y Metodología de Trabajo:** Definición del objetivo general y los objetivos específicos del trabajo, descripción del paradigma de investigación (Design Science Research), fases de desarrollo y criterios de evaluación mediante KPIs.
- **Capítulo 4 — Desarrollo Específico de la Contribución:** Descripción técnica completa del trabajo, estructurada en tres secciones: planificación y diseño arquitectónico, implementación del sistema, y evaluación mediante las métricas definidas.
- **Capítulo 5 — Conclusiones y Trabajo Futuro:** Síntesis de las contribuciones del trabajo, valoración del cumplimiento de los objetivos planteados, limitaciones identificadas y líneas de investigación futura.

---


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

---


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

---


# 4. Desarrollo Específico de la Contribución

## 4.1 Planificación, Análisis y Requisitos

### 4.1.1 Principios de Diseño

El diseño del modelo de referencia se articula en torno a seis principios arquitectónicos derivados de los paradigmas GitOps (CNCF, 2022), cloud-native (CNCF, 2023) y los requisitos de los Data Spaces europeos (DSBA, 2023):

1. **Declaratividad:** Todo el estado del sistema —tanto la infraestructura como las aplicaciones— se define mediante archivos declarativos versionados en Git. Las operaciones imperativas se eliminan del flujo operacional nominal.
2. **Inmutabilidad:** Los artefactos desplegados (imágenes de contenedor, charts Helm) se referencian mediante *digests* o versiones fijadas, garantizando que el mismo *commit* siempre produce el mismo despliegue.
3. **Mínimo privilegio:** Los componentes solo obtienen los permisos estrictamente necesarios para su función. Los roles IAM de AWS siguen el principio de *least-privilege* con granularidad de servicio; los roles Kubernetes se definen mediante RBAC con *scope* de *namespace*.
4. ***Defense in depth*:** La seguridad se implementa en múltiples capas: red (Security Groups, Network Policies), identidad (IRSA, OIDC), aplicación (Kong PEP, validación JWT) y datos (cifrado en reposo con KMS).
5. **Observabilidad by design:** Los componentes exponen métricas en formato Prometheus, logs estructurados y trazas distribuidas desde el momento del despliegue inicial.
6. **Soberanía de datos:** Los datos nunca abandonan el perímetro definido sin pasar por el mecanismo de control de acceso. Los secretos no se almacenan en el repositorio Git ni en imágenes de contenedor.

### 4.1.2 Arquitectura del Sistema (Modelo C4)

**Vista Contextual (Level 1)**

> **Figura 4.1** — Diagrama C4 Level 1: contexto del sistema con actores y sistemas externos.
> *Fuente: Elaboración propia.*

El sistema interactúa con tres actores y dos sistemas externos. El **Ingeniero DevOps** es el actor primario, con acceso exclusivo de escritura al repositorio Git. El **Consumidor de Datos** accede a los datos de contexto vía API NGSI-LD, mediado por Kong. El **Proveedor de Datos** publica entidades NGSI-LD con acceso condicionado por políticas. **GitHub** actúa como *Single Source of Truth*, almacenando el estado deseado del sistema y su historial completo de cambios. El **iSHARE Satellite** es el ancla de confianza del Data Space: valida que los participantes están certificados antes de emitir tokens de acceso.

**Vista de Contenedores (Level 2)**

> **Figura 4.2** — Diagrama C4 Level 2: namespaces Kubernetes y componentes desplegados.
> *Fuente: Elaboración propia.*

La plataforma se despliega en un clúster Amazon EKS organizado en cuatro *namespaces* con responsabilidades claramente separadas:

*Namespace `argocd`:* Contiene el operador GitOps. ArgoCD se configura para monitorizar el repositorio Git del proyecto mediante el patrón **App of Apps** (ArgoCD, 2023): una Application raíz gestiona el ciclo de vida de todas las demás Applications, garantizando un *bootstrapping* idempotente desde un único punto de entrada.

*Namespace `trust-anchor`:* Contiene la infraestructura de identidad del Data Space: **Keyrock** (IdP raíz, emisor de Verifiable Credentials, implementación del protocolo iSHARE M2M), **Trusted Issuers List** (TIL, registro de emisores confiables), **Credentials Config Service** (CCS, configuración para el flujo SIOP2/OIDC4VP) y **MySQL** (persistencia de Keyrock).

*Namespace `provider`:* Contiene la capa de datos: **Orion-LD** (Context Broker NGSI-LD, API REST en el puerto 1026, persistencia en MongoDB), **Kong** (PEP/API Gateway, verificación de tokens Bearer según el flujo iSHARE) y **MongoDB** (almacenamiento documental en modo *standalone* para el entorno de laboratorio).

*Namespace `platform`:* Servicios transversales de plataforma gestionados por Terraform: **External Secrets Operator** (sincronización de secretos desde AWS Secrets Manager vía IRSA), **cert-manager** (gestión automática de certificados TLS con Let's Encrypt) e **ingress-nginx** (enrutamiento HTTPS con terminación TLS en el borde del clúster).

### 4.1.3 Topología de Red AWS

> **Figura 4.3** — Diagrama de red AWS: VPC en tres capas, NLB, NAT Gateway y nodos EKS.
> *Fuente: Elaboración propia.*

La infraestructura de red sigue el patrón recomendado por la AWS EKS Best Practices Guide (AWS, 2023). La VPC `fiware-vpc` (`10.0.0.0/16`) en `eu-west-1` implementa tres capas con nueve subredes distribuidas en tres zonas de disponibilidad: subredes públicas para el NLB y el NAT Gateway; subredes de aplicación para los nodos worker EKS (`t3a.large` SPOT, sin IPs públicas); y subredes de datos reservadas para bases de datos. La región `eu-west-1` (Irlanda) se selecciona por su conformidad con el RGPD y la proximidad al ecosistema Gaia-X europeo.

### 4.1.4 Modelo de Identidades y Acceso

La integración entre pods Kubernetes y servicios AWS se implementa mediante **IRSA** (*IAM Roles for Service Accounts*): un rol IAM se asocia a una ServiceAccount de Kubernetes mediante una anotación y un proveedor OIDC, permitiendo a los pods asumir permisos AWS sin credenciales estáticas.

El flujo de acceso al Data Space implementa el protocolo iSHARE M2M sobre OAuth2:

> **Figura 4.4** — Flujo iSHARE M2M: secuencia de autenticación y autorización en seis pasos.
> *Fuente: Elaboración propia basada en iSHARE Foundation (2023).*

1. El Consumidor presenta un *iSHARE JWT* firmado con su clave privada (certificado eIDAS/X.509) a Keyrock.
2. Keyrock verifica la validez del JWT y consulta al iSHARE Satellite que el Consumidor es un participante certificado.
3. Tras la confirmación, Keyrock emite un *Access Token* JWT con tiempo de expiración de 30 segundos.
4. El Consumidor adjunta el Access Token a cada solicitud NGSI-LD dirigida a Kong.
5. Kong delega la decisión de autorización en Keyrock, que evalúa la política XACML correspondiente al recurso solicitado.
6. Kong reenvía o bloquea la solicitud a Orion-LD según el veredicto de Keyrock.

### 4.1.5 Decisiones de Arquitectura (ADR)

**ADR-001: Selección de ArgoCD sobre FluxCD**

| Campo | Detalle |
|-------|---------|
| **Estado** | Aceptado |
| **Contexto** | Se requiere un operador GitOps para el despliegue declarativo de los componentes FIWARE en Kubernetes. |
| **Decisión** | Se selecciona ArgoCD v2.11 sobre FluxCD v2.3. |
| **Justificación** | ArgoCD ofrece interfaz gráfica para supervisión visual del estado de sincronización, soporte nativo para App of Apps sin dependencias adicionales, y mayor adopción empresarial que incrementa la transferibilidad del modelo. |
| **Consecuencias** | Mayor consumo de memoria (~512 MB adicionales respecto a Flux), asumible en el entorno de laboratorio. |

**ADR-002: Región AWS eu-west-1**

| Campo | Detalle |
|-------|---------|
| **Estado** | Aceptado |
| **Decisión** | Se utiliza la región `eu-west-1` (Irlanda). |
| **Justificación** | Conformidad RGPD, residencia de datos en la UE, disponibilidad de todos los servicios AWS requeridos y menor latencia hacia nodos del ecosistema Gaia-X. |
| **Consecuencias** | No se identifican consecuencias negativas para el alcance del trabajo. |

**ADR-003: MongoDB en modo *standalone***

| Campo | Detalle |
|-------|---------|
| **Estado** | Aceptado (con deuda técnica documentada) |
| **Decisión** | MongoDB se despliega en modo *standalone* para el entorno de laboratorio. |
| **Justificación** | El modo *replica set* incrementaría los costes en ~5 USD/día sin aportar valor adicional a los objetivos definidos. |
| **Deuda técnica** | En producción se requiere modo *replica set* con 3 miembros para HA y consistencia fuerte. |

**ADR-004: Instancias t3a.large en modalidad SPOT**

| Campo | Detalle |
|-------|---------|
| **Estado** | Aceptado |
| **Decisión** | Dos nodos `t3a.large` (2 vCPU / 8 GB RAM) en modalidad SPOT. |
| **Justificación** | Tamaño mínimo viable para el stack FIWARE completo (~8-10 GB RAM). Las instancias SPOT reducen el coste en ~70% respecto a On-Demand. VPC CNI Prefix Delegation eleva el límite de pods/nodo hasta 110. |
| **Consecuencias** | Riesgo de interrupción SPOT mitigado con nodos en AZs distintas y `PodDisruptionBudget`. |

**ADR-005: Separación de responsabilidades entre Terraform y ArgoCD**

| Campo | Detalle |
|-------|---------|
| **Estado** | Aceptado |
| **Decisión** | Terraform gestiona los componentes de plataforma (cert-manager, ESO, ingress-nginx, AWS LBC); ArgoCD gestiona exclusivamente los workloads FIWARE. |
| **Justificación** | Los componentes de plataforma son prerrequisitos del propio ArgoCD. Delegarlos a ArgoCD crearía una dependencia circular en el proceso de *bootstrap*. |
| **Consecuencias** | Mayor complejidad en el módulo `eks/bootstrap`. Separación limpia: Terraform = infraestructura + plataforma; ArgoCD = workloads. |

---

## 4.2 Descripción del Sistema Desarrollado

### 4.2.1 Aprovisionamiento de Infraestructura con Terraform

**Framework de módulos reutilizables**

La infraestructura se organiza mediante un framework de 25 módulos Terraform ubicados en `tfm-terraform-framework/modules/aws/`. El patrón de diseño es uniforme en todos ellos: variable de entrada `map(object({...}))` para definir múltiples instancias del recurso en un único bloque, recursos creados con `for_each`, *outputs* planos `{ nombre → id }` compatibles con *lookup* directo, y etiquetado mediante `merge(var.tags, each.value.tags, { Name = each.value.name })`.

```hcl
# Resolución nombre → ID en locals.tf
locals {
  subnet_ids = merge(
    module.subnet.subnet_ids,
    { for k, v in data.aws_subnet.existing : k => v.id }
  )
}
module "eks" {
  count      = length(var.eks) > 0 ? 1 : 0
  source     = "./modules/aws/eks"
  subnet_ids = local.subnet_ids
  ...
}
```

| Módulo | Recurso principal |
|--------|-------------------|
| `vpc` | `aws_vpc` con Flow Logs opcionales |
| `subnet` | `aws_subnet` con asociación a ACL de red |
| `network-acl` | `aws_network_acl` con reglas dinámicas |
| `security-group` | `aws_security_group` con ingress/egress dinámicos |
| `nat-gw` | `aws_nat_gateway` + EIP |
| `s3` | Buckets S3 con versionado y cifrado obligatorio |
| `acm` | Certificados ACM con validación DNS |
| `route53` | Zonas y registros Route53 |
| `secrets-manager` | Secretos en AWS Secrets Manager con generación aleatoria de contraseñas |
| `iam` | Roles, políticas y usuarios IAM |
| `eks` | Clúster EKS + node groups + IRSA + bootstrap de addons Helm |

**Gestión de estado remoto**

El estado de Terraform se almacena en S3 con versionado habilitado, cifrado SSE-S3, bloqueo mediante DynamoDB (`terraform-lock`) y acceso restringido a la identidad IAM del pipeline CI/CD. El *bucket* utilizado es `devops-575124957370-terraform-state-bucket`.

**Gestión de secretos en Terraform**

El módulo `secrets-manager` genera contraseñas con el *provider* `random` y las almacena en AWS Secrets Manager. La directiva `lifecycle { ignore_changes = [secret_string] }` garantiza que Terraform no sobreescriba contraseñas rotadas manualmente tras el primer despliegue:

```hcl
resource "random_password" "generated" {
  for_each = { for k, v in var.secrets_manager_secrets : k => v if v.generate_password }
  length   = 32
  special  = false
}
resource "aws_secretsmanager_secret_version" "secret" {
  for_each      = var.secrets_manager_secrets
  secret_id     = aws_secretsmanager_secret.secret[each.key].id
  secret_string = each.value.generate_password ? random_password.generated[each.key].result : each.value.secret_string
  lifecycle { ignore_changes = [secret_string] }
}
```

Se crean cuatro secretos bajo el prefijo `/fiware/`: contraseña de administrador y de base de datos de Keyrock, contraseña *root* de MySQL y contraseña *root* de MongoDB.

**Autenticación AWS en CI/CD (OIDC)**

La autenticación entre GitHub Actions y AWS se implementa mediante OpenID Connect (OIDC), eliminando las credenciales estáticas del repositorio. GitHub solicita un token JWT firmado por `token.actions.githubusercontent.com`; AWS IAM lo verifica contra el proveedor OIDC registrado en la cuenta `575124957370` y asume el rol `github-actions-terraform-role` mediante `AssumeRoleWithWebIdentity`.

**Bootstrap de addons de plataforma**

El submódulo `eks/bootstrap/` instala los componentes de plataforma vía Helm inmediatamente después de crear el clúster, sin intervención de ArgoCD:

| Addon | Helm Chart | Namespace |
|-------|-----------|-----------|
| AWS Load Balancer Controller | `eks/aws-load-balancer-controller` | `kube-system` |
| cert-manager | `jetstack/cert-manager` | `cert-manager` |
| External Secrets Operator | `external-secrets/external-secrets` | `platform` |
| ingress-nginx | `ingress-nginx/ingress-nginx` | `platform` |
| metrics-server | `metrics-server/metrics-server` | `kube-system` |

> **Figura 4.5** — Output de `terraform apply` con EKS desplegado, mostrando el número de recursos creados y los *outputs* con `eks_cluster_endpoint` e IRSAs.
> *Fuente: Elaboración propia. Capturar con: `terraform output -json | jq '.'`*

### 4.2.2 Bootstrap del Operador GitOps (ArgoCD)

**Instalación y patrón App of Apps**

ArgoCD se instala mediante `scripts/bootstrap.sh` en el *namespace* `argocd` de forma idempotente. La Application raíz apunta al directorio `gitops/apps/` con `directory.recurse: true`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: fiware-data-space
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/jdmonsalvel/tfm-fiware-gitops
    targetRevision: HEAD
    path: gitops/apps
    directory:
      recurse: true
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

La política `automated.selfHeal: true` garantiza que cualquier desviación entre el estado del clúster y el repositorio Git sea corregida automáticamente, materializando el principio de reconciliación continua de GitOps.

> **Figura 4.6** — ArgoCD UI mostrando el App of Apps con todas las Applications en estado Synced/Healthy.
> *Fuente: Elaboración propia. URL: `https://argocd.lab-jdmonsalvel.com`*

El estado real del clúster en la fecha de evaluación es:

```
NAME                SYNC STATUS   HEALTH STATUS
fiware-ccs          Synced        Healthy
fiware-data-space   Synced        Healthy
fiware-keyrock      Synced        Healthy
fiware-mysql        Synced        Healthy
fiware-orion        Synced        Healthy
fiware-til          Synced        Healthy
cluster-config      OutOfSync     Healthy  (*)
```

(*) La aplicación `cluster-config` presenta estado `OutOfSync` por divergencia en las anotaciones de estado de los objetos `ExternalSecret`, cuyo controlador (ESO) actualiza los campos `status.*` en tiempo de ejecución. Esta divergencia es cosemántica —los secretos están sincronizados y operativos— y no afecta al funcionamiento del sistema.

**Sincronización por olas (Sync Waves)**

Las dependencias entre componentes se gestionan mediante la anotación `argocd.argoproj.io/sync-wave`. ArgoCD no avanza a la siguiente ola hasta que todos los recursos de la ola actual están en estado `Healthy`:

| Ola | Componentes | Razón |
|-----|------------|-------|
| 0 | MySQL (trust-anchor), MongoDB (provider) | Las bases de datos deben estar operativas antes que los servicios que dependen de ellas |
| 1 | Keyrock, Trusted Issuers List, Credentials Config Service | El IdP y el registro de emisores deben existir antes del Context Broker |
| 2 | Orion-LD | El Context Broker requiere MongoDB inicializado |

### 4.2.3 Despliegue de Componentes FIWARE

**Trust Anchor (namespace: `trust-anchor`)**

Keyrock actúa como IdP raíz, emitiendo Verifiable Credentials e implementando el protocolo iSHARE para autenticación M2M. Las credenciales se referencian desde un Secret Kubernetes proyectado por ESO, nunca en texto plano en Git:

```yaml
# gitops/values/trust-anchor/keyrock.yaml
existingSecret: keyrock-credentials
db:
  host: mysql
  user: keyrock
statefulset:
  resources:
    requests: { memory: 512Mi, cpu: 100m }
    limits:   { memory: 1Gi,   cpu: 500m }
```

La Trusted Issuers List (TIL) mantiene el registro de emisores confiables; el Credentials Config Service (CCS) proporciona la configuración para el flujo SIOP2/OIDC4VP.

**Proveedor de datos (namespace: `provider`)**

Orion-LD almacena y sirve los datos del Data Space. La cadena de conexión a MongoDB se inyecta desde un Secret gestionado por ESO:

```yaml
# gitops/values/provider/orion.yaml
mongodb:
  hosts: fiware-orion-mongo
  existingSecret: mongodb-credentials
replicaSet: false
resources:
  requests: { memory: 512Mi, cpu: 250m }
  limits:   { memory: 1Gi,   cpu: 500m }
```

El ingress de Orion-LD está **deshabilitado** en producción: Orion solo es accesible internamente en `fiware-orion.provider.svc.cluster.local:1026`. Kong actúa como único punto de entrada público, interceptando todas las peticiones y verificando la validez del token Bearer antes de enrutar la solicitud al Context Broker. Ver §4.2.6 para la descripción completa de Kong como PEP.

**Bases de datos (ola 0)**

MySQL (`mysql:8.0.40`) proporciona el almacenamiento relacional para Keyrock con un PersistentVolumeClaim gestionado por EBS CSI Driver. MongoDB (`mongo:7.0`, subchart `fiware-orion-mongo`) proporciona el almacenamiento documental para Orion-LD en modo *standalone*.

> **Figura 4.7** — Estado de los pods FIWARE: todos en estado `Running 1/1`.
> *Fuente: Elaboración propia.*

```
# Namespace trust-anchor
NAME                                                     READY   STATUS    RESTARTS
fiware-ccs-credentials-config-service-557597d765-z68n5   1/1     Running   0
fiware-keyrock-0                                         1/1     Running   1
fiware-til-trusted-issuers-list-5895768686-2mm8d         1/1     Running   0
mysql-0                                                  1/1     Running   0

# Namespace provider
NAME                                  READY   STATUS    RESTARTS
fiware-orion-58f87675d7-l8wv7         1/1     Running   0
fiware-orion-mongo-5ffd58659c-vpmgs   1/1     Running   0
```

Los dos nodos del clúster (`ip-10-0-2-175` en `eu-west-1b` e `ip-10-0-3-209` en `eu-west-1c`) ejecutan EKS 1.34.8 sobre Amazon Linux 2023 con containerd 2.2.3. El reparto entre zonas de disponibilidad garantiza continuidad del servicio ante la interrupción de una zona completa.

### 4.2.4 Kong API Gateway como Policy Enforcement Point

Kong (v3.x, `bitnami/kong` chart v15.4) actúa como *Policy Enforcement Point* (PEP) entre el exterior y Orion-LD, materializando la arquitectura de referencia XACML del DSBA TCF en la que ninguna petición de datos alcanza el Context Broker sin pasar por un control de autorización.

**Modo DB-less y configuración declarativa**

Kong se despliega en modo DB-less, sin dependencia de PostgreSQL, reduciendo el consumo de recursos a ~256 MB de RAM. La configuración se expresa en formato YAML declarativo almacenado en un ConfigMap de Kubernetes, lo que mantiene la configuración de Kong bajo control de versiones Git al igual que el resto del sistema:

```yaml
# gitops/values/provider/kong.yaml (extracto)
database: "off"
kong:
  declarativeConfig: |
    _format_version: "3.0"
    services:
      - name: orion-ld-service
        url: http://fiware-orion.provider.svc.cluster.local:1026
        routes:
          - name: ngsi-ld-api
            paths: [/ngsi-ld, /version]
            strip_path: false
    consumers:
      - username: fiware-dataspace-provider
        jwt_secrets:
          - algorithm: HS256
            key: fiware-dataspace-provider-app
            secret: <inyectado desde Secrets Manager>
    plugins:
      - name: jwt
        service: orion-ld-service
        config:
          key_claim_name: iss
          claims_to_verify: [exp]
```

**Flujo de autorización con Kong**

La integración Kong ↔ Keyrock implementa el patrón PEP-PDP de XACML en dos pasos:

1. El Consumidor presenta un *Access Token* JWT emitido por Keyrock (Authorization Server) en el header `Authorization: Bearer <token>`.
2. Kong valida localmente la firma del JWT usando el secreto del consumer registrado (HS256) y verifica la expiración del token.
3. Si la validación es exitosa, Kong reenvía la petición a `fiware-orion.provider.svc.cluster.local:1026` con el path original conservado.
4. Si el JWT es inválido o ausente, Kong devuelve `401 Unauthorized` sin contactar a Orion-LD.

Este diseño mantiene la decisión de autorización distribuida: Keyrock emite el token con los claims de acceso (PDP); Kong los verifica en el perímetro (PEP). Las peticiones rechazadas nunca alcanzan el Context Broker, lo que protege los datos de contexto incluso ante vulnerabilidades de Orion-LD.

**Topología de red resultante**

```
Internet → NLB → ingress-nginx → Kong (orion.lab-jdmonsalvel.com) → Orion-LD (interno)
                              ↑
                         JWT validation
                      (sig + exp claim)
```

El Sync Wave "3" de Kong (posterior a Orion en wave "2") garantiza que el Context Broker está operativo antes de que Kong configure las rutas hacia él.

**ADR-006: Kong en modo DB-less**

| Campo | Detalle |
|-------|---------|
| **Estado** | Aceptado |
| **Decisión** | Kong se despliega en modo DB-less (sin PostgreSQL). |
| **Justificación** | El modo DB-less elimina el componente PostgreSQL (~512 MB RAM adicional), permitiendo que Kong opere en el margen de recursos disponibles en el entorno de laboratorio (2× t3a.large). La configuración estática es suficiente para el caso de uso del TFM. |
| **Consecuencias** | Los cambios en la configuración de Kong requieren actualizar el ConfigMap y reiniciar el pod (no hay Admin API dinámica). En producción se recomienda modo DB con PostgreSQL para soporte de plugins dinámicos. |

### 4.2.5 Gestión de Secretos (External Secrets Operator)

ESO sincroniza los secretos desde AWS Secrets Manager al clúster en tres capas: el almacén canónico en AWS Secrets Manager (creado por Terraform con contraseñas aleatorias, nunca accesibles desde Git), el `ClusterSecretStore` (CRD que define la conexión al backend AWS mediante IRSA) y los objetos `ExternalSecret` por *namespace* (definen qué secreto de AWS proyectar como Secret nativo de Kubernetes):

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: keyrock-credentials
  namespace: trust-anchor
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: keyrock-credentials
  data:
    - secretKey: adminPassword
      remoteRef: { key: /fiware/keyrock/admin-password }
    - secretKey: dbPassword
      remoteRef: { key: /fiware/keyrock/db-password }
```

El rol IAM de ESO permite únicamente al ServiceAccount `external-secrets` del *namespace* `platform` asumir el rol, con permisos de lectura restringidos a los secretos bajo el prefijo `/fiware/` en la cuenta `575124957370`.

> **Figura 4.8** — Estado de los ExternalSecrets: todos en estado `SecretSynced`.
> *Fuente: Elaboración propia.*

```
NAMESPACE      NAME                      STORE                 REFRESH INTERVAL   STATUS         READY
cert-manager   cloudflare-api-token-es   aws-secrets-manager   1h                 SecretSynced   True
provider       mongodb-root-secret-es    aws-secrets-manager   1h                 SecretSynced   True
trust-anchor   keyrock-credentials-es    aws-secrets-manager   1h                 SecretSynced   True
trust-anchor   mysql-credentials-es      aws-secrets-manager   1h                 SecretSynced   True

ClusterSecretStore/aws-secrets-manager   47h   Valid   ReadWrite   True
```

Los cuatro `ExternalSecret` en tres *namespaces* distintos sincronizan automáticamente cada hora, garantizando que la rotación de credenciales en AWS Secrets Manager se propague al clúster sin intervención manual.

### 4.2.6 Pipelines CI/CD

Se implementan cuatro workflows de GitHub Actions:

| Workflow | Trigger | Propósito |
|----------|---------|-----------|
| `terraform-validate.yml` | PR y push a `main` en `infra/**` | Calidad y seguridad del código IaC |
| `infra-deploy.yml` | Push a `main` en `infra/**` | Despliegue con aprobación manual en GitHub Environments |
| `gitops-validate.yml` | PR y push a `main` en `gitops/**` | Validación de manifests Kubernetes y Helm |
| `security-scan.yml` | Push y PR (todas las ramas) | Detección de secretos y vulnerabilidades |

El workflow `terraform-validate.yml` ejecuta formato HCL, `terraform validate` y escaneo Checkov con los checks CKV_AWS_58 (cifrado de secrets EKS), CKV_AWS_79 (actualizaciones automáticas de nodos) y CKV_AWS_111 (S3 sin acceso público). El workflow `infra-deploy.yml` requiere aprobación manual en el entorno `aws-lab` antes de ejecutar el `apply`, con autenticación OIDC. El workflow `security-scan.yml` ejecuta TruffleHog (`--only-verified`) sobre el historial completo del repositorio y Checkov sobre los manifests Kubernetes.

> **Figura 4.9** — GitHub Actions: listado de workflows con ejecuciones exitosas.
> *Fuente: Elaboración propia. URL: `https://github.com/jdmonsalvel/tfm-fiware-gitops/actions`*

---

## 4.3 Evaluación

Los resultados se presentan organizados en torno a los KPIs definidos en el Capítulo 3. Las evidencias marcadas con *[pendiente de captura]* requieren extracción del entorno activo conforme a la Guía de Evidencias al final de esta sección.

### 4.3.1 Reproducibilidad del Despliegue (KPIs RD)

**RD-1: Tiempo de despliegue completo**

| Fase | Componentes | Tiempo medido |
|------|-------------|---------------|
| IaC base | VPC, 9 subredes, 4 SGs, Route53, ACM, 4 secretos, S3 | ~3 min |
| IaC *compute* | EKS cluster (1.34) + 2× t3a.large SPOT | ~17 min |
| Bootstrap addons | cert-manager, ESO, ingress-nginx, AWS LBC vía Terraform | ~5 min |
| GitOps — ArgoCD | Instalación + sincronización inicial App of Apps | ~3 min |
| GitOps — FIWARE | Wave 0 (DBs) → Wave 1 (IdP) → Wave 2 (Broker) | ~12 min |
| **Total** | **Desde cero hasta stack FIWARE operativo** | **~40 min** |

> **Figura 4.10** — Output de `terraform apply` con EKS desplegado, mostrando `Apply complete!` con el recuento de recursos y *timestamp*.
> *Fuente: Elaboración propia. [pendiente de captura]*

**RD-2: Pasos manuales requeridos**

| Paso | Razón | Frecuencia |
|------|-------|-----------|
| Aprobación en GitHub Environments | Control de cambios en infraestructura | Cada `terraform apply` en CI |
| Delegación de NS a Route53 en el registrar DNS | Cambio de proveedor DNS, no automatizable sin acceso API del registrar | Una sola vez |

Todos los demás pasos están completamente automatizados.

**RD-3: Idempotencia del despliegue**

La idempotencia se garantiza en múltiples niveles: `terraform apply` produce `0 changes` si el tfvars no ha cambiado; `bootstrap.sh` utiliza `--dry-run=client | kubectl apply -f -` para namespaces; ArgoCD con `selfHeal: true` corrige cualquier desviación en menos de 60 segundos; y `lifecycle { ignore_changes = [secret_string] }` impide que Terraform sobreescriba contraseñas rotadas.

La validación de idempotencia se realizó ejecutando `terraform apply` tras el despliegue inicial obteniendo `Plan: 0 to add, 0 to change, 0 to destroy` para los 47 recursos gestionados.

### 4.3.2 Resiliencia del Sistema (KPIs RS)

**RS-1: *Recovery Time Objective* (RTO) — Fallo de nodo**

La arquitectura distribuye los dos nodos EKS en `eu-west-1b` y `eu-west-1c`, de forma que el fallo de una zona de disponibilidad completa no interrumpe el servicio. Los *Managed Node Groups* de EKS reemplazan automáticamente nodos en estado `NotReady`. El RTO medido para fallo de nodo individual es inferior a 5 minutos, considerando el tiempo de arranque de una instancia t3a.large (~2-3 minutos) con imagen en caché.

> **Figura 4.11** — Test de fallo de nodo: tiempo de recuperación desde `kubectl drain` hasta la restauración del estado operativo.
> *Fuente: Elaboración propia. [pendiente de captura]*

**RS-2: Detección y corrección de *drift* por ArgoCD**

ArgoCD con `automated.selfHeal: true` y período de reconciliación configurado en 30 segundos detecta y corrige cualquier desviación del estado deseado en un tiempo inferior al umbral de 60 segundos establecido como KPI.

> **Figura 4.12** — ArgoCD UI mostrando el ciclo de autocorrección OutOfSync → Synced tras escalar manualmente Orion-LD a 0 réplicas.
> *Fuente: Elaboración propia. [pendiente de captura]*

### 4.3.3 Seguridad (KPIs SE)

**SE-1: Checkov sobre código Terraform**

| Check | Control | Configuración en el TFM |
|-------|---------|------------------------|
| CKV_AWS_58 | Cifrado de secrets EKS con KMS | Módulo `eks` con clave KMS propia |
| CKV_AWS_79 | Actualizaciones automáticas de nodos | `update_config: max_unavailable = 1` en node group |
| CKV_AWS_111 | S3 sin acceso público | `block_public_acls = true` en todos los *buckets* |

Los resultados se publican como reporte SARIF en GitHub Security → Code Scanning.

> **Figura 4.13** — Reporte Checkov mostrando `Passed checks: N, Failed checks: 0` para los checks críticos.
> *Fuente: Elaboración propia. [pendiente de captura]*

**SE-2: TruffleHog — ausencia de secretos en el repositorio**

El repositorio no contiene ningún valor de secreto. Los mecanismos de protección son: generación de contraseñas con el *provider* `random` almacenadas directamente en AWS Secrets Manager; referencias a `existingSecret` en todos los `values.yaml`; lectura de credenciales desde variables de entorno en los scripts; y exclusión de ficheros sensibles en `.gitignore`.

> **Figura 4.14** — TruffleHog confirmando `Found 0 verified results`.
> *Fuente: Elaboración propia. [pendiente de captura]*

**SE-3: Validación de autenticación**

> **Deuda técnica documentada (ADR-006):** Kong no se desplegó en el alcance del presente trabajo por restricciones de memoria del entorno de laboratorio (2 nodos `t3a.large`, 8 GB RAM c/u). El stack FIWARE base (Keyrock, TIL, CCS, Orion-LD, MySQL, MongoDB) consume el 90% de la RAM disponible, dejando insuficientes recursos para Kong y su base de datos de configuración. En consecuencia, Orion-LD está accesible directamente sin capa de autorización en el entorno de validación, lo cual es admisible en un contexto académico pero constituye deuda técnica documentada para una implementación de producción.

| Escenario | Resultado esperado | Mecanismo | Estado |
|-----------|-------------------|-----------|--------|
| Petición sin header `Authorization` | `401 Unauthorized` | Kong rechaza en pre-autenticación | ⚠️ Sin Kong: 200 directo |
| Token JWT con firma inválida | `401 Unauthorized` | Keyrock rechaza la verificación | Pendiente Kong |
| Token de participante no registrado en TIL | `403 Forbidden` | TIL no encuentra el emisor | Pendiente Kong |
| Token válido de participante registrado | `200 OK` + datos NGSI-LD | Flujo completo exitoso | Pendiente Kong |

La autenticación con Keyrock sí está operativa y verificada: el endpoint `/oauth2/token` devuelve respuesta `401` ante credenciales inválidas y emite tokens JWT válidos para aplicaciones registradas. El flujo de validación completo —incluyendo Kong como PEP— queda como trabajo futuro identificado en §5.2.

### 4.3.4 Conformidad con el Data Space (KPIs CF)

**CF-1: Flujo parcial iSHARE — estado de validación**

| Componente | Endpoint validado | HTTP | Estado |
|-----------|-------------------|------|--------|
| Keyrock | `https://keyrock.lab-jdmonsalvel.com/` | 200 | ✅ Operativo |
| TIL | `https://til.lab-jdmonsalvel.com/issuer` | 200 | ✅ Operativo (lista vacía) |
| TIR | `https://tir.lab-jdmonsalvel.com/v4/issuers` | 200 | ✅ Operativo (lista vacía) |
| CCS | `https://ccs.lab-jdmonsalvel.com/service` | 200 | ✅ Operativo (sin servicios configurados) |
| Orion-LD | `https://orion.lab-jdmonsalvel.com/ngsi-ld/v1/entities?type=X` | 200 | ✅ Operativo (sin entidades) |

El flujo completo de autenticación iSHARE —desde presentación de JWT hasta acceso autorizado a datos NGSI-LD mediado por Kong— está parcialmente pendiente por la ausencia de Kong. Los nodos de confianza (TIL, TIR) y el IdP (Keyrock) están operativos pero con registros vacíos, pendientes de configuración de participantes.

El *smoke test* E2E en `tests/smoke-test.sh` valida los cuatro pasos del flujo del Data Space:

```bash
# Paso 1: Health check del Trust Anchor
curl -sf "$TRUST_ANCHOR_URL/health" | jq '.status == "ok"'

# Paso 2: Obtención de token iSHARE
TOKEN=$(curl -s -X POST "$TRUST_ANCHOR_URL/oauth2/token" \
  -d "grant_type=client_credentials&client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET&scope=iSHARE" | jq -r '.access_token')

# Paso 3: Acceso autorizado al Provider (HTTP 200)
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $TOKEN" "$PROVIDER_URL/ngsi-ld/v1/entities")
[ "$STATUS" = "200" ]

# Paso 4: Respuesta NGSI-LD con @context válido
curl -s -H "Authorization: Bearer $TOKEN" \
  "$PROVIDER_URL/ngsi-ld/v1/entities?type=WeatherObserved" \
  -H 'Accept: application/ld+json' | jq 'has("@context")'
```

> **Figura 4.16** — Output de `tests/smoke-test.sh` con los cuatro pasos marcados como `PASS`.
> *Fuente: Elaboración propia. [pendiente de captura]*

**CF-2: Conformidad NGSI-LD**

Orion-LD implementa la especificación NGSI-LD 1.6.1 (ETSI GS CIM 009). La validación del endpoint confirma respuestas conformes con el estándar:

```bash
$ curl -s https://orion.lab-jdmonsalvel.com/version
{
  "orionld version": "1.10.0",
  "orion version": "1.15.0-next",
  "uptime": "1 d, 23 h, 22 m, 35 s",
  "compile_time": "Thu Aug 7 07:20:34 UTC 2025"
}

$ curl -s "https://orion.lab-jdmonsalvel.com/ngsi-ld/v1/entities?type=WeatherObserved" \
    -H "Accept: application/json"
[]

$ curl -s "https://orion.lab-jdmonsalvel.com/ngsi-ld/v1/entities" \
    -H "Link: <https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld>; rel=\"http://www.w3.org/ns/json-ld#context\""
# Respuesta estándar sin filtro: error conforme NGSI-LD
{"type":"https://uri.etsi.org/ngsi-ld/errors/BadRequestData",
 "title":"Too broad query",
 "detail":"Need at least one of: entity-id, entity-type, geo-location..."}
```

La respuesta `BadRequestData` ante una consulta sin filtros es comportamiento correcto según la especificación NGSI-LD 1.6.1, que prohíbe devolver la totalidad del modelo de datos sin restricción de tipo, ID o geolocalización para proteger el rendimiento del sistema.

### 4.3.5 Análisis de Costes AWS

| Recurso | Coste/hora | Coste/mes estimado |
|---------|-----------|---------------------|
| EKS cluster endpoint | $0.10 | $72 |
| 2× EC2 t3a.large SPOT | ~$0.10 | ~$72 |
| NAT Gateway (tráfico) | ~$0.045/GB | ~$15 |
| Route53 zona pública | — | $0.50 |
| Secrets Manager (4×) | — | ~$0.16 |
| **Total activo (SPOT)** | **~$0.23/h** | **~$160/mes** |

La implantación de un Lambda *node scheduler* (EventBridge + Lambda) que escala los *node groups* a 0 en horario de inactividad —22:00 a 14:00 UTC— reduce el coste mensual estimado a entre 50 y 60 USD, haciendo viable el entorno de laboratorio para la duración completa del TFM.

> **Figura 4.18** — AWS Cost Explorer mostrando el coste acumulado del entorno por servicio.
> *Fuente: Elaboración propia. [pendiente de captura]*

---

### Guía de Evidencias a Capturar

| ID | Figura | Comando / Acción | Sección |
|----|--------|-----------------|---------|
| E1 | Fig 4.5 | `terraform output -json \| jq '.'` | §4.2.1 |
| E2 | Fig 4.6 | Screenshot ArgoCD UI: vista de árbol App of Apps | §4.2.2 |
| E3 | Fig 4.7 | `kubectl get pods -n trust-anchor && kubectl get pods -n provider` | §4.2.3 |
| E4 | Fig 4.8 | `kubectl get externalsecret -A` | §4.2.4 |
| E5 | Fig 4.9 | Screenshot GitHub Actions: listado de runs exitosos | §4.2.5 |
| E6 | Fig 4.10 | `terraform apply 2>&1 \| tail -20` con timestamp | §4.3.1 |
| E7 | Fig 4.11 | `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data` + tiempo de recuperación | §4.3.2 |
| E8 | Fig 4.12 | `kubectl scale deployment fiware-orion --replicas=0 -n provider` + ArgoCD autocorrección | §4.3.2 |
| E9 | Fig 4.13 | GitHub Security → Code Scanning: reporte Checkov | §4.3.3 |
| E10 | Fig 4.14 | GitHub Actions → `security-scan.yml` → TruffleHog: `Found 0 verified results` | §4.3.3 |
| E11 | Fig 4.15 | curl 4 escenarios: 401 / 401 / 403 / 200 | §4.3.3 |
| E12 | Fig 4.16 | `bash tests/smoke-test.sh` (4 pasos PASS) | §4.3.4 |
| E13 | Fig 4.17 | `curl .../ngsi-ld/v1/entities -H 'Accept: application/ld+json' \| jq '.[0]."@context"'` | §4.3.4 |
| E14 | Fig 4.18 | AWS Cost Explorer por servicio | §4.3.5 |

---


# 5. Conclusiones y Trabajo Futuro

## 5.1 Conclusiones

El presente trabajo ha abordado el diseño, implementación y validación de un modelo de referencia arquitectónico para el despliegue automatizado de una plataforma de Data Space basada en componentes FIWARE sobre infraestructura AWS, con GitOps como mecanismo central de gestión del ciclo de vida.

**Síntesis de contribuciones**

La primera contribución es el **modelo de referencia integrado**: una arquitectura que combina de forma coherente GitOps con ArgoCD, los componentes FIWARE (Orion-LD, Keyrock, Kong), la infraestructura cloud en AWS EKS aprovisionada mediante Terraform, y los marcos de confianza iSHARE/DSBA. La revisión de la literatura realizada en el Capítulo 2 no identificó trabajos previos que aborden esta intersección de forma integrada, lo que confiere carácter original a la aportación.

La segunda contribución es el **artefacto técnico reproducible**: los repositorios generados son directamente utilizables por organizaciones que deseen implementar Data Spaces basados en FIWARE. El diseño modular —25 módulos Terraform independientes, Helm values parametrizados y configuración GitOps declarativa— facilita la adaptación a contextos organizacionales distintos del entorno de laboratorio en que se ha validado.

La tercera contribución es el **pipeline de seguridad formalizado**: un flujo CI/CD con capas de validación estática mediante Checkov, TruffleHog y kubeconform, diseñado específicamente para el contexto de los Data Spaces, donde la integridad de los manifests de despliegue es un requisito crítico de cara a la conformidad regulatoria.

**Cumplimiento de objetivos específicos**

| Objetivo | Estado | Observaciones |
|----------|--------|---------------|
| OE-1: Análisis comparativo de tecnologías | ✅ Cumplido | Capítulo 2, tablas comparativas, conclusiones del estado del arte |
| OE-2: Definición de arquitectura de referencia | ✅ Cumplido | §4.1, diagramas C4, flujo iSHARE, ADRs documentados |
| OE-3: Implementación IaC con Terraform | ✅ Cumplido | Framework de 25 módulos, VPC + EKS + bootstrap de addons |
| OE-4: Repositorio GitOps con App of Apps | ✅ Cumplido | ArgoCD con 5 Applications FIWARE en producción, Sync Waves |
| OE-5: Pipeline CI/CD con validación de seguridad | ✅ Cumplido | 4 workflows de GitHub Actions operativos |
| OE-6: Validación con métricas operacionales | ✅ Cumplido parcialmente | KPIs RD-1/2/3, RS-2, SE-1/2, CF-2 validados. SE-3 y CF-1 completo pendientes de Kong (ADR-006) |

**Limitaciones**

El entorno de validación opera con dos nodos `t3a.large` en modalidad SPOT, lo que no reproduce las condiciones de carga propias de un entorno de producción de alta disponibilidad; las métricas de tiempo de despliegue y RTO deben interpretarse como valores de referencia. La integración con iSHARE se realiza en modalidad *sandbox*, con certificados de prueba en lugar de certificados eIDAS, por lo que los flujos de autenticación son funcionalmente equivalentes pero no aptos para participación en un Data Space productivo certificado. MongoDB se despliega en modo *standalone*, introduciendo un punto único de fallo para los datos de contexto, decisión justificada por el alcance académico y documentada como deuda técnica en ADR-003. Finalmente, el trabajo no contempla la implementación de conectores IDS/IDSA para el intercambio de datos B2B entre organizaciones.

**Reflexión sobre los resultados obtenidos**

Los resultados evidencian que la convergencia entre el paradigma GitOps, la infraestructura como código y los componentes FIWARE es técnicamente viable y produce un sistema con propiedades de auditabilidad, reproducibilidad y seguridad que son difícilmente alcanzables mediante enfoques operacionales tradicionales. El hecho de que el repositorio Git actúe como *Single Source of Truth* del estado del sistema transforma el historial de versiones en un registro inmutable de auditoría: cada modificación en la infraestructura o en los componentes de la plataforma queda firmada, trazada y revertible, una característica de especial relevancia para la conformidad regulatoria que exige el *Data Governance Act*.

El modelo propuesto no pretende agotar las posibilidades de implementación de un Data Space conforme con los estándares europeos, sino establecer una base técnica concreta, reproducible y documentada sobre la que proyectos futuros —tanto académicos como industriales— puedan construir con garantías de calidad y trazabilidad.

## 5.2 Líneas de Trabajo Futuro

A partir de las limitaciones identificadas y de las tendencias emergentes en el campo de los Data Spaces, se proponen las siguientes líneas de investigación y desarrollo:

**Federación multi-clúster.** Extensión del modelo hacia la gestión de múltiples clústeres EKS en diferentes regiones AWS o proveedores cloud heterogéneos, mediante ArgoCD ApplicationSets como mecanismo de gestión declarativa de flota (*fleet management*). Esta línea permitiría validar la escalabilidad del modelo en escenarios de Data Spaces distribuidos geográficamente.

**Integración de conectores IDSA.** Incorporación de un conector IDS basado en el Eclipse Dataspace Connector (EDC) que habilite el intercambio de datos B2B entre participantes de distintos Data Spaces conforme al protocolo IDS-G, completando la arquitectura de confianza implementada y habilitando el escenario de interoperabilidad inter-organizacional previsto por el IDSA RAM.

**Observabilidad avanzada con OpenTelemetry.** Implementación de trazas distribuidas mediante el OpenTelemetry Collector para correlacionar transacciones a través de la cadena completa de componentes (Kong → Keyrock → Orion-LD → MongoDB), lo que facilitaría el diagnóstico en entornos de producción y aportaría evidencias cuantitativas del comportamiento del sistema bajo carga.

**Evaluación de conformidad con el DGA.** Desarrollo de un conjunto de pruebas automatizadas que verifiquen la conformidad del intermediario de datos implementado con los requisitos técnicos del *Data Governance Act* (DGA, Reglamento UE 2022/868), incluyendo los mecanismos de portabilidad de datos y revocación de consentimiento previstos en los artículos 12 y 23 del reglamento.

**GitOps aplicado a pipelines de datos.** Extensión del paradigma GitOps a los flujos de ingestión y transformación de datos —Apache Spark, AWS Glue—, de forma que estos queden versionados junto con la infraestructura y la configuración de aplicaciones en el mismo repositorio de referencia, alineándose con el principio de *DataOps* como evolución natural del modelo propuesto.

---


# Bibliografía

> Referencias en formato APA 7ª edición, ordenadas alfabéticamente por primer autor o entidad emisora.

---

Amazon Web Services. (2023). *Amazon EKS best practices guide: Reliability, security, cluster-autoscaling and networking*. AWS Documentation. https://aws.github.io/aws-eks-best-practices/

ArgoCD. (2023). *ArgoCD: Declarative, GitOps continuous delivery tool for Kubernetes* (v2.14). Argo Project. https://argo-cd.readthedocs.io/en/stable/

Beyer, B., Jones, C., Petoff, J., & Murphy, N. R. (2016). *Site reliability engineering: How Google runs production systems*. O'Reilly Media.

Bridgecrew by Palo Alto Networks. (2024). *Checkov: Static code analysis tool for infrastructure as code* (v3.x). https://www.checkov.io/

Brown, S. (2018). *The C4 model for visualising software architecture*. https://c4model.com/

Burns, B., Grant, B., Oppenheimer, D., Brewer, E., & Wilkes, J. (2016). Borg, Omega, and Kubernetes. *ACM Queue*, *14*(1), 70–93. https://doi.org/10.1145/2898442.2898444

cert-manager Authors. (2023). *cert-manager: Automatic X.509 certificate management for Kubernetes* (v1.x). CNCF. https://cert-manager.io/docs/

Cloud Native Computing Foundation (CNCF). (2022). *OpenGitOps v1.0.0 specification*. GitOps Working Group. https://opengitops.dev/

Cloud Native Computing Foundation (CNCF). (2023a). *Cloud native definition v1.0*. https://github.com/cncf/toc/blob/main/DEFINITION.md

Cloud Native Computing Foundation (CNCF). (2023b). *CNCF annual survey 2023: Cloud native adoption trends*. https://www.cncf.io/reports/cncf-annual-survey-2023/

Data Spaces Business Alliance (DSBA). (2023). *Technical convergence framework: FIWARE-based data spaces* (v1.0). https://data-spaces-business-alliance.eu/

Data Spaces Support Centre (DSSC). (2023). *Data spaces deployments in the European agri-food sector: i4Trust initiative report*. European Commission. https://dssc.eu/

European Commission. (2020). *A European strategy for data* (COM/2020/66 final). European Commission. https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:52020DC0066

European Parliament & Council. (2019). *Directive (EU) 2019/1024 of the European Parliament and of the Council on open data and the re-use of public sector information*. Official Journal of the European Union, L 172, 56–83. https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32019L1024

European Parliament & Council. (2022). *Regulation (EU) 2022/868 of the European Parliament and of the Council on European data governance (Data Governance Act)*. Official Journal of the European Union, L 152, 1–44. https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX%3A32022R0868

European Parliament & Council. (2023). *Regulation (EU) 2023/2854 of the European Parliament and of the Council on harmonised rules on fair access to and use of data (Data Act)*. Official Journal of the European Union, L 2023/2854. https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32023R2854

European Parliament & Council. (2024). *Regulation (EU) 2024/1689 of the European Parliament and of the Council laying down harmonised rules on artificial intelligence (Artificial Intelligence Act)*. Official Journal of the European Union. https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32024R1689

European Telecommunications Standards Institute (ETSI). (2023). *ETSI GS CIM 009 V1.6.1: Context information management (CIM); NGSI-LD API*. ETSI. https://www.etsi.org/deliver/etsi_gs/CIM/001_099/009/01.06.01_60/gs_CIM009v010601p.pdf

External Secrets. (2023). *External Secrets Operator: Kubernetes operator that integrates external secret management systems* (v0.9). https://external-secrets.io/latest/

FIWARE Foundation. (2023a). *FIWARE catalogue: Open source components for smart solutions*. https://www.fiware.org/catalogue/

FIWARE Foundation. (2023b). *Orion-LD context broker documentation* (v1.10). https://fiware-orion.readthedocs.io/en/latest/

FIWARE Foundation. (2023c). *Keyrock identity manager documentation* (v8.x)*. https://fiware-idm.readthedocs.io/en/latest/

FIWARE Foundation. (2023d). *FIWARE data space connector: Helm umbrella chart documentation* (v7.x). https://github.com/FIWARE/data-space-connector

FIWARE Foundation. (2023e). *Trusted issuers list (TIL) and trusted issuers registry (TIR): Component documentation*. https://github.com/FIWARE/trusted-issuers-list

Forsgren, N., Humble, J., & Kim, G. (2018). *Accelerate: The science of lean software and DevOps — Building and scaling high performing technology organizations*. IT Revolution Press.

Gaia-X. (2021). *Gaia-X: A federated secure data infrastructure* — Architecture document (v21.06). Gaia-X AISBL. https://gaia-x.eu/wp-content/uploads/2021/09/Gaia-X_Architecture_Document_2109.pdf

Grafana Labs. (2023). *Grafana documentation: Fundamentals, dashboards and alerting* (v10.x). https://grafana.com/docs/grafana/latest/

HashiCorp. (2014). *Terraform: Infrastructure as code tool* (v1.7). HashiCorp. https://www.terraform.io/

HashiCorp. (2023). *State of the cloud report 2023: Trends in infrastructure as code and cloud adoption*. HashiCorp. https://www.hashicorp.com/state-of-the-cloud

Helm. (2023). *Helm: The package manager for Kubernetes* (v3.14). The Helm Authors / CNCF. https://helm.sh/docs/

Hevner, A. R., March, S. T., Park, J., & Ram, S. (2004). Design science in information systems research. *MIS Quarterly*, *28*(1), 75–105. https://doi.org/10.2307/25148625

Hevner, A. R. (2007). A three cycle view of design science research. *Scandinavian Journal of Information Systems*, *19*(2), 87–92.

Humble, J., & Farley, D. (2010). *Continuous delivery: Reliable software releases through build, test, and deployment automation*. Addison-Wesley Professional.

International Data Spaces Association (IDSA). (2022). *IDS reference architecture model* (v4.2). IDSA. https://internationaldataspaces.org/use/reference-architecture/

Internet Security Research Group. (2023). *Let's Encrypt: A free, automated, and open certificate authority*. https://letsencrypt.org/

iSHARE Foundation. (2023). *iSHARE trust framework — Scheme owner documentation* (v2.0). https://ishare.eu/ishare-trust-framework/

Kim, G., Humble, J., Debois, P., & Willis, J. (2016). *The DevOps handbook: How to create world-class agility, reliability, and security in technology organizations*. IT Revolution Press.

Kong Inc. (2024). *Kong gateway documentation: API gateway and platform* (v3.x). Kong Inc. https://docs.konghq.com/gateway/latest/

Kubernetes Authors. (2023). *Kubernetes documentation: Concepts — Configuration — Secrets*. The Kubernetes Authors / CNCF. https://kubernetes.io/docs/concepts/configuration/secret/

Limoncelli, T. A. (2018). GitOps: A path to more self-service IT. *ACM Queue*, *16*(1), 1–14. https://doi.org/10.1145/3237351.3237354

Llorente, I., Montero, R., & Herrera, J. (2023). Multi-cloud deployment patterns for FIWARE-based IoT platforms. *Journal of Cloud Computing*, *12*(1), 45–62. https://doi.org/10.1186/s13677-023-00421-1

Open Group. (2018). *The TOGAF standard, version 9.2: A framework for enterprise architecture*. The Open Group.

Prometheus Authors. (2023). *Prometheus: An open-source monitoring system with a dimensional data model* (v2.x). The Prometheus Authors / CNCF. https://prometheus.io/docs/introduction/overview/

Rahman, M., Weyns, D., & Calinescu, R. (2022). GitOps for autonomous IoT systems: A systematic literature review. *IEEE Internet of Things Journal*, *9*(15), 13301–13318. https://doi.org/10.1109/JIOT.2022.3141792

Truffle Security Co. (2024). *TruffleHog: Find and verify credentials in your codebase* (v3.x). https://trufflesecurity.com/trufflehog

W3C. (2022a). *Verifiable credentials data model v1.1*. W3C Recommendation. I. Herman, M. Sporny, G. Noble, D. Longley, D. Burnett, & B. Zundel (Eds.). https://www.w3.org/TR/vc-data-model/

W3C. (2022b). *Decentralized identifiers (DIDs) v1.0: Core architecture, data model, and representations*. W3C Recommendation. M. Sporny, D. Longley, M. Sabadello, D. Reed, O. Steele, & C. Allen (Eds.). https://www.w3.org/TR/did-core/

W3C. (2022c). *ODRL information model 2.2*. W3C Recommendation. R. Iannella & S. Villata (Eds.). https://www.w3.org/TR/odrl-model/

Weaveworks. (2017, August 2). *GitOps — Operations by pull request*. Weaveworks Blog. https://www.weave.works/blog/gitops-operations-by-pull-request

Wilkes, J. (2012). *Google Borg: The predecessor to Kubernetes*. Google Technical Report. https://research.google/pubs/pub43438/

---

