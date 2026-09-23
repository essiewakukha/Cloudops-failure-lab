#!/usr/bin/env bash
# SYMPTOM: / works, but /s3 returns 500 AccessDenied. Nobody touched IAM.
source "$(dirname "$0")/../_lib.sh"
require_env eks
case "${1:-}" in
  break) kubectl -n $NS annotate serviceaccount app eks.amazonaws.com/role-arn-
         kubectl -n $NS rollout restart deployment/app
         kubectl -n $NS rollout status deployment/app --timeout=180s
         say "Broken. Hit /s3 and read the ARN in the error." ;;
  fix)   redeploy ;;
  *)     usage ;;
esac