# Guion por diapositivas

## 1. Portada — 0:20

Buenos días. Soy Jesús David Monsalve Lezama y presento mi Trabajo Fin de Máster: Automatización GitOps de FIWARE Data Spaces, dirigido por Rafael Merlo Loranca.

El trabajo aborda el despliegue y la operación de una plataforma de espacio de datos basada en FIWARE sobre AWS de forma automatizada, reproducible y auditable mediante GitOps.

## 2. Índice — 0:15

La presentación sigue cinco bloques: contexto y objetivos, arquitectura, implementación GitOps, resultados medidos y conclusiones.

## 3. Contexto y problema — 1:00

La estrategia europea de datos —con Gaia-X, el Data Governance Act y el Data Act— exige infraestructuras soberanas, interoperables y trazables.

Sin embargo, los entornos FIWARE siguen desplegándose a menudo de forma manual o mediante Helm directo. Esto plantea tres brechas:

- Automatización, porque faltan pipelines CI/CD completos.
- Reproducibilidad, porque no existe una definición declarativa y versionada del estado completo del Data Space.
- Confianza, porque la infraestructura no está integrada con marcos como iSHARE y DSBA.
"iSHARE es un marco de confianza para compartir datos entre organizaciones: define roles y un registro de participantes, y usa tokens JWT firmados con certificados eIDAS.  DSBA es la alianza de Gaia-X, IDSA, FIWARE y BDVA que define una arquitectura técnica común para los Data Spaces europeos, basada en credenciales verificables y listas de emisores de confianza. 

De ahí surge la pregunta que guía el trabajo: ¿se puede desplegar y operar un Data Space FIWARE completo solo desde Git?

## 4. Objetivos — 0:50

El objetivo general fue diseñar, implementar y validar una arquitectura GitOps que desplegara de forma automatizada y reproducible un Data Space FIWARE sobre AWS.

Se concreta en seis objetivos: analizar el estado del arte; definir la arquitectura con C4; construir el framework de infraestructura como código; implementar el repositorio GitOps; integrar un pipeline CI/CD seguro; y validar el sistema con diez KPIs.

Los seis objetivos se cumplieron.

## 5. Metodología — 0:40

Seguí la metodología Design Science Research, porque el resultado principal es un artefacto tecnológico: un modelo de referencia reutilizable.

El trabajo se ejecutó en cuatro entregas iterativas: análisis y arquitectura; infraestructura con Terraform y EKS; plataforma GitOps con FIWARE accesible por HTTPS; y validación mediante KPIs.

Desde la primera entrega, Git es la fuente única de verdad.

## 6. Stack tecnológico — 0:30

La solución se organiza en cuatro capas:

- Infraestructura con AWS, Terraform y Amazon EKS.
- GitOps con ArgoCD, App of Apps, Sync Waves y Helm.
- CI/CD con GitHub Actions, OIDC, Checkov y TruffleHog.
		- Checkov: analiza el código de infraestructura (Terraform y manifiestos de Kubernetes) en busca de configuraciones inseguras antes de desplegar
		- TruffleHog: busca secretos filtrados (claves, tokens, contraseñas) en todo el historial de Git.
- Y la capa de Data Space, con Keyrock, la Trusted Issuers List, el Credentials Config Service, Orion-LD, Kong y External Secrets.
		- Keyrock: gestor de identidades de FIWARE. Administra usuarios y aplicaciones y emite tokens OAuth2.
		- TIL (Trusted Issuers List): lista de emisores de confianza. Kong la consulta para saber si quien firmó el token es un participante registrado.
		- CCS (Credentials Config Service): define qué tipo de credenciales acepta cada servicio del Data Space.
		-  Orion-LD: el Context Broker. Guarda y sirve los datos del proveedor mediante la API estándar NGSI-LD.
		- Kong (PEP): la puerta de entrada a Orion-LD. Comprueba el token y la TIL, y solo deja pasar las peticiones autorizadas (401/403/200).
		- External Secrets: copia las contraseñas desde AWS Secrets Manager al clúster como Secrets de Kubernetes, para que nunca estén en Git

## 7. Arquitectura C4 — 1:15

Esta es la vista de contenedores del modelo C4. Todo se ejecuta en un clúster EKS en eu-west-1, organizado en cuatro namespaces.

- **argocd** es el motor GitOps que gestiona el ciclo de vida.
- **trust-anchor** agrupa la capa de identidad y confianza: Keyrock, la Trusted Issuers List, el Credentials Config Service y MySQL.
- **provider** es la capa de datos: Kong actúa como Policy Enforcement Point delante de Orion-LD, que persiste en MongoDB.
- Y **platform** contiene los servicios transversales: ingress-nginx, cert-manager y External Secrets Operator.

Uso 2 de los 4 niveles de C4, según la §4.1.2 de la memoria:

  1. Nivel 1, Contexto (Figura 4.1). El sistema como una caja, con 3 actores y 2 sistemas externos:
     - Ingeniero DevOps: el único que escribe en Git.
     - Consumidor de Datos: accede a los datos por NGSI-LD a través de Kong.
     - Proveedor de Datos: publica entidades NGSI-LD.
     - GitHub: fuente única de verdad.
     - iSHARE Satellite: el ancla de confianza.
  2. Nivel 2, Contenedores (Figura 4.2, diapositiva 7). El clúster EKS por dentro, en 4 namespaces:
     - argocd
     - trust-anchor: Keyrock, TIL, CCS y MySQL.
     - provider: Kong, Orion-LD y MongoDB.
     - platform: ingress-nginx, cert-manager y External Secrets.

  Los niveles 3 (Componentes) y 4 (Código) no los usas.


La idea clave es que ningún componente se despliega manualmente: su estado deseado está en Git y ArgoCD lo reconcilia.

## 8. Infraestructura AWS — 1:00

En AWS, la plataforma se despliega sobre una VPC de tres capas —pública, aplicación y datos— distribuida en tres zonas de disponibilidad.

El clúster EKS utiliza dos nodos t3a.large en modo SPOT, una decisión coherente con el carácter de laboratorio del entorno.

El estado de Terraform está en S3 con bloqueo en DynamoDB. Los secretos residen en Secrets Manager y se proyectan al clúster mediante External Secrets Operator e IRSA, sin credenciales estáticas.

También incluí una Lambda con EventBridge que apaga el clúster fuera de horario para controlar el coste.

## 9. Infraestructura como código — 0:50

La infraestructura se construyó como un framework propio de 25 módulos Terraform reutilizables, versionado por tags.

Gestiona 47 recursos de AWS y es idempotente: tras el despliegue inicial, un nuevo terraform apply devuelve cero cambios.

Cada entorno se define con un único terraform.tfvars. Crear un entorno nuevo no requiere escribir código: solo variables. Por ejemplo, actualizar la versión de EKS se reduce a cambiar una línea.

## 10. Pipeline: del commit al clúster — 1:00

Un cambio recorre cuatro pasos.

1. Cada push pasa validación de seguridad con Checkov, TruffleHog y kubeconform.
2. El despliegue requiere aprobación manual en el entorno de laboratorio.
3. Terraform se autentica en AWS mediante OIDC, sin claves fijas, y utiliza siempre un tag inmutable del framework, nunca la rama principal.
4. ArgoCD no recibe nada del pipeline; hace pull del repositorio y el clúster converge hacia el estado declarado en Git.

> **Si preguntan:** el framework publica versiones con release-please; el workflow se dispara al modificar un terraform.tfvars, detecta el entorno y, tras el apply, devuelve a Git los ARNs de IRSA. Existe además un workflow manual con doble confirmación para destruir el entorno.

## 11. ArgoCD: App of Apps y Sync Waves — 1:00

ArgoCD gestiona el ciclo de vida mediante el patrón App of Apps: una Application raíz sincroniza el resto de aplicaciones.

Las dependencias se resuelven con Sync Waves: primero la plataforma, después las bases de datos, luego el Trust Anchor, después Orion-LD y, finalmente, Kong.

ArgoCD no avanza de ola hasta que todo está Healthy. Con selfHeal y prune, corrige desviaciones respecto a Git.

Elegí Applications independientes en lugar de un Helm umbrella único para tener control, salud y trazabilidad por componente.

## 12. Autorización: Kong como PEP — 1:00

El acceso a los datos está protegido por Kong como Policy Enforcement Point.

El consumidor envía una petición con un token JWT. Kong verifica la firma y consulta la Trusted Issuers List para comprobar que el emisor está registrado. Solo entonces reenvía la petición a Orion-LD, que responde con datos NGSI-LD.

Validé cuatro casos: sin token, 401; firma inválida, 401; emisor no registrado, 403; y token válido, 200.

En el laboratorio se usa HS256 en modo sandbox. En producción se emplearían certificados eIDAS y un iSHARE Satellite.

## 13. Resultados: 10 KPIs — 1:30

Los resultados se agrupan en cuatro dimensiones.

- **Reproducibilidad:** el despliegue completo tarda unos 40 minutos. Es el único KPI que no cumple el umbral de 30 minutos; la causa principal es el aprovisionamiento de EKS, unos 17 minutos, no el proceso GitOps. Solo se requieren dos pasos manuales y el re-despliegue tras destrucción total funciona al cien por cien.
- **Resiliencia:** el RTO ante un fallo de nodo fue de 95 segundos y ArgoCD corrigió una desviación en 6,8 segundos.
- **Seguridad:** no hubo hallazgos críticos de Checkov ni secretos expuestos detectados por TruffleHog. Todas las peticiones sin JWT válido fueron rechazadas.
- **Conformidad:** el flujo de autorización devolvió los cuatro códigos esperados y la consulta NGSI-LD respondió correctamente.

En total, nueve de diez KPIs cumplen los umbrales definidos.

## 14. Evidencia en ejecución — 0:50

Estas son dos evidencias del sistema en ejecución.

A la izquierda, el panel de ArgoCD muestra las ocho aplicaciones gestionadas por la plataforma, que está operativa y en reconciliación continua.

A la derecha, el smoke test end-to-end valida el flujo completo: salud del Trust Anchor, obtención de token, acceso al proveedor a través de Kong y consulta NGSI-LD.

El resultado fue cinco comprobaciones correctas y ningún fallo.

## 15. Del laboratorio a producción — 1:15

Es importante contextualizar el alcance. Este TFM se validó en un laboratorio con restricciones de coste, por lo que algunas decisiones responden a ese contexto, no a una limitación del diseño.

En producción, los dos nodos SPOT pasarían a escalado dinámico con Karpenter o Cluster Autoscaler en tres zonas. Las aplicaciones pasarían de una réplica a múltiples réplicas con KEDA y PodDisruptionBudgets.

MongoDB pasaría de standalone a un replica set de tres miembros. La confianza usaría certificados eIDAS y un iSHARE Satellite. Y el clúster operaría 24/7.

Lo importante es que la arquitectura no cambia: se reutilizan el mismo framework Terraform y el mismo repositorio GitOps; solo cambian las variables del entorno.

## 16. Conclusiones y trabajo futuro — 1:00

La respuesta a la pregunta de investigación es sí: un Data Space FIWARE completo puede desplegarse y operarse solo desde Git.

El trabajo aporta un modelo de referencia que integra GitOps, FIWARE, infraestructura como código en AWS y los marcos de confianza iSHARE y DSBA.

También aporta un artefacto reproducible en repositorios públicos y un pipeline con seguridad integrada desde el primer commit.

Como trabajo futuro propongo federación multi-clúster con ApplicationSets, un conector basado en Eclipse Dataspace Connector, observabilidad con OpenTelemetry y pruebas de conformidad con el Data Governance Act.
