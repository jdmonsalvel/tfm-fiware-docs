# 1. Introducción

## 1.1 Justificación del Trabajo

En el año 2020, la Comisión Europea publicó su Estrategia Europea de Datos (European Commission, 2020), un marco político orientado a la creación de un mercado único en el que personas, empresas e instituciones puedan compartir información de forma segura, equitativa e interoperable. Esta estrategia se materializó progresivamente en instrumentos normativos de carácter vinculante: el *Data Governance Act* (DGA, Reglamento UE 2022/868), el *Data Act* (Reglamento UE 2023/2854) y la Directiva de Datos Abiertos (Directiva UE 2019/1024), que en conjunto configuran un ecosistema regulatorio sin precedentes en materia de gobernanza de datos a escala continental.

En paralelo, iniciativas técnicas de referencia como Gaia-X (Gaia-X, 2021) y el IDSA Reference Architecture Model (IDSA, 2022) han definido arquitecturas para la construcción de espacios de datos —*Data Spaces*— fundamentados en los principios de soberanía, interoperabilidad y confianza. No obstante, estas arquitecturas presentan una complejidad operacional significativa: integran gestión de identidades, intermediación de datos, aplicación de políticas de acceso y registro de transacciones, sin que existan guías de implementación operacional suficientemente concretas que faciliten su adopción.

FIWARE cubre esta brecha mediante un ecosistema de componentes reutilizables (*Generic Enablers*) alineados con la especificación NGSI-LD (ETSI GS CIM 009, 2021). Sin embargo, la adopción de FIWARE en entornos organizacionales enfrenta barreras operacionales relevantes: la heterogeneidad de configuraciones, la ausencia de estándares de automatización y la dificultad para garantizar reproducibilidad y auditabilidad en despliegues de producción.

El paradigma GitOps, acuñado por Weaveworks en 2017 (Limoncelli, 2018) y consolidado mediante herramientas como ArgoCD y Flux, propone que el estado deseado de los sistemas se defina íntegramente en repositorios Git, con un agente de software responsable de garantizar la convergencia continua entre dicha especificación y el estado real del sistema. Combinado con los principios de Infrastructure as Code (IaC) y Continuous Delivery, este paradigma constituye una respuesta técnica rigurosa a los desafíos operacionales identificados en el despliegue de plataformas FIWARE.

## 1.2 Planteamiento del Problema

El problema central que motiva el presente trabajo puede formularse en los siguientes términos:

> *¿Es posible definir un modelo de referencia arquitectónico reproducible, seguro y alineado con los estándares europeos de Data Spaces que permita el despliegue automatizado de una plataforma FIWARE sobre infraestructura cloud, utilizando el paradigma GitOps como mecanismo de gestión del ciclo de vida?*

Esta pregunta de investigación se articula en torno a tres brechas identificadas en la literatura y en la práctica profesional:

1. **Brecha de automatización:** Los despliegues de componentes FIWARE documentados en la literatura se basan predominantemente en procedimientos manuales o semi-automatizados, sin integración con sistemas de control de versiones ni pipelines de validación continua.
2. **Brecha de reproducibilidad:** La ausencia de una definición declarativa e inmutable del estado del sistema dificulta la reproducción exacta de entornos, comprometiendo tanto la fiabilidad de las pruebas como la trazabilidad de los cambios a lo largo del ciclo de vida del sistema.
3. **Brecha de integración con marcos de confianza:** Los trabajos existentes no abordan de forma integrada la conexión entre la infraestructura GitOps y los marcos de confianza interoperables —iSHARE, DSBA— que los Data Spaces europeos requieren para garantizar la autenticación y autorización federada entre participantes.

## 1.3 Objetivos

### Objetivo General

Diseñar, implementar y validar un modelo de referencia arquitectónico para el despliegue automatizado de una plataforma de Data Space basada en FIWARE sobre AWS, aplicando el paradigma GitOps con ArgoCD y garantizando reproducibilidad, trazabilidad y conformidad con los estándares europeos de interoperabilidad.

