#!/usr/bin/env bash
# Prints the base URL of the app for the current ENV.
set -euo pipefail
ENV=${ENV:-minikube}
if [ "$ENV" = eks ]; then
  host=$(kubectl --context "${KCTX:-break-fix-lab-eks}" -n app get ingress app \
         -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
  [ -z "$host" ] && { echo "No ALB hostname yet (takes 2-3 min after deploy)." >&2; exit 1; }
  echo "http://$host"
elif [ -n "${BASE_URL:-}" ]; then
  echo "$BASE_URL"
else
  echo "http://$(minikube ip)"
fi