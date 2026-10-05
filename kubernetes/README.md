# Kubernetes

Das Cluster wird per **GitOps (Flux)** aus dem Repository `philiplorenz-code/3kshetzner` verwaltet.
Dort liegt die maßgebliche Definition (`apps/powershell-kurs/`). Diese Kopie dient nur der Lesbarkeit
und dem Nachvollziehen. **Bitte nicht per `kubectl apply` ausrollen.**

| Ressource | Wert |
|---|---|
| Namespace | `powershell-kurs` |
| Host | `powershell-kurs.philiplorenz.com` (TLS: cert-manager `letsencrypt-prod`, DNS: external-dns/Cloudflare) |
| Image | `ghcr.io/philiplorenz-code/powershell-kurs:sha-<commit>` (gebaut von GitHub Actions) |
| Ingress | Traefik |
| Health | `GET /healthz` |

## Neue Version ausrollen

1. Änderungen nach `main` mergen. Die GitHub Action baut und pusht das Image mit dem Tag `sha-<7 Zeichen>`.
2. In `3kshetzner` die Zeile `image:` in `apps/powershell-kurs/02-deployment.yaml` auf den neuen Tag setzen und per PR mergen.
3. Flux rollt aus (`kubectl -n powershell-kurs rollout status deploy/powershell-kurs`).
