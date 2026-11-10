Glosario 
  1. Marco europeo y de confianza:
     - Data Space y soberanía de datos.
     - Gaia-X.
     - DGA: Reglamento (UE) 2022/868, aplicable desde septiembre de 2023.
     - Data Act: Reglamento (UE) 2023/2854, aplicable desde el 12 de septiembre de 2025.
     - eIDAS, iSHARE y su Satellite, DSBA, IDSA/conector IDS, Eclipse EDC, Verifiable Credentials/DID, Trust Anchor y Provider/Consumer.
  2. Componentes FIWARE: NGSI-LD, Orion-LD, MongoDB, Keyrock, MySQL, TIL frente a TIR, CCS y Kong, con sus versiones reales. También Wilma (chart en el repo, sin desplegar) y el chart paraguas DSC (no usado).
  3. Control de acceso XACML:
     - PEP: Kong.
     - PDP: Keyrock/AuthZForce como objetivo; hoy decide la lógica del plugin.
     - PIP: la TIL.
     - PAP: Git.
     - Además: JWT con sus claims, HS256 frente a RS256, fail-closed y el significado de 401/403/503.
  4. Arquitectura y método:
     - C4, que en la diapositiva 7 es el nivel 2, contenedores. Cuando dices "arquitectura 4C" te refieres a esto: el nombre correcto es C4.
     - ADR-003 y ADR-006.
     - Design Science Research.
  5. GitOps y Kubernetes: los 4 principios de OpenGitOps, pull frente a push, App of Apps, sync waves, drift, selfHeal y prune, PVC frente a emptyDir, ESO, cert-manager con DNS-01, IRSA y LBC.
  6. IaC y AWS: módulos, tfvars, state en S3 con bloqueo en DynamoDB, idempotencia, release-please, VPC 3×3, SPOT y RTO.
  7. CI/CD y seguridad: OIDC, environment de aprobación, Checkov (soft_fail), TruffleHog (--only-verified), shift-left y mínimo privilegio.
  8. KPIs: cada uno con su resultado, y SE-1 ya matizado.


PRespuestas para el tribunal
¿Por qué ArgoCD y no FluxCD?
Elegí ArgoCD porque ofrece una interfaz y modelo de aplicaciones más adecuados para gestionar un Data Space con múltiples componentes y dependencias. El patrón App of Apps, las Sync Waves y el estado de salud por aplicación me permitían controlar el orden de despliegue y detectar fallos por componente. Flux es una alternativa válida, más ligera y muy buena para automatización pura, pero ArgoCD encajaba mejor con la necesidad de observabilidad y control del ciclo de vida.

¿Por qué FIWARE/iSHARE frente a Eclipse Dataspace Connector?
FIWARE me permitía construir un Data Space basado en NGSI-LD, con un Context Broker maduro y un ecosistema de componentes open source. iSHARE/DSBA encaja con el modelo de confianza federada que quería integrar. EDC es una alternativa sólida y más centrada en el conector de datos, pero el objetivo del TFM no era solo el intercambio puntual de datos, sino desplegar y operar una plataforma completa de forma reproducible con GitOps.

¿Por qué EKS y no GKE, AKS, k3s o ECS?
EKS porque el trabajo se centra en AWS y necesitaba un Kubernetes gestionado con integración nativa de IAM, IRSA, Secrets Manager y VPC. GKE y AKS habrían exigido adaptar la infraestructura a otro proveedor. k3s es válido para laboratorio, pero no representa un entorno cloud gestionado. ECS no es Kubernetes y limitaría la portabilidad del modelo GitOps basado en manifiestos y Helm.

¿Por qué Terraform frente a Pulumi o AWS CDK?
Terraform porque es el estándar de facto en Infrastructure as Code multi-cloud, con un ecosistema muy maduro de módulos, proveedores y herramientas de validación como Checkov. Además, su modelo declarativo en HCL encaja directamente con GitOps: el estado deseado se versiona y revisa en Git. Pulumi y CDK son buenas opciones, especialmente si se prioriza código general-purpose, pero no aportaban una ventaja suficiente para este caso.

¿Por qué MongoDB standalone? ¿Qué implicaciones tiene en producción?
Fue una decisión deliberada para el laboratorio, documentada en el ADR-003, para reducir coste y complejidad operativa. En producción no sería adecuado: MongoDB debe desplegarse como replica set de al menos tres miembros para alta disponibilidad y tolerancia a fallos. La arquitectura GitOps no cambia; solo cambia la configuración del entorno.

¿Cómo garantizas reproducibilidad real más allá de Terraform?
Con tres mecanismos. Primero, Terraform versiona y aprovisiona la infraestructura. Segundo, ArgoCD y Helm definen declarativamente el estado de las aplicaciones en Git. Tercero, el pipeline usa versiones inmutables del framework, no la rama principal, y aplica validaciones automáticas. Además, validé el re-despliegue tras destrucción total y la idempotencia con un nuevo terraform apply sin cambios.

¿Qué pasa si ArgoCD o Git fallan?
El clúster sigue ejecutando la última configuración sincronizada. GitOps gobierna el ciclo de vida y la reconciliación, no el runtime inmediato. Si Git falla, no hay cambios nuevos; si ArgoCD falla, el clúster sigue operativo, pero pierde la autocorrección y la capacidad de desplegar cambios. Por eso, en producción, ArgoCD y Git deben tener alta disponibilidad y backups.

¿Cómo escalas este laboratorio a producción multi-tenant?
Mantendría la misma base: Terraform para infraestructura y ArgoCD para aplicaciones, pero con separación por entornos o tenants mediante namespaces, proyectos de ArgoCD, políticas de red y cuotas de recursos. Para multi-clúster usaría ApplicationSets y GitOps por entorno. Además, añadiría autoscaling con Karpenter, MongoDB en replica set, observabilidad completa y controles de aislamiento por tenant.

