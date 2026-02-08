# ---------- Builder: construeix la documentació ----------
FROM python:3.11-slim AS builder

# Evitar preguntes d'APT
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1

# Paquets del sistema necessaris (graphviz, etc.)
WORKDIR /work
COPY apt-packages.txt /tmp/apt-packages.txt
RUN apt-get update \
 && xargs -r apt-get install -y < /tmp/apt-packages.txt \
 && rm -rf /var/lib/apt/lists/*

# Dependències Python
COPY requirements.txt /work/requirements.txt
RUN python -m pip install --upgrade pip \
 && pip install -r requirements.txt

# Còpia del projecte (només el necessari per a Sphinx)
COPY docs /work/docs

# Construeix HTML (de docs → /site)
RUN sphinx-build -b html /work/docs /site

# ---------- Runtime: Nginx servint /site ----------
FROM nginx:alpine AS runtime
COPY --from=builder /site /usr/share/nginx/html
# (Opcional) Config Nginx extra:
# COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
