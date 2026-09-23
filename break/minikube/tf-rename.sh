#!/usr/bin/env bash
# SYMPTOM: A harmless "rename for clarity" PR. terraform plan wants to DESTROY something.
# DO NOT run terraform apply while this is broken.
source "$(dirname "$0")/../_lib.sh"
TFDIR="$ROOT/terraform/core"
case "${1:-}" in
  break) perl -pi -e 's/aws_s3_bucket\.data\b/aws_s3_bucket.artifacts/g; s/"aws_s3_bucket" "data"/"aws_s3_bucket" "artifacts"/' "$TFDIR"/*.tf
         terraform -chdir="$TFDIR" plan || true
         say "Read the plan. What happens to the bucket's data?" ;;
  fix)   cat > "$TFDIR/moved.tf" <<'TF'
moved {
  from = aws_s3_bucket.data
  to   = aws_s3_bucket.artifacts
}
TF
         terraform -chdir="$TFDIR" plan
         say "Plan should show the move and 0 to destroy." ;;
  reset) rm -f "$TFDIR/moved.tf"
         perl -pi -e 's/aws_s3_bucket\.artifacts\b/aws_s3_bucket.data/g; s/"aws_s3_bucket" "artifacts"/"aws_s3_bucket" "data"/' "$TFDIR"/*.tf
         say "Code restored to original names (state was never changed)." ;;
  *)     echo "usage: $0 break|fix|reset"; exit 1 ;;
esac