#!/usr/bin/env bash
# SYMPTOM: After a "small tuning change", new pods keep restarting.
source "$(dirname "$0")/../_lib.sh"
case "${1:-}" in
  break) kubectl -n $NS set resources deployment/app -c app --requests=memory=40Mi --limits=memory=40Mi
         say "Broken. Watch: kubectl --context $KCTX -n app get pods -w" ;;
  fix)   redeploy ;;
  *)     usage ;;
esac