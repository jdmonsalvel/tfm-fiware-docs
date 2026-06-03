# 1. Introducción

El presente Trabajo Fin de Máster aborda el diseño, implementación y validación de un modelo de referencia arquitectónico para el despliegue automatizado, reproducible y auditable de una plataforma de espacio de datos (*Data Space*) basada en los componentes de código abierto FIWARE sobre infraestructura de nube pública en Amazon Web Services (AWS), aplicando el paradigma GitOps mediante ArgoCD y Helm como mecanismo central de gestión del ciclo de vida.

El problema que motiva el trabajo es la existencia de una brecha significativa entre las arquitecturas de referencia europeas para Data Spaces —IDSA RAM v4, Gaia-X, DSBA Technical Convergence Framework— y la ausencia de guías de implementación operacional concretas, reproducibles y automatizadas. Los marcos regulatorios del *Data Governance Act* (DGA, Reglamento UE 2022/868) y el *Data Act* (Reglamento UE 2023/2854) exigen a las organizaciones la capacidad de intercambiar datos de forma segura e interoperable, pero ninguno de los trabajos revisados en la literatura proporciona un modelo integrado que combine la infraestructura como código, GitOps y los marcos de confianza iSHARE/DSBA como sistema completo y reproducible.

Para resolver esta brecha, el trabajo sigue la metodología **Design Science Research** (Hevner et al., 2004): se diseña un artefacto tecnológico —el modelo de referencia— y se evalúa mediante métricas operacionales definidas a priori. El procedimiento se estructuró en cuatro fases: análisis y diseño de la arquitectura, aprovisionamiento de infraestructura AWS con Terraform, despliegue GitOps de los componentes FIWARE con ArgoCD, e integración de pipelines CI/CD con validación de seguridad.

Los resultados obtenidos confirman la viabilidad técnica del modelo: la plataforma completa —Keyrock como Trust Anchor, Trusted Issuers List, Credentials Config Service, Orion-LD como Context Broker y Kong como Policy Enforcement Point— se despliega de forma completamente automatizada en aproximadamente 40 minutos desde código fuente hasta sistema operativo, con cero pasos manuales excepto la aprobación de cambios de infraestructura en el entorno CI/CD. Todos los endpoints del Data Space responden correctamente sobre HTTPS con certificados TLS emitidos automáticamente por cert-manager y Let's Encrypt. La principal limitación identificada es la ausencia del flujo de autenticación iSHARE completo en el entorno de validación, dado que la integración requiere certificados eIDAS y un Satellite iSHARE productivo, aspectos que quedan documentados como trabajo futuro.

La contribución del trabajo es triple: un modelo de referencia arquitectónico integrado que cubre la intersección entre GitOps, FIWARE y los marcos de confianza europeos; un artefacto técnico reproducible con código abierto disponible en GitHub; y un pipeline de seguridad formalizado con capas de validación estática específicas para el contexto de Data Spaces.

---

## 1.1 Justificación del Trabajo

En el año 2020, la Comisión Europea publicó su Estrategia Europea de Datos (European Commission, 2020), un marco político orientado a la creación de un mercado único en el que personas, empresas e instituciones puedan compartir información de forma segura, equitativa e interoperable. Esta estrategia se materializó progresivamente en instrumentos normativos de carácter vinculante: el *Data Governance Act* (DGA, Reglamento UE 2022/868), el *Data Act* (Reglamento UE 2023/2854) y la Directiva de Datos Abiertos (Directiva UE 2019/1024), que en conjunto configuran un ecosistema regulatorio sin precedentes en materia de gobernanza de datos a escala continental. El *Data Governance Act*, en particular, introduce la figura del **intermediario de datos** —una entidad técnica que facilita el intercambio entre proveedores y consumidores sin apropiarse de los datos— y establece requisitos de trazabilidad, neutralidad y seguridad que condicionan directamente el diseño técnico de cualquier plataforma que aspire a operar en este marco.

En paralelo a la evolución normativa, iniciativas técnicas de referencia como Gaia-X (Gaia-X, 2021) y el IDSA Reference Architecture Model (IDSA, 2022) han definido arquitecturas para la construcción de espacios de datos fundamentados en los principios de soberanía, interoperabilidad y confianza. Sin embargo, estas arquitecturas presentan una complejidad operacional significativa: integran gestión de identidades federada, intermediación de datos conforme a NGSI-LD, aplicación de políticas de acceso verificables mediante XACML y registro de transacciones auditables, sin que existan guías de implementación operacional suficientemente concretas que faciliten su adopción en entornos reales.

FIWARE (FIWARE Foundation, 2023a) cubre parcialmente esta brecha mediante un ecosistema de componentes reutilizables —los *Generic Enablers*— alineados con la especificación NGSI-LD (ETSI GS CIM 009, 2023) y respaldados institucionalmente por la Data Spaces Business Alliance (DSBA) como la pila tecnológica de referencia para Data Spaces conformes con los estándares europeos. Sin embargo, la adopción de FIWARE en entornos organizacionales enfrenta barreras operacionales relevantes: la heterogeneidad de configuraciones entre despliegues, la ausencia de estándares de automatización del ciclo de vida y la dificultad para garantizar reproducibilidad y auditabilidad en entornos de producción.

