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
