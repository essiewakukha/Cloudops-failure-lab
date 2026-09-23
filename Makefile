# Usage: make <target> [ENV=minikube|eks] [TAG=v1]
ENV  ?= minikube
TAG  ?= v1
CORE := terraform -chdir=terraform/core
EKS  := terraform -chdir=terraform/eks

ifeq ($(ENV),eks)
  KCTX         := break-fix-lab-eks
  REGION        = $(shell $(CORE) output -raw region)
  REPO_URL      = $(shell $(CORE) output -raw ecr_repository_url)
  IMAGE         = $(REPO_URL):$(TAG)
  APP_ROLE_ARN  = $(shell $(EKS) output -raw app_role_arn)
  BUCKET_NAME   = $(shell $(CORE) output -raw bucket_name)
else
  KCTX         := minikube
  IMAGE         = break-fix-lab:$(TAG)
endif

KUBECTL := kubectl --context $(KCTX)
export ENV KCTX TAG

.PHONY: help minikube-up minikube-down core-up core-destroy eks-up eks-destroy \
        build deploy url probe status break fix leftovers

help:
	@grep -E '^[a-z-]+:.*## ' Makefile | awk -F':.*## ' '{printf "  %-15s %s\n", $$1, $$2}'

# ---------- infrastructure ----------
minikube-up:     ## Local cluster: Calico CNI, ingress-nginx, metrics-server
	./scripts/minikube-up.sh

minikube-down:   ## Delete the local cluster
	minikube delete

core-up:         ## S3, ECR, GitHub OIDC (cheap, leave running)
	$(CORE) init
	$(CORE) apply

core-destroy:    ## Remove core stack (destroy EKS first if it exists)
	$(CORE) destroy

eks-up:          ## EKS session: VPC, cluster, ALB controller (~20 min, ~$0.40/hr)
	$(EKS) init
	$(EKS) apply
	aws eks update-kubeconfig --region $$($(EKS) output -raw region) \
	  --name $$($(EKS) output -raw cluster_name) --alias break-fix-lab-eks

eks-destroy:     ## End EKS session: delete Ingress/ALB first, then cluster
	-kubectl --context break-fix-lab-eks delete namespace app --wait=true --timeout=300s
	$(EKS) destroy
	./scripts/leftovers.sh $$($(CORE) output -raw region)

# ---------- app ----------
build:           ## Build the image for the current ENV
ifeq ($(ENV),eks)
	aws ecr get-login-password --region $(REGION) | docker login --username AWS --password-stdin $(firstword $(subst /, ,$(REPO_URL)))
	docker buildx build --platform linux/amd64 -t $(IMAGE) --push app
else
	minikube image build -t $(IMAGE) app
endif

deploy:          ## Render overlay, apply, restart, wait
	kubectl kustomize k8s/overlays/$(ENV) \
	| IMAGE=$(IMAGE) APP_ROLE_ARN=$(APP_ROLE_ARN) BUCKET_NAME=$(BUCKET_NAME) AWS_REGION=$(REGION) \
	  envsubst '$${IMAGE} $${APP_ROLE_ARN} $${BUCKET_NAME} $${AWS_REGION}' \
	| $(KUBECTL) apply -f -
	$(KUBECTL) -n app rollout restart deployment/app
	$(KUBECTL) -n app rollout status deployment/app --timeout=300s

url:             ## Print the app URL
	@./scripts/url.sh

probe:           ## Live status of every endpoint (run in a second terminal)
	./scripts/probe.sh

status:          ## Quick overview of the app namespace
	$(KUBECTL) -n app get pods,svc,endpoints,ingress,hpa

# ---------- scenarios ----------
break:           ## make break S=common/01-bad-gateway
	./break/$(S).sh break

fix:             ## make fix S=common/01-bad-gateway
	./break/$(S).sh fix

leftovers:       ## Anything on AWS still costing money?
	./scripts/leftovers.sh $$($(CORE) output -raw region)