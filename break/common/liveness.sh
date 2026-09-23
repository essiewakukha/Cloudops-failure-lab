#!/usr/bin/env bash
# SYMPTOM: Pods become Ready, serve traffic for a bit, then restart. Over and over.
source "$(dirname "$0")/../_lib.sh"
case "${1:-}" in
  break) kubectl -n $NS patch deployment app --type=json \
           -p '[{"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe/httpGet/path","value":"/health"}]'
         say "Broken. Watch the RESTARTS column." ;;
  fix)   redeploy ;;
  *)     usage ;;
esac