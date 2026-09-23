# Shared helpers for scenario scripts. Sourced, not executed.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV=${ENV:-minikube}
if [ "$ENV" = eks ]; then KCTX=${KCTX:-break-fix-lab-eks}; else KCTX=${KCTX:-minikube}; fi
export ENV KCTX
NS=app

# Always target the right cluster, never whatever your current context happens to be.
kubectl() { command kubectl --context "$KCTX" "$@"; }

core_out() { terraform -chdir="$ROOT/terraform/core" output -raw "$1"; }
eks_out()  { terraform -chdir="$ROOT/terraform/eks"  output -raw "$1"; }
redeploy() { make -C "$ROOT" deploy ENV="$ENV"; }
require_env() { [ "$ENV" = "$1" ] || { echo "This scenario needs ENV=$1 (current: $ENV)"; exit 1; }; }
usage() { echo "usage: $0 break|fix"; exit 1; }
say() { printf '\n>>> %s\n\n' "$*"; }

echo "[target: $ENV | context: $KCTX]"