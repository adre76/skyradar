# ── Stage 1: builder ──────────────────────────────────────────────────────────
# Instala dependências em ambiente isolado para não vazar build-tools na imagem final
FROM python:3.12-alpine AS builder

WORKDIR /install

# Copia só o requirements para aproveitar cache de layer
COPY requirements.txt .

# Instala no diretório /install/deps (sem compilar nada — tudo pure-python)
RUN pip install --no-cache-dir --prefix=/install/deps -r requirements.txt


# ── Stage 2: runtime ──────────────────────────────────────────────────────────
# python:3.12-alpine ~50 MB vs python:3.12-slim ~130 MB
FROM python:3.12-alpine AS runtime

# Usuário não-root (boa prática de segurança)
RUN addgroup -S skyradar && adduser -S skyradar -G skyradar

WORKDIR /app

# Copia dependências já instaladas do builder
COPY --from=builder /install/deps /usr/local

# Copia código da aplicação
COPY app.py .
COPY templates/ templates/

# Muda dono para o usuário não-root
RUN chown -R skyradar:skyradar /app

USER skyradar

# Gunicorn: servidor WSGI de produção (já incluso via requirements)
# 2 workers síncronos — suficiente para o tráfego esperado
EXPOSE 8000
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "--timeout", "30", "app:app"]