El paradigma GitOps, acuñado por Weaveworks en 2017 (Limoncelli, 2018) y consolidado mediante herramientas como ArgoCD y Flux, propone que el estado deseado de los sistemas se defina íntegramente en repositorios Git, con un agente de software responsable de garantizar la convergencia continua entre dicha especificación y el estado real del sistema. Combinado con los principios de Infrastructure as Code (IaC) —materializados en el presente trabajo mediante Terraform— y los pipelines de Continuous Delivery, este paradigma ofrece una respuesta técnica rigurosa a los desafíos operacionales identificados: el historial inmutable de Git actúa como registro de auditoría de todos los cambios, responde a los requisitos de trazabilidad del DGA, y la reconciliación automática garantiza que el sistema converge al estado declarado sin intervención manual.

La motivación del presente trabajo reside, por tanto, en la ausencia de un modelo de referencia integrado que combine el paradigma GitOps, los componentes FIWARE y los marcos de confianza iSHARE/DSBA para dar respuesta simultánea a los requisitos técnicos y regulatorios de los Data Spaces europeos. La revisión de la literatura realizada en el Capítulo 2 confirma que ningún trabajo previo ha abordado esta intersección de forma completa y reproducible.

## 1.2 Planteamiento del Problema

El problema central que motiva el presente trabajo puede formularse en los siguientes términos:

> *¿Es posible definir un modelo de referencia arquitectónico reproducible, seguro y alineado con los estándares europeos de Data Spaces que permita el despliegue automatizado de una plataforma FIWARE sobre infraestructura cloud, utilizando el paradigma GitOps como mecanismo de gestión del ciclo de vida?*

Esta pregunta de investigación se articula en torno a tres brechas identificadas en la literatura y en la práctica profesional:

1. **Brecha de automatización:** Los despliegues de componentes FIWARE documentados en la literatura se basan predominantemente en procedimientos manuales o semi-automatizados, sin integración con sistemas de control de versiones ni pipelines de validación continua (Llorente et al., 2023; DSSC, 2023). La reproducción exacta de un despliegue documentado requiere intervención humana significativa, comprometiendo la escalabilidad y la auditabilidad del proceso.

2. **Brecha de reproducibilidad:** La ausencia de una definición declarativa e inmutable del estado del sistema dificulta la reproducción exacta de entornos, comprometiendo tanto la fiabilidad de las pruebas como la trazabilidad de los cambios a lo largo del ciclo de vida del sistema. En el contexto del DGA, esta brecha es especialmente relevante: un intermediario de datos debe poder demostrar que su configuración es la declarada y que no ha sufrido alteraciones no autorizadas.

3. **Brecha de integración con marcos de confianza:** Los trabajos existentes no abordan de forma integrada la conexión entre la infraestructura GitOps y los marcos de confianza interoperables —iSHARE, DSBA— que los Data Spaces europeos requieren para garantizar la autenticación y autorización federada entre participantes. La mera existencia de los componentes técnicos (Keyrock, Kong, TIL) no es suficiente: deben estar integrados en un flujo coherente, versionado y reproducible.

**Alcance del trabajo**

El trabajo abarca el diseño e implementación de la infraestructura AWS (VPC en tres capas, Amazon EKS 1.34) mediante Terraform, la configuración de ArgoCD como operador GitOps con el patrón App of Apps y Sync Waves para la gestión de dependencias entre componentes, el despliegue de los componentes FIWARE (Orion-LD, Keyrock, Kong, Trusted Issuers List, Credentials Config Service y sus bases de datos), la integración con el marco de confianza iSHARE en modalidad *sandbox*, la gestión de secretos mediante External Secrets Operator y AWS Secrets Manager, la integración de pipelines CI/CD con validación de seguridad estática (Checkov, TruffleHog, kubeconform), y la documentación técnica y académica del modelo de referencia.

Quedan fuera del alcance: la implementación de conectores de datos tipo IDS/IDSA para intercambio B2B entre organizaciones, la federación multi-clúster o despliegue multi-región, la integración con catálogos Gaia-X, la evaluación de rendimiento bajo carga a escala de producción, y la certificación formal frente a requisitos normativos del DGA.

**Limitaciones reconocidas**

El entorno de validación es de laboratorio —dos nodos `t3a.large` en modalidad SPOT en la región eu-west-1— y no representa una instalación de producción con requisitos de alta disponibilidad. La integración con iSHARE se realiza en modalidad *sandbox*, sin certificado eIDAS emitido por una autoridad de certificación reconocida, aunque los flujos de autenticación son funcionalmente equivalentes a los de un entorno productivo. Las restricciones presupuestarias del entorno de laboratorio se gestionan mediante un scheduler Lambda que escala los nodos a cero en horario de inactividad.

## 1.3 Objetivos y Contribución Principal

**Objetivo general**

Diseñar, implementar y validar un modelo de referencia arquitectónico que permita el despliegue automatizado y reproducible de una plataforma de Data Space basada en componentes FIWARE sobre infraestructura AWS, aplicando el paradigma GitOps con ArgoCD y garantizando la conformidad con los marcos de confianza iSHARE/DSBA y los requisitos regulatorios europeos.

**Objetivos específicos**

A grandes rasgos, el trabajo persigue seis objetivos concretos: (OE-1) analizar y comparar los estándares y tecnologías relevantes en los ámbitos de Data Spaces, FIWARE y GitOps; (OE-2) definir una arquitectura de referencia que integre coherentemente todos los componentes; (OE-3) implementar la infraestructura cloud mediante Terraform; (OE-4) desarrollar el repositorio GitOps con ArgoCD y Helm; (OE-5) integrar pipelines CI/CD con validación de seguridad; y (OE-6) validar el modelo mediante métricas operacionales. La descripción detallada de cada objetivo y sus criterios de evaluación se presenta en el Capítulo 3.

**Contribución principal**

El trabajo realiza tres contribuciones diferenciadas:

La **primera contribución** es el *modelo de referencia integrado*: una arquitectura que combina de forma coherente GitOps con ArgoCD, los componentes FIWARE, la infraestructura AWS aprovisionada mediante Terraform y los marcos de confianza iSHARE/DSBA. La revisión de la literatura no identificó trabajos previos que aborden esta intersección de forma completa, lo que confiere carácter original a la aportación.

La **segunda contribución** es el *artefacto técnico reproducible*: los repositorios generados (`tfm-fiware-gitops` y `tfm-terraform-framework`, disponibles en GitHub) son directamente utilizables por organizaciones que deseen implementar Data Spaces basados en FIWARE. El diseño modular —25 módulos Terraform independientes, Helm values parametrizados y configuración GitOps declarativa— facilita la adaptación a contextos organizacionales distintos del entorno de laboratorio en que se ha validado.

La **tercera contribución** es el *pipeline de seguridad formalizado*: un flujo CI/CD con capas de validación estática mediante Checkov, TruffleHog y kubeconform, diseñado específicamente para el contexto de los Data Spaces, donde la integridad de los manifests de despliegue es un requisito crítico para la conformidad regulatoria.

**Principales resultados**

La plataforma completa se despliega en aproximadamente 40 minutos desde código fuente hasta sistema operativo, con los cinco componentes FIWARE en estado `Running` y todos los endpoints accesibles sobre HTTPS. El tiempo de re-sincronización de ArgoCD ante desviaciones de estado (*drift*) es inferior a 60 segundos. La validación de idempotencia confirma que un segundo `terraform apply` produce cero cambios. Los KPIs de seguridad SE-1 y SE-2 se cumplen con cero hallazgos críticos en Checkov y cero secretos verificados expuestos en TruffleHog.

## 1.4 Estructura de la Memoria

El presente documento se organiza en cinco capítulos más la bibliografía, siguiendo la estructura recomendada por UNIR para trabajos de desarrollo práctico:

- **Capítulo 2 — Contexto y Estado del Arte:** Revisión sistemática de la literatura en los ámbitos de Data Spaces europeos y su marco normativo, el ecosistema FIWARE y la especificación NGSI-LD, el paradigma GitOps y su madurez industrial, la infraestructura como código con Terraform y Amazon EKS, y los marcos de confianza iSHARE/DSBA. Se analizan cinco trabajos relacionados en una tabla comparativa estructurada y se presentan las tres conclusiones del estado del arte que fundamentan el diseño propuesto.

- **Capítulo 3 — Objetivos y Metodología de Trabajo:** Definición formal del objetivo general y los seis objetivos específicos, descripción del paradigma de investigación Design Science Research (Hevner et al., 2004) con sus ciclos de relevancia y rigor, desglose de las cuatro fases del proyecto con sus entregables, y definición de los diez KPIs de evaluación organizados en cuatro dimensiones: reproducibilidad, resiliencia, seguridad y conformidad con el Data Space.

- **Capítulo 4 — Desarrollo Específico de la Contribución:** Descripción técnica completa del trabajo en dos secciones principales. La primera —planificación y diseño— cubre el modelo C4 de arquitectura, la topología de red AWS, el modelo de identidades con IRSA, y las seis Decisiones de Arquitectura (ADR-001 a ADR-006). La segunda —implementación— detalla el framework Terraform, el bootstrap de ArgoCD con el patrón App of Apps, el despliegue de los componentes FIWARE con Sync Waves, Kong como Policy Enforcement Point, la gestión de secretos con ESO y los pipelines CI/CD. La tercera sección presenta la evaluación de los KPIs con evidencias del sistema en producción.

- **Capítulo 5 — Conclusiones y Trabajo Futuro:** Síntesis de las tres contribuciones del trabajo, tabla de cumplimiento de los seis objetivos específicos con su estado, reflexión sobre los resultados obtenidos y las limitaciones identificadas, y cinco líneas de investigación futura: federación multi-clúster, integración de conectores IDSA, observabilidad con OpenTelemetry, evaluación de conformidad con el DGA y extensión del paradigma GitOps a pipelines de datos.
