#!/usr/bin/env bash
# SYMPTOM: Latency spikes, some requests time out, maybe restarts. "Is it the network?"
source "$(dirname "$0")/../_lib.sh"
case "${1:-}" in
  break) kubectl -n $NS run loadgen --image=curlimages/curl --restart=Never --command -- \
           sh -c 'while true; do for i in 1 2 3 4 5 6 7 8; do curl -s -m 30 "http://app/burn?seconds=5" >/dev/null & done; wait; done'
         say "Load running. Try: kubectl top pods -n app ; kubectl get hpa -n app -w" ;;
  fix)   kubectl -n $NS delete pod loadgen --ignore-not-found
         say "Load stopped. HPA scales down after ~5 min." ;;
  *)     usage ;;
esac