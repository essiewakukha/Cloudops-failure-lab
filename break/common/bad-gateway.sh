#!/usr/bin/env bash
# SYMPTOM: Users get 502 Bad Gateway. Pods look healthy.
source "$(dirname "$0")/../_lib.sh"
case "${1:-}" in
  break) kubectl -n $NS patch svc app --type=json \
           -p '[{"op":"replace","path":"/spec/ports/0/targetPort","value":9090}]'
         say "Broken. Give it ~30s, then investigate." ;;
  fix)   redeploy ;;
  *)     usage ;;
esac