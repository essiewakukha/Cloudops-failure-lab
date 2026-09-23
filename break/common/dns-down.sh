#!/usr/bin/env bash
# SYMPTOM: / and /k8s work. /egress (and /s3 on EKS) fail. Nothing changed in the app namespace.
source "$(dirname "$0")/../_lib.sh"
case "${1:-}" in
  break) kubectl -n kube-system get deployment coredns -o jsonpath='{.spec.replicas}' > /tmp/bfl-coredns-replicas
         kubectl -n kube-system scale deployment coredns --replicas=0
         say "Broken (in a namespace you weren't looking at)." ;;
  fix)   kubectl -n kube-system scale deployment coredns --replicas="$(cat /tmp/bfl-coredns-replicas 2>/dev/null || echo 2)"
         kubectl -n kube-system rollout status deployment coredns --timeout=120s ;;
  *)     usage ;;
esac