#!/usr/bin/env bash
# SYMPTOM: "It worked yesterday." Today a routine restart leaves new pods stuck.
source "$(dirname "$0")/../_lib.sh"
IMG=$(kubectl -n $NS get deployment app -o jsonpath='{.spec.template.spec.containers[0].image}')
TAG=${IMG##*:}
case "${1:-}" in
  break)
    if [ "$ENV" = eks ]; then
      aws ecr batch-delete-image --region "$(core_out region)" \
        --repository-name "$(core_out ecr_repository_name)" --image-ids imageTag="$TAG"
      kubectl -n $NS rollout restart deployment/app
    else
      # Locally: a deploy references a tag the build never produced.
      kubectl -n $NS set image deployment/app app="${IMG%:*}:${TAG}-hotfix"
    fi
    say "Broken. Which pods still serve traffic, and which don't?" ;;
  fix)
    if [ "$ENV" = eks ]; then make -C "$ROOT" build ENV=eks TAG="$TAG"; fi
    redeploy ;;
  *) usage ;;
esac