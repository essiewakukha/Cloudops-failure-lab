#!/usr/bin/env bash
# SYMPTOM: Users get 503 Service Unavailable. Pods are Running and Ready.
source "$(dirname "$0")/../_lib.sh"
case "${1:-}" in
  break) kubectl -n $NS patch svc app -p '{"spec":{"selector":{"app":"app-v2"}}}'
         say "Broken. Compare with 01: why 503 here and 502 there?" ;;
  fix)   redeploy ;;
  *)     usage ;;
esac