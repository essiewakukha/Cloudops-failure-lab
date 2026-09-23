#!/usr/bin/env bash
# Hits each endpoint every 2s. Each one tests a different layer:
#   /       app            /k8s     K8s API + RBAC
#   /egress DNS + network   /s3      AWS IAM + S3 (EKS only)
# 000 = timeout / connection failed.
DIR="$(cd "$(dirname "$0")" && pwd)"
BASE=$("$DIR/url.sh") || exit 1
PATHS="/ /k8s /egress"
[ "${ENV:-minikube}" = eks ] && PATHS="$PATHS /s3"
echo "Probing $BASE  [$PATHS]  (Ctrl-C to stop)"
while true; do
  line="$(date +%H:%M:%S)"
  for p in $PATHS; do
    code=$(curl -s -o /dev/null -m 8 -w '%{http_code}' "$BASE$p")
    line="$line   $p=$code"
  done
  echo "$line"
  sleep 2
done