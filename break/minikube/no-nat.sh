#!/usr/bin/env bash
# SYMPTOM: / works. /s3 and /egress hang. New pods on fresh nodes can't pull images.
source "$(dirname "$0")/../_lib.sh"
require_env eks
case "${1:-}" in
  break) for rt in $(terraform -chdir="$ROOT/terraform/eks" output -json private_route_table_ids | jq -r '.[]'); do
           aws ec2 delete-route --region "$(eks_out region)" --route-table-id "$rt" --destination-cidr-block 0.0.0.0/0
         done
         say "Broken (someone 'cleaned up' in the console)." ;;
  fix)   say "Read the plan before approving - it shows exactly what drifted."
         terraform -chdir="$ROOT/terraform/eks" apply ;;
  *)     usage ;;
esac