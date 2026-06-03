# Anexo C. Decisiones de Arquitectura (ADRs) — Registro Completo

Las Decisiones de Arquitectura (Architecture Decision Records, ADRs) documentan las elecciones de diseño más significativas del proyecto: el contexto que motivó cada decisión, las alternativas consideradas, la opción seleccionada y sus consecuencias. Este registro complementa la descripción técnica del §4.1.5 de la memoria con el detalle completo de cada ADR.

---

## ADR-001: Selección de ArgoCD como operador GitOps

**Estado:** Aceptado  
**Fecha:** Fase 1 — Análisis y Diseño

**Contexto:** El trabajo requiere un operador GitOps para el despliegue declarativo y la reconciliación continua de los componentes FIWARE en Kubernetes. Las dos opciones principales en el ecosistema CNCF Graduated son ArgoCD y FluxCD.

**Alternativas consideradas:**

| Opción | Ventajas | Inconvenientes |
|--------|----------|----------------|
| ArgoCD v2.14 | UI completa, App of Apps nativo, Sync Waves, mayor adopción enterprise | Mayor consumo RAM (~512 MB baseline) |
| FluxCD v2.3 | Menor consumo RAM (~256 MB), rollback automático de HelmRelease | Sin UI, Sync Waves más complejas, menor adopción |

**Decisión:** ArgoCD v2.14.

**Justificación:** La interfaz gráfica de ArgoCD es necesaria para la demostración académica y para la supervisión visual del estado del Data Space durante la evaluación del trabajo. El soporte nativo para App of Apps sin dependencias adicionales simplifica el bootstrapping, y el mecanismo de Sync Waves es crítico para gestionar las dependencias entre el Trust Anchor y los componentes del Provider.

**Consecuencias:** Mayor consumo de RAM del operador GitOps (~512 MB adicionales respecto a Flux). Asumible dado el dimensionamiento del clúster (2× t3a.large, 14.2 GB RAM total allocatable).

---

## ADR-002: Región AWS eu-west-1 (Irlanda)

**Estado:** Aceptado  
**Fecha:** Fase 1 — Análisis y Diseño

**Contexto:** El Data Space debe operar con residencia de datos en la Unión Europea para ser conforme con el Data Governance Act (DGA, Reglamento UE 2022/868).

**Decisión:** Región `eu-west-1` (Irlanda).

**Justificación:** (1) Conformidad RGPD: datos almacenados en territorio UE. (2) Disponibilidad de todos los servicios AWS requeridos: EKS, Secrets Manager, Lambda, EventBridge, DynamoDB, S3. (3) Menor latencia hacia los nodos del ecosistema Gaia-X europeo. (4) Tres zonas de disponibilidad (eu-west-1a, 1b, 1c) para distribución multi-AZ.

**Consecuencias:** No se identifican consecuencias negativas para el alcance del trabajo.

---

## ADR-003: MongoDB en modo standalone

**Estado:** Aceptado (con deuda técnica documentada)  
**Fecha:** Fase 3 — Plataforma GitOps y FIWARE

**Contexto:** Orion-LD requiere MongoDB como backend de persistencia. Las opciones son: modo standalone (una instancia), modo replica set (mínimo 3 instancias) y Amazon DocumentDB.

**Decisión:** MongoDB en modo standalone como subchart de Orion-LD.

**Justificación:** El modo replica set incrementaría el consumo de RAM en ~1.5 GB adicionales y requeriría 3 pods MongoDB, lo que compromete la viabilidad del entorno de laboratorio. Amazon DocumentDB añadiría un coste fijo de ~$180/mes, fuera del presupuesto del entorno de laboratorio. El modo standalone es suficiente para demostrar el funcionamiento del Data Space en un contexto académico.

**Deuda técnica:** En un entorno de producción, MongoDB debe operar en modo replica set con 3 miembros para garantizar alta disponibilidad y consistencia fuerte de los datos de contexto.

---

## ADR-004: Instancias t3a.large en modalidad SPOT

**Estado:** Aceptado  
**Fecha:** Fase 2 — Infraestructura

**Contexto:** El clúster EKS requiere nodos worker con capacidad suficiente para ejecutar el stack FIWARE completo (~3.3 GB RAM de requests, ~6.3 GB de límites). El coste del entorno de laboratorio debe ser sostenible para la duración del TFM.

**Alternativas consideradas:**

| Tipo | RAM | Precio SPOT | Viabilidad |
|------|-----|-------------|------------|
| t3.medium | 4 GB | ~$0.016/h | ❌ OOM frecuente |
| t3a.large | 8 GB | ~$0.025/h | ✅ Mínimo viable |
| t3a.xlarge | 16 GB | ~$0.050/h | ✅ Holgado (+100% coste) |

**Decisión:** 2× t3a.large SPOT en zonas eu-west-1a y eu-west-1c, con scheduler Lambda que escala a 0 en horario de inactividad.

**Justificación:** La variante AMD (`t3a`) es un 10% más económica que `t3`. El modo SPOT reduce el coste en ~70% respecto a On-Demand. La distribución en dos AZs distintas garantiza tolerancia a fallos de zona. El scheduler Lambda (EventBridge + Lambda Python 3.12) reduce el coste mensual de ~$160 a ~$50-60 USD al apagar los nodos fuera del horario de trabajo.

**Consecuencias:** Riesgo de interrupción SPOT mitigado por la distribución multi-AZ y los `PodDisruptionBudget`.

---

## ADR-005: Separación de responsabilidades Terraform / ArgoCD

**Estado:** Aceptado  
**Fecha:** Fase 2 — Infraestructura

**Contexto:** El sistema tiene componentes de plataforma (cert-manager, ESO, ingress-nginx, AWS LBC) que son prerrequisitos del propio ArgoCD. Delegarlos a ArgoCD crearía una dependencia circular: ArgoCD no puede instalar sus propios prerrequisitos.

**Decisión:** Terraform gestiona la infraestructura AWS y los componentes de plataforma; ArgoCD gestiona exclusivamente los workloads FIWARE.

**Justificación:** La separación elimina la dependencia circular y establece una frontera clara de responsabilidades: Terraform = infraestructura + plataforma (capa 0); ArgoCD = workloads de aplicación (capa 1+). El módulo `eks/bootstrap` instala los addons de plataforma vía Helm inmediatamente después de crear el clúster, garantizando que el clúster está operativo antes de que ArgoCD intente gestionar los workloads.

**Consecuencias:** Mayor complejidad en el módulo `eks/bootstrap` de Terraform. La separación es limpia y no introduce acoplamiento entre las dos capas de gestión.

---

## ADR-006: Kong en modo DB-less con chart oficial konghq

**Estado:** Aceptado  
**Fecha:** Fase 3 — Plataforma GitOps y FIWARE

**Contexto:** Kong actúa como PEP (Policy Enforcement Point) frente a Orion-LD. Requiere una configuración para definir servicios, rutas y plugins. Las opciones son: modo DB (con PostgreSQL), modo DB-less (configuración declarativa en ConfigMap) y el chart de Bitnami vs. el chart oficial de Kong.

**Decisión:** Kong en modo DB-less usando el chart oficial `kong/kong` v3.2.0 de `charts.konghq.com`.

**Justificación:** El modo DB elimina la dependencia de PostgreSQL (~512 MB RAM adicional), lo que es crítico dado el presupuesto de recursos del entorno de laboratorio. La configuración declarativa en un ConfigMap mantiene el estado de Kong bajo control de versiones Git, alineándose con los principios GitOps del proyecto. El chart de Bitnami fue descartado porque las imágenes `bitnami/kong:3.9.x` no están disponibles en Docker Hub (Bitnami migró a un registro de pago a partir de 2024). El chart oficial `kong/kong` usa la imagen oficial `kong:3.9` que está disponible públicamente.

**Consecuencias:** Los cambios en la configuración de Kong (rutas, plugins, consumers) requieren actualizar el ConfigMap y provocar un rolling restart del pod. No hay Admin API dinámica en modo DB-less. En producción se recomienda modo DB con PostgreSQL para soporte de configuración dinámica.

*Fuente:* Elaboración propia.
