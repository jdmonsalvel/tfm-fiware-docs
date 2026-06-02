# 4. Arquitectura y Diseño

## 4.1 Principios de Diseño

El diseño del modelo de referencia se articula en torno a seis principios arquitectónicos derivados de los paradigmas GitOps (CNCF, 2022), cloud-native (CNCF, 2023) y los requisitos de los Data Spaces europeos (DSBA, 2023):

1. **Declaratividad:** Todo el estado del sistema —tanto la infraestructura como las aplicaciones— se define mediante archivos declarativos versionados en Git. Las operaciones imperativas se eliminan del flujo operacional nominal.
2. **Inmutabilidad:** Los artefactos desplegados (imágenes de contenedor, charts Helm) se referencian mediante *digests* o versiones fijadas, garantizando que el mismo commit siempre produce el mismo despliegue.
3. **Mínimo privilegio:** Los componentes solo obtienen los permisos estrictamente necesarios para su función. Los roles IAM de AWS siguen el principio de least-privilege con granularidad de servicio. Los roles Kubernetes se definen mediante RBAC con scope de namespace.
4. **Defense in depth:** La seguridad se implementa en múltiples capas: red (Security Groups, Network Policies), identidad (IRSA, OIDC), aplicación (Kong PEP, validación JWT) y datos (cifrado en reposo con KMS).
5. **Observabilidad by design:** Los componentes exponen métricas en formato Prometheus, logs estructurados y trazas distribuidas desde el momento del despliegue inicial.
6. **Soberanía de datos:** Los datos nunca salen del perímetro definido sin pasar por el mecanismo de control de acceso. Los secretos nunca se almacenan en el repositorio Git ni en imágenes de contenedor.

## 4.2 Vista Contextual (C4 — Level 1)

> **Figura 4.1** — Diagrama C4 Level 1: contexto del sistema (ver `docs/diagrams/README.md`).

El sistema interactúa con tres actores y dos sistemas externos:

- **Ingeniero DevOps (actor primario):** Gestiona el repositorio Git (manifests, IaC, configuración). Es el único actor con acceso de escritura al repositorio.
- **Consumidor de Datos (actor externo):** Aplicación o servicio que accede a datos de contexto mediante la API NGSI-LD. Solo tiene acceso de lectura, mediado por Kong.
- **Proveedor de Datos (actor externo):** Produce y publica entidades NGSI-LD en el Context Broker. Puede tener acceso de escritura condicionado por políticas.
- **GitHub (sistema externo):** Repositorio Git que actúa como *Single Source of Truth*. Almacena tanto el estado deseado del sistema como el historial completo de cambios.
- **iSHARE Satellite (sistema externo):** Ancla de confianza del Data Space. Valida que los participantes están certificados y son de confianza antes de emitir tokens de acceso.

## 4.3 Vista de Contenedores (C4 — Level 2)

> **Figura 4.2** — Diagrama C4 Level 2: contenedores y namespaces Kubernetes (ver `docs/diagrams/README.md`).

La plataforma se despliega en un clúster Amazon EKS organizado en cuatro namespaces con responsabilidades claramente separadas:

### 4.3.1 Namespace `argocd`

Contiene el operador GitOps. ArgoCD se instala mediante su chart Helm oficial y se configura para monitorizar el repositorio Git del proyecto. El patrón **App of Apps** (ArgoCD, 2023) se implementa mediante una Application raíz que gestiona el ciclo de vida del resto de Applications, garantizando bootstrapping idempotente del sistema completo desde un único punto de entrada.

### 4.3.2 Namespace `trust-anchor`

Contiene la infraestructura de identidad del Data Space:

- **Keyrock:** Identity Provider (IdP) raíz. Emite Verifiable Credentials a los participantes e implementa el protocolo iSHARE para autenticación M2M. Persiste en MySQL.
- **Trusted Issuers List (TIL):** Registro de emisores de credenciales confiables del Data Space.
- **Credentials Config Service (CCS):** Configuración de credenciales para el flujo de autorización SIOP2/OIDC4VP.
- **MySQL:** Base de datos relacional para Keyrock (usuarios, organizaciones, aplicaciones y permisos).

### 4.3.3 Namespace `provider`

Contiene la capa de datos del Data Space:

- **Orion-LD:** Context Broker NGSI-LD. Gestiona el ciclo de vida de entidades de contexto (creación, actualización, suscripciones). Expone la API REST en el puerto 1026. Persiste en MongoDB.
- **Kong:** PEP Proxy / API Gateway. Intercepta todas las solicitudes a Orion-LD y verifica que el token Bearer presentado es válido según el flujo iSHARE antes de enrutar la petición al Context Broker.
- **MongoDB:** Base de datos documental para Orion-LD. Desplegada en modo standalone para el entorno de laboratorio.

### 4.3.4 Namespace `platform`

Servicios de plataforma transversales:

- **External Secrets Operator:** Sincroniza secretos desde AWS Secrets Manager hacia Kubernetes Secrets mediante el CRD `ExternalSecret`. Utiliza IRSA para autenticarse en AWS sin credenciales estáticas.
- **cert-manager:** Gestiona certificados TLS/X.509. Provisiona y renueva automáticamente certificados Let's Encrypt para los Ingress de la plataforma.
- **ingress-nginx:** Enruta el tráfico HTTPS externo hacia los servicios internos, terminando TLS en el borde del clúster.

## 4.4 Topología de Red AWS

> **Figura 4.3** — Diagrama de red AWS: VPC en tres capas, NLB, NAT Gateway y nodos EKS (ver `docs/diagrams/README.md`).

La infraestructura de red sigue el patrón recomendado por la AWS EKS Best Practices Guide (AWS, 2023):

- **VPC:** Bloque CIDR `/16` (65.536 IPs) en la región `eu-west-1` (Irlanda), seleccionada por su conformidad con el RGPD y la proximidad a los nodos del ecosistema Gaia-X europeo.
- **Subredes públicas (3× `/24`):** Alojan el NLB de ingress-nginx y el NAT Gateway. El tráfico de entrada (ingress) se concentra en el NLB.
- **Subredes privadas de aplicación (3× `/24`):** Alojan los nodos worker de EKS (`t3a.large` SPOT). Los nodos no tienen IPs públicas y acceden a internet mediante el NAT Gateway.
- **Subredes de datos (3× `/24`):** Reservadas para bases de datos externas (RDS, ElastiCache). En el entorno de laboratorio las bases de datos se despliegan dentro del clúster.
- **NAT Gateway:** Punto de salida para los nodos privados. Permite la descarga de imágenes desde registros externos sin exponer los nodos a internet.

## 4.5 Modelo de Identidades y Acceso

### 4.5.1 IAM para AWS (IRSA)

La integración entre pods Kubernetes y servicios AWS se implementa mediante **IRSA** (*IAM Roles for Service Accounts*). Este mecanismo asocia un rol IAM a una ServiceAccount de Kubernetes mediante una anotación y un proveedor OIDC, permitiendo a los pods asumir permisos AWS sin credenciales estáticas. External Secrets Operator utiliza este mecanismo para acceder a AWS Secrets Manager con el principio de mínimo privilegio.

### 4.5.2 Control de Acceso al Data Space (iSHARE)

> **Figura 4.4** — Flujo iSHARE M2M: 6 pasos de autenticación y autorización (ver `docs/diagrams/README.md`).

El flujo de acceso implementa el protocolo iSHARE M2M sobre OAuth2, con los siguientes pasos:

1. El Consumidor presenta un *iSHARE JWT* firmado con su clave privada (certificado eIDAS/X.509) a Keyrock.
2. Keyrock verifica la validez del JWT y consulta al iSHARE Satellite que el Consumidor es un participante certificado (*trusted party*).
3. Tras confirmación, Keyrock emite un *Access Token* JWT con tiempo de expiración corto (30 segundos, según la especificación iSHARE).
4. El Consumidor presenta el Access Token a Kong en cada solicitud NGSI-LD.
5. Kong delega la decisión de autorización en Keyrock, que evalúa la política XACML correspondiente al recurso solicitado.
6. Kong reenvía (o bloquea) la solicitud a Orion-LD según el veredicto de Keyrock.

## 4.6 Decisiones de Arquitectura (ADR)

### ADR-001: Selección de ArgoCD sobre FluxCD

| Campo | Detalle |
|-------|---------|
| **Estado** | Aceptado |
| **Contexto** | Se requiere un operador GitOps para el despliegue declarativo de los componentes FIWARE en Kubernetes. |
| **Decisión** | Se selecciona ArgoCD v2.11 sobre FluxCD v2.3. |
| **Justificación** | ArgoCD ofrece una interfaz gráfica que facilita la demostración y la supervisión visual del estado de sincronización —aspecto de especial relevancia en el contexto académico—, soporte nativo para el patrón App of Apps sin dependencias adicionales, y una adopción empresarial más amplia que incrementa la transferibilidad del modelo propuesto. |
| **Consecuencias** | Mayor consumo de memoria en el clúster (~512 MB adicionales respecto a Flux), asumible para el entorno de laboratorio. |

### ADR-002: Región AWS eu-west-1

| Campo | Detalle |
|-------|---------|
| **Estado** | Aceptado |
| **Contexto** | Se requiere seleccionar una región AWS para el despliegue de la infraestructura. |
| **Decisión** | Se utiliza la región `eu-west-1` (Irlanda). |
| **Justificación** | Conformidad con el RGPD y residencia de datos en la Unión Europea; disponibilidad de todos los servicios AWS requeridos (EKS, Secrets Manager); y menor latencia hacia los nodos del ecosistema Gaia-X europeo. |
| **Consecuencias** | No se identifican consecuencias negativas para el alcance del trabajo. |

### ADR-003: MongoDB en modo *standalone*

| Campo | Detalle |
|-------|---------|
| **Estado** | Aceptado (con deuda técnica documentada) |
| **Contexto** | Orion-LD requiere MongoDB como base de datos de persistencia. |
| **Decisión** | Se despliega MongoDB en modo *standalone* (una única instancia) para el entorno de laboratorio. |
| **Justificación** | El modo *replica set* (3 miembros) incrementaría los costes AWS en aproximadamente 5 USD/día y la complejidad operacional sin aportar valor adicional a los objetivos de investigación definidos. |
| **Deuda técnica** | En entornos de producción, MongoDB debe desplegarse en modo *replica set* con 3 miembros para garantizar alta disponibilidad y consistencia fuerte. Esta mejora se documenta en el Capítulo 7. |

### ADR-004: Instancias t3a.large en modalidad SPOT

| Campo | Detalle |
|-------|---------|
| **Estado** | Aceptado |
| **Contexto** | Se requiere seleccionar el tipo de instancia y la modalidad de compra para los nodos worker de EKS. |
| **Decisión** | Dos nodos `t3a.large` (2 vCPU / 8 GB RAM) en modalidad SPOT. |
| **Justificación** | El stack FIWARE completo demanda aproximadamente 8-10 GB de RAM; `t3a.large` es el tamaño mínimo viable. Las instancias SPOT reducen el coste en torno a un 70% respecto a On-Demand, lo que hace viable el entorno de laboratorio desde el punto de vista presupuestario. La activación de VPC CNI Prefix Delegation eleva el límite de pods por nodo hasta 110. |
| **Consecuencias** | Las interrupciones SPOT pueden afectar puntualmente a la disponibilidad del servicio. El riesgo se mitiga distribuyendo los nodos en distintas zonas de disponibilidad (`eu-west-1b` y `eu-west-1c`) y aplicando `PodDisruptionBudget` en los componentes críticos. |

### ADR-005: Separación de responsabilidades entre Terraform y ArgoCD

| Campo | Detalle |
|-------|---------|
| **Estado** | Aceptado |
| **Contexto** | Es necesario delimitar qué componentes gestiona Terraform y cuáles gestiona ArgoCD. |
| **Decisión** | Terraform gestiona los componentes de plataforma (cert-manager, External Secrets Operator, ingress-nginx, AWS Load Balancer Controller); ArgoCD gestiona exclusivamente los workloads FIWARE. |
| **Justificación** | Los componentes de plataforma son prerrequisitos para el funcionamiento de ArgoCD: cert-manager proporciona el TLS del servidor de ArgoCD y ESO inyecta los secretos que las aplicaciones FIWARE necesitan. Delegarlos a ArgoCD crearía una dependencia circular en el proceso de *bootstrap*. |
| **Consecuencias** | Mayor complejidad en el módulo `eks/bootstrap` de Terraform. A cambio, se establece una separación limpia de responsabilidades: Terraform gestiona la infraestructura y la plataforma; ArgoCD gestiona los workloads de aplicación. |