### Objetivos Específicos

- **OE-1:** Analizar y comparar los estándares, marcos de referencia y tecnologías relevantes en el ámbito de los Data Spaces europeos, GitOps y FIWARE, identificando brechas y oportunidades de integración.
- **OE-2:** Definir una arquitectura de referencia que integre los principios GitOps con los componentes FIWARE (Orion-LD, Keyrock, Kong) y el marco de confianza iSHARE/DSBA sobre infraestructura AWS EKS.
- **OE-3:** Implementar la infraestructura cloud mediante Terraform (VPC, EKS, IAM, Secrets Manager) siguiendo principios de Infrastructure as Code con gestión de estado remoto seguro.
- **OE-4:** Desarrollar el repositorio GitOps con manifests Helm y configuración ArgoCD (patrón App of Apps) que permita el despliegue declarativo y reproducible de todos los componentes de la plataforma.
- **OE-5:** Integrar pipelines de integración continua (GitHub Actions) con validación estática de seguridad, lint de manifests y gates de aprobación para cambios de infraestructura.
- **OE-6:** Validar el modelo mediante un conjunto de pruebas funcionales y métricas operacionales que incluyan tiempo de despliegue, *Recovery Time Objective* (RTO), trazabilidad de cambios y conformidad de seguridad.

## 1.4 Alcance y Limitaciones

**Dentro del alcance:**
- Diseño e implementación de la infraestructura AWS (VPC, EKS) mediante Terraform
- Configuración de ArgoCD como operador GitOps con el patrón App of Apps
- Despliegue de los componentes FIWARE: Orion-LD, Keyrock, Kong y MongoDB
- Integración con el marco de confianza iSHARE para autenticación y autorización federada
- Gestión de secretos mediante External Secrets Operator y AWS Secrets Manager
- Pipelines CI/CD con validación de seguridad estática
- Documentación técnica y académica del modelo de referencia

**Fuera del alcance:**
- Implementación de conectores de datos tipo IDS/IDSA para intercambio B2B
- Federación multi-clúster o despliegue multi-región
- Integración con catálogos de datos Gaia-X (GXFS)
- Evaluación de rendimiento bajo carga (*load testing*) a escala de producción
- Certificación formal frente a requisitos normativos del DGA

**Limitaciones reconocidas:**
- El entorno de validación es de laboratorio —2 nodos `t3a.large` en modalidad SPOT— y no representa una instalación de producción con requisitos de alta disponibilidad
- El marco iSHARE se integra en modalidad *sandbox*, sin certificado eIDAS emitido por una autoridad de certificación reconocida; los flujos de autenticación son funcionalmente equivalentes, aunque no aptos para participación en un Data Space productivo certificado
- Las restricciones presupuestarias del entorno de laboratorio limitan el tiempo de actividad de la infraestructura de validación

## 1.5 Estructura de la Memoria

El presente documento se organiza en los siguientes capítulos:

- **Capítulo 2 — Estado del Arte:** Revisión sistemática de la literatura y análisis comparativo de tecnologías en los ámbitos de Data Spaces, FIWARE, GitOps e Infrastructure as Code.
- **Capítulo 3 — Metodología:** Descripción del paradigma de investigación (Design Science Research), fases del proyecto y criterios de evaluación definidos mediante KPIs.
- **Capítulo 4 — Arquitectura y Diseño:** Definición del modelo de referencia, decisiones de arquitectura documentadas (ADR) y diagramas de sistema siguiendo el modelo C4.
- **Capítulo 5 — Implementación:** Descripción técnica de los componentes desarrollados, incluyendo el framework IaC, los manifests GitOps y los pipelines CI/CD.
- **Capítulo 6 — Resultados y Evaluación:** Métricas de validación, evidencias de funcionamiento del sistema y análisis de conformidad con los KPIs establecidos.
- **Capítulo 7 — Conclusiones:** Síntesis de contribuciones, limitaciones del trabajo y líneas de investigación futura.
