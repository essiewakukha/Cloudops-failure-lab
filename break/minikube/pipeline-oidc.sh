#!/usr/bin/env bash
# SYMPTOM: The pipeline worked on the last push. Now it fails before building anything.
# Requires github_repo in terraform/core/terraform.tfvars and the AWS_ROLE_ARN repo secret.
source "$(dirname "$0")/../_lib.sh"
ROLE=$(core_out github_actions_role_name)
[ -z "$ROLE" ] && { echo "Pipeline not enabled (github_repo is empty)."; exit 1; }
case "${1:-}" in
  break) DOC=$(aws iam get-role --role-name "$ROLE" --query Role.AssumeRolePolicyDocument --output json \
           | jq '.Statement[0].Condition.StringLike["token.actions.githubusercontent.com:sub"] |=
                 (if type=="array" then map(sub("refs/heads/main";"refs/heads/release"))
                  else sub("refs/heads/main";"refs/heads/release") end)')
         aws iam update-assume-role-policy --role-name "$ROLE" --policy-document "$DOC"
         say "Broken. Re-run the workflow and read the failing step." ;;
  fix)   say "Read the plan: this is drift."
         terraform -chdir="$ROOT/terraform/core" apply ;;
  *)     usage ;;
esac