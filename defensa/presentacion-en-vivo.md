# Presentación en vivo — enlaces y comandos

Uso local. No se versiona.

## Antes de empezar (07:30 CET)

```bash
export KUBECONFIG=~/.kube/config-tfm
kubectl get nodes                                   # 2 Ready
kubectl get applications -n argocd                  # 8 Synced / Healthy
bash ~/Documents/Personal/Repositorios/github/TFM/tfm-fiware-gitops/tests/smoke-test.sh   # 9 OK / 0 FAIL (registra el emisor en la TIL)
kubectl port-forward -n argocd svc/argocd-server 8443:443   # dejar abierto en otra terminal
```

El smoke-test va **antes** que la demo: si la TIL se reinició, vuelve a registrar el emisor y el caso 4 da 200 en vez de 403.

Pantalla: terminal con fuente grande (Ctrl + +), navegador en modo claro, cerrar pestañas con datos personales. Tener a mano el vídeo de respaldo.

## Pestañas del navegador (en este orden)

| # | Qué enseñar | URL |
|---|---|---|
| 1 | ArgoCD — 8 aplicaciones en verde | https://localhost:8443/applications |
| 2 | ArgoCD — árbol App of Apps | https://localhost:8443/applications/argocd/fiware-data-space |
| 3 | ArgoCD — Kong (PEP) | https://localhost:8443/applications/argocd/fiware-kong |
| 4 | Repo GitOps | https://github.com/jdmonsalvel/tfm-fiware-gitops |
| 5 | Config de Kong (PEP + consulta a la TIL) | https://github.com/jdmonsalvel/tfm-fiware-gitops/blob/main/gitops/apps/fiware/kong.yaml |
| 6 | tfvars del entorno (qué y dónde se despliega) | https://github.com/jdmonsalvel/tfm-fiware-gitops/blob/main/infra/environments/dev/terraform.tfvars |
| 7 | Applications con sync waves | https://github.com/jdmonsalvel/tfm-fiware-gitops/tree/main/gitops/apps/fiware |
| 8 | GitHub Actions (workflows) | https://github.com/jdmonsalvel/tfm-fiware-gitops/actions |
| 9 | Infra Deploy en verde (OIDC + aprobación) | https://github.com/jdmonsalvel/tfm-fiware-gitops/actions/runs/41253917397 |
| 10 | Security Scan en verde (TruffleHog + Checkov) | https://github.com/jdmonsalvel/tfm-fiware-gitops/actions/runs/41253917431 |
| 11 | GitOps Validate en verde (Helm lint + kubeconform) | https://github.com/jdmonsalvel/tfm-fiware-gitops/actions/runs/41253418935 |
| 12 | Framework Terraform | https://github.com/jdmonsalvel/tfm-terraform-framework |
| 13 | Tags del framework (v1.0.19) | https://github.com/jdmonsalvel/tfm-terraform-framework/tags |
| 14 | Terraform Validate en verde | https://github.com/jdmonsalvel/tfm-terraform-framework/actions/runs/41253702145 |
| 15 | Keyrock (login del IdP) | https://keyrock.lab-jdmonsalvel.com |
| 16 | Orion sin token → 401 | https://orion.lab-jdmonsalvel.com/version |
| 17 | TIL — emisores de confianza | https://til.lab-jdmonsalvel.com/issuer |
| 18 | Diagrama CI/CD | https://claude.ai/artifact/DEmg3WeYUr88JpQxV867sN |

Contraseña de ArgoCD (usuario `admin`), al portapapeles:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d | wl-copy
```

**No abrir** el workflow *Release* del framework: siempre ha fallado porque el repo no permite que Actions cree PRs (release-please). Los tags se crearon a mano. Si preguntan: "release-please necesita el permiso *Allow GitHub Actions to create pull requests*; está desactivado y los tags se publican manualmente".

## Demo en terminal (~2 min)

```bash
cd ~/Documents/Personal/Repositorios/github/TFM/tfm-fiware-docs
bash defensa/demo.sh               # 401 / 401 / 403 / 200 + TIL + smoke-test (Enter entre pasos)
bash defensa/demo.sh --sin-smoke   # versión corta
```

## Demos opcionales si el tribunal lo pide

**Self-heal de ArgoCD (RS-2, ~10 s).** Con la pestaña 1 abierta:

```bash
kubectl scale deploy fiware-orion -n provider --replicas=0
kubectl get deploy fiware-orion -n provider -w      # vuelve a 1/1 en segundos
```

**Pods y nodos (2 AZ):**

```bash
kubectl get pods -A -o wide | grep -E 'trust-anchor|provider'
kubectl get nodes -L topology.kubernetes.io/zone
```

**Secretos sincronizados desde Secrets Manager:**

```bash
kubectl get externalsecret -A
kubectl get certificate -A
```

No hacer `kubectl drain` en directo: la TIL tarda ~95 s en volver y pierde el emisor (H2 en memoria).

## Si algo falla

| Síntoma | Causa probable | Acción |
|---|---|---|
| Caso 4 da 403 | La TIL se reinició y perdió el emisor | Ejecutar el smoke-test y repetir |
| 503 "Trusted Issuers List unavailable" | La TIL está arrancando | Esperar ~1 min |
| `localhost:8443` no carga | Se cayó el port-forward | Relanzar el `kubectl port-forward` |
| Nada responde | Nodos SPOT reclamados o entorno caído | Pasar al vídeo de respaldo y a las capturas |
