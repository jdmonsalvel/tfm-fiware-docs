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
| OE-6: Validación con métricas operacionales | 🔄 En progreso | Smoke test E2E pendiente de ejecución completa |

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
