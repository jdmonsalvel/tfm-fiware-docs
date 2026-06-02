# 7. Conclusiones y Trabajo Futuro

## 7.1 Síntesis de Contribuciones

El presente trabajo ha abordado el diseño, implementación y validación de un modelo de referencia arquitectónico para el despliegue automatizado de una plataforma de Data Space basada en componentes FIWARE sobre infraestructura AWS, con GitOps como mecanismo central de gestión del ciclo de vida. Las contribuciones principales pueden sintetizarse en tres aportaciones diferenciadas:

**Contribución 1 — Modelo de referencia integrado.** Se ha propuesto y documentado una arquitectura que integra de forma coherente tecnologías que la literatura existente había tratado de forma independiente: el paradigma GitOps implementado con ArgoCD, los componentes FIWARE (Orion-LD, Keyrock, Kong), la infraestructura cloud en AWS EKS aprovisionada mediante Terraform, y los marcos de confianza para Data Spaces europeos (iSHARE/DSBA). La revisión bibliográfica realizada no ha identificado trabajos previos que aborden esta intersección de forma integrada, lo que confiere carácter original a la contribución.

**Contribución 2 — Artefacto técnico reproducible.** Los repositorios generados constituyen un artefacto técnico directamente utilizable por organizaciones que deseen implementar Data Spaces basados en FIWARE. El diseño modular del framework —módulos Terraform independientes, Helm values parametrizados y configuración GitOps declarativa— facilita la adaptación a contextos organizacionales distintos del entorno de laboratorio en el que fue validado.

**Contribución 3 — Pipeline de seguridad formalizado.** Se ha definido e implementado un pipeline CI/CD con capas de validación de seguridad estática mediante Checkov, TruffleHog y kubeconform, diseñado específicamente para el contexto de los Data Spaces, donde la integridad de los manifests de despliegue es un requisito crítico de cara a la conformidad regulatoria.

## 7.2 Cumplimiento de Objetivos Específicos

| Objetivo | Estado | Observaciones |
|----------|--------|---------------|
| OE-1: Análisis comparativo de tecnologías | ✅ Cumplido | Capítulo 2, tablas comparativas FIWARE/ArgoCD, conclusiones del estado del arte |
| OE-2: Definición de arquitectura de referencia | ✅ Cumplido | Capítulo 4, diagramas C4 y flujo iSHARE documentado |
| OE-3: Implementación IaC con Terraform | ✅ Cumplido | Framework de 25 módulos, VPC + EKS + bootstrap de addons |
| OE-4: Repositorio GitOps con App of Apps | ✅ Cumplido | ArgoCD con 5 Applications FIWARE en producción |
| OE-5: Pipeline CI/CD con validación de seguridad | ✅ Cumplido | 4 workflows de GitHub Actions operativos |
| OE-6: Validación con métricas operacionales | 🔄 En progreso | Smoke test E2E pendiente de ejecución completa |

## 7.3 Limitaciones del Trabajo

**Escala de laboratorio.** El entorno de validación opera con dos nodos `t3a.large` en modalidad SPOT, una configuración que no reproduce las condiciones de carga propias de un entorno de producción de alta disponibilidad. Las métricas de tiempo de despliegue y *Recovery Time Objective* obtenidas deben interpretarse, por tanto, como valores de referencia y no como garantías de rendimiento en producción.

**Marco iSHARE en modalidad *sandbox*.** La integración con el esquema de confianza iSHARE se ha llevado a cabo utilizando certificados de prueba, sin disponer de un certificado eIDAS emitido por una autoridad de certificación reconocida. Si bien los flujos de autenticación son funcionalmente equivalentes a los de un entorno certificado, la plataforma implementada no reúne los requisitos formales para la participación en un Data Space productivo bajo el marco de confianza vigente.

**MongoDB en modo *standalone*.** La base de datos de persistencia de Orion-LD se despliega en una única instancia sin replicación, lo que introduce un punto único de fallo para los datos de contexto del Data Space. Esta decisión de diseño, documentada como deuda técnica en el ADR-003, está justificada por el alcance académico del trabajo y deberá resolverse antes de cualquier despliegue en producción.

**Ausencia de conectores IDSA.** El trabajo no contempla la implementación de conectores de datos tipo IDS (*International Data Spaces Connector*) para el intercambio de datos entre organizaciones según el modelo IDSA RAM, lo que limita el alcance del Data Space implementado al entorno de un único proveedor de datos.

## 7.4 Líneas de Investigación y Trabajo Futuro

A partir de las limitaciones identificadas y de las tendencias emergentes en el campo de los Data Spaces, se proponen las siguientes líneas de trabajo futuro:

**Federación multi-clúster.** Extensión del modelo hacia la gestión de múltiples clústeres EKS en diferentes regiones AWS o proveedores cloud heterogéneos, mediante ArgoCD ApplicationSets como mecanismo de gestión declarativa de flota (*fleet management*).

**Integración de conectores IDSA.** Incorporación de un conector IDS basado en el Eclipse Dataspace Connector (EDC) que habilite el intercambio de datos B2B entre participantes de distintos Data Spaces conforme al protocolo IDS-G, completando así la arquitectura de confianza implementada.

**Observabilidad avanzada con OpenTelemetry.** Implementación de trazas distribuidas mediante el OpenTelemetry Collector para correlacionar transacciones a través de la cadena completa de componentes del Data Space (Kong → Keyrock → Orion-LD → MongoDB), lo que facilitaría el diagnóstico en entornos de producción.

**Evaluación de conformidad con el DGA.** Desarrollo de un conjunto de pruebas automatizadas que verifiquen la conformidad del intermediario de datos implementado con los requisitos técnicos del *Data Governance Act* (DGA, Reglamento UE 2022/868), incluyendo los mecanismos de portabilidad de datos y revocación de consentimiento.

**GitOps aplicado a pipelines de datos.** Extensión del paradigma GitOps a los flujos de ingestión y transformación de datos —Apache Spark, AWS Glue—, de forma que estos queden versionados junto con la infraestructura y la configuración de aplicaciones en el mismo repositorio de referencia.

## 7.5 Reflexión Final

Los resultados obtenidos en el presente trabajo evidencian que la convergencia entre el paradigma GitOps, la infraestructura como código y los componentes FIWARE es no solo técnicamente viable, sino que produce un sistema con propiedades de auditabilidad, reproducibilidad y seguridad que resultan difícilmente alcanzables mediante enfoques operacionales tradicionales. El hecho de que el repositorio Git actúe como *Single Source of Truth* del estado del sistema transforma el historial de versiones en un registro inmutable de auditoría: cada modificación en la infraestructura o en los componentes de la plataforma queda firmada, trazada y revertible, una característica de especial relevancia para la conformidad regulatoria que exige el *Data Governance Act*.

El modelo de referencia propuesto no pretende agotar las posibilidades de implementación de un Data Space conforme con los estándares europeos, sino establecer una base técnica concreta, reproducible y documentada sobre la que proyectos futuros —tanto académicos como industriales— puedan construir con garantías de calidad y trazabilidad.