¿Qué parte es contribución tuya y qué parte es integración de herramientas existentes?
Mi contribución es el modelo de referencia integrado: el diseño C4, el framework de 25 módulos Terraform, la estructura GitOps con App of Apps y Sync Waves, la integración de Kong como Policy Enforcement Point con la Trusted Issuers List, el pipeline seguro y la definición y medición de los KPIs. Las herramientas —Terraform, ArgoCD, FIWARE, Kong, GitHub Actions— son existentes; el aporte está en cómo las integro en un sistema completo, reproducible y auditable.

¿Cuál es la limitación más importante del trabajo?
La principal es que se valida en un entorno de laboratorio, con una sola réplica por componente, MongoDB standalone, dos nodos SPOT y JWT HS256 en sandbox. Eso limita la evidencia sobre alta disponibilidad, escalado real y conformidad productiva. Sin embargo, el diseño contempla la evolución a producción y el modelo es reutilizable cambiando la configuración del entorno.

¿Por qué solo 6 semanas?
Fue una ejecución intensiva y acotada: definí un alcance concreto, reutilicé mi experiencia previa en AWS, Kubernetes, Terraform y GitOps, y prioricé un artefacto funcional y medible. No significa que el problema sea trivial; significa que el trabajo se centró en construir y validar un modelo de referencia viable, dejando la operativa productiva como línea futura.

¿Por qué el KPI RD-1 no cumple?
Porque el umbral de 30 minutos era demasiado optimista para incluir la creación completa del clúster EKS. De los aproximadamente 40 minutos totales, unos 17 corresponden al aprovisionamiento inicial de EKS. El proceso GitOps posterior —validación, despliegue y reconciliación— es considerablemente más rápido. Es una limitación de definición del KPI y del coste de aprovisionamiento inicial, no del modelo GitOps.

¿Por qué HS256 en sandbox?
Porque en el laboratorio prioricé validar el flujo de autorización y la integración con Kong y la Trusted Issuers List de forma controlada y económica. HS256 es adecuado para pruebas sandbox, pero no para producción. En un despliegue real usaríamos certificados eIDAS y un iSHARE Satellite, con claves asimétricas y una cadena de confianza federada.

¿Por qué solo 2 nodos SPOT?
Por coste: era un entorno de laboratorio con presupuesto limitado. Los nodos SPOT permiten reducir coste, pero no son la opción ideal para cargas críticas. En producción usaría un pool de nodos con autoscaling, preferiblemente Karpenter, distribuido en varias zonas de disponibilidad y con tolerancias a interrupciones configuradas.

¿Qué ocurre si Git o ArgoCD caen?
El sistema sigue funcionando con la última configuración sincronizada. GitOps no es un componente en el camino de cada petición: es el mecanismo que declara y reconcilia el estado. La caída afecta a la capacidad de desplegar cambios y autocorregir desviaciones, no a la disponibilidad inmediata de las aplicaciones.

¿Qué aporta frente a los charts oficiales de FIWARE?
Los charts oficiales resuelven el despliegue de componentes, pero no proporcionan por sí solos un modelo operativo completo. Mi enfoque usa Applications independientes para tener salud, versionado y trazabilidad por componente; Sync Waves explícitas para respetar dependencias; y evita las dependencias ocultas de un Helm umbrella. Además, lo integro con Terraform, pipeline seguro, secretos, Kong e iSHARE, y lo valido con KPIs.

Respuestas extra probables
¿Por qué Kong y no otro API Gateway?
Porque Kong funciona como Policy Enforcement Point y permite validar JWT y aplicar políticas antes de que la petición llegue a Orion-LD. Es ligero, se despliega en modo DB-less y se integra bien en Kubernetes y GitOps.

¿Por qué Orion-LD y no otro Context Broker?
Porque Orion-LD implementa NGSI-LD, el estándar relevante para interoperabilidad semántica en los Data Spaces europeos. Es el componente central para publicar y consultar contexto de forma estandarizada.

¿Por qué GitHub Actions y no GitLab CI o Jenkins?
Porque el repositorio está en GitHub y Actions permite integrar validación, aprobación, OIDC y despliegue sin mantener infraestructura adicional de CI. Jenkins exigiría operar un controlador adicional; GitLab CI habría sido válido si el repositorio estuviera en GitLab.

¿Por qué OIDC en vez de claves estáticas?
Porque OIDC permite que GitHub Actions obtenga credenciales temporales de AWS sin almacenar secretos de larga duración. Reduce la superficie de ataque y elimina el riesgo de filtración de claves estáticas.

¿Cómo validaste la seguridad?
Con controles estáticos y pruebas funcionales. Checkov analiza el código Terraform, TruffleHog busca secretos expuestos y validé el comportamiento de Kong con cuatro escenarios: sin token, firma inválida, emisor no registrado y token válido.

¿Qué harías diferente si empezaras de nuevo?
Definiría el KPI de tiempo separando aprovisionamiento inicial de EKS del despliegue GitOps, y añadiría antes observabilidad con OpenTelemetry y pruebas automatizadas de conformidad. También exploraría antes la federación multi-clúster con ApplicationSets.

Regla para responder
Si te bloqueas, usa siempre esta estructura:

text
1. Decisión: "Elegí X porque..."
2. Motivo técnico: "Necesitaba..."
3. Límite honesto: "La alternativa Y también sería válida, pero..."
No digas “no lo probé” sin contexto. Di:

“No era parte del alcance validado; el diseño lo contempla como evolución y está documentado como trabajo futuro.”

Eso es una respuesta profesional, no una debilidad.

