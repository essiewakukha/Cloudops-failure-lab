#!/usr/bin/env bash
# SYMPTOM: After a "security hardening" PR, /egress times out. DNS still resolves.
source "$(dirname "$0")/../_lib.sh"
require_env minikube
if ! kubectl -n kube-system get pods -l k8s-app=calico-node --no-headers 2>/dev/null | grep -q Running; then
  echo "Calico not running - NetworkPolicies won't be enforced. Recreate with scripts/minikube-up.sh"; exit 1
fi
case "${1:-}" in
  break) kubectl apply -f - <<'YAML'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
  namespace: app
spec:
  podSelector: {}
  policyTypes: [Egress]
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - { protocol: UDP, port: 53 }
        - { protocol: TCP, port: 53 }
YAML
         say "Broken. Compare the /egress error with scenario 09's." ;;
  fix)   kubectl -n $NS delete networkpolicy default-deny-egress --ignore-not-found ;;
  *)     usage ;;
esac