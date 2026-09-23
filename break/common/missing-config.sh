#!/usr/bin/env bash
# SYMPTOM: The site is still up, but the new deployment never finishes rolling out.
source "$(dirname "$0")/../_lib.sh"
case "${1:-}" in
  break) kubectl -n $NS delete configmap app-config
         kubectl -n $NS rollout restart deployment/app
         say "Broken. Try: kubectl --context $KCTX -n app rollout status deployment/app" ;;
  fix)   redeploy ;;
  *)     usage ;;
esac