#!/usr/bin/env bash
# Calico is required: the default minikube CNI ignores NetworkPolicies (scenario 10).
set -euo pipefail
minikube start --cpus="${CPUS:-4}" --memory="${MEMORY:-4g}" --cni=calico
minikube addons enable ingress
minikube addons enable metrics-server
echo "Waiting for ingress-nginx..."
kubectl --context minikube -n ingress-nginx wait --for=condition=ready pod \
  -l app.kubernetes.io/component=controller --timeout=300s
cat <<MSG

minikube is ready.
  Linux:         make url  (uses minikube ip)
  macOS/Windows: run 'minikube tunnel' in another terminal, then export BASE_URL=http://127.0.0.1
MSG