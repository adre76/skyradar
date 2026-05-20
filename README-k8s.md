# ✈ SkyRadar — Deploy Kubernetes

## Estrutura

```
skyradar/
├── app.py                  ← aplicação Flask (com ProxyFix para sub-path)
├── requirements.txt        ← flask + requests + gunicorn (pinados)
├── Dockerfile              ← multi-stage, python:3.12-alpine (~80 MB final)
├── .dockerignore
├── Makefile                ← atalhos de build/deploy
└── k8s/
    ├── 00-namespace.yaml   ← Namespace isolado
    ├── 01-deployment.yaml  ← Deployment (1 réplica, limites mínimos)
    ├── 02-service.yaml     ← Service ClusterIP
    ├── 03-ingress.yaml     ← Ingress nginx → andrepereira.tec.br/radar
    └── 04-hpa.yaml         ← HPA 1–3 réplicas por CPU
```

---

## Pré-requisitos no cluster

| Componente | Finalidade |
|---|---|
| **nginx Ingress Controller** | rotear tráfego externo |
| **cert-manager** + ClusterIssuer `letsencrypt-prod` | TLS automático |
| Registry acessível | armazenar a imagem Docker |

---

## Deploy passo a passo

### 1. Build e push da imagem

```bash
# Ajuste o nome da imagem no Makefile ou passe como variável
make release IMAGE=seu-registry/skyradar TAG=1.0.0
```

> Se usar registry privado, lembre de criar o `imagePullSecret` e referenciar em `01-deployment.yaml`.

### 2. Ajustar o nome da imagem

Edite `k8s/01-deployment.yaml`, linha `image:`:

```yaml
image: seu-registry/skyradar:1.0.0
```

### 3. Aplicar os manifests

```bash
make deploy
```

Ou manualmente:

```bash
kubectl apply -f k8s/
```

### 4. Verificar status

```bash
make status
# ou
kubectl get all -n skyradar
kubectl get ingress -n skyradar
```

### 5. Acompanhar logs

```bash
make logs
```

---

## URL final

```
https://andrepereira.tec.br/radar
```

O cert-manager emitirá o certificado TLS automaticamente na primeira requisição.  
Enquanto o certificado não estiver pronto, o acesso será via HTTP.

---

## Como o roteamento de sub-path funciona

```
Browser → andrepereira.tec.br/radar/*
            │
            ▼ nginx-ingress (rewrite-target: /$2)
            │  /radar/api/aircraft → /api/aircraft
            │  /radar/             → /
            │
            ▼ Service ClusterIP :80
            │
            ▼ Gunicorn :8000
            │
            ▼ Flask (ProxyFix lê X-Forwarded-Prefix=/radar)
```

O `ProxyFix` no `app.py` garante que `url_for()` e redirects internos  
do Flask gerem URLs corretas com o prefixo `/radar`.

---

## Resource footprint

| Recurso | Request | Limit |
|---|---|---|
| CPU | 50m | 200m |
| Memória | 64 Mi | 128 Mi |

Imagem final: **~80 MB** (python:3.12-alpine multi-stage).

---

## Atualizar a aplicação

```bash
# 1. Suba a nova imagem com nova tag
make release TAG=1.0.1

# 2. Atualize a tag no deployment
kubectl set image deployment/skyradar skyradar=andrepereira/skyradar:1.0.1 -n skyradar

# 3. Acompanhe o rollout (zero-downtime)
kubectl rollout status deployment/skyradar -n skyradar
```
