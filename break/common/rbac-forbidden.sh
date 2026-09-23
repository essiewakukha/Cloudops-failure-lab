#!/usr/bin/env bash
# SYMPTOM: / works, but /k8s returns 500. Nothing was deployed.
source "$(dirname "$0")/../_lib.sh"
case "${1:-}" in
  break) kubectl -n $NS delete rolebinding app-read-config
         say "Broken (a 'permissions cleanup'). Hit /k8s and read the error." ;;
  fix)   redeploy ;;
  *)     usage ;;
esac