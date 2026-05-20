IMAGE   ?= andrepereira/skyradar
TAG     ?= latest
FULL    := $(IMAGE):$(TAG)

# ── Build & Push ─────────────────────────────────────────────────────────────
.PHONY: build push release

build:
	docker build -t $(FULL) .

push:
	docker push $(FULL)

release: build push   ## build + push em um comando

# ── Kubernetes ───────────────────────────────────────────────────────────────
.PHONY: deploy undeploy restart logs status

deploy:             ## aplica todos os manifests em ordem
	kubectl apply -f k8s/00-namespace.yaml
	kubectl apply -f k8s/01-deployment.yaml
	kubectl apply -f k8s/02-service.yaml
	kubectl apply -f k8s/03-ingress.yaml
	kubectl apply -f k8s/04-hpa.yaml

undeploy:           ## remove tudo (mantém o namespace para preservar o TLS Secret)
	kubectl delete -f k8s/04-hpa.yaml       --ignore-not-found
	kubectl delete -f k8s/03-ingress.yaml   --ignore-not-found
	kubectl delete -f k8s/02-service.yaml   --ignore-not-found
	kubectl delete -f k8s/01-deployment.yaml --ignore-not-found

restart:            ## rollout sem downtime
	kubectl rollout restart deployment/skyradar -n skyradar

logs:               ## segue logs do pod em execução
	kubectl logs -n skyradar -l app=skyradar -f --tail=100

status:             ## visão geral rápida
	@echo "=== Pods ==="
	kubectl get pods -n skyradar
	@echo "\n=== Service ==="
	kubectl get svc  -n skyradar
	@echo "\n=== Ingress ==="
	kubectl get ingress -n skyradar
	@echo "\n=== HPA ==="
	kubectl get hpa -n skyradar
