#!/bin/bash
set -e

# VARIABLES
PROJECT_DIR=~/odoo_server
ODOO_PORT=8069
ODOO_DB_NAME=falla
ODOO_DB_USER=admin
ODOO_DB_PASS='Pa$$w0rd'
ODOO_MASTER_PASS='Pa$$w0rd'
ODOO_PG_PORT=5432
ADDONS_DIR=$PROJECT_DIR/dev_addons

# FLAGS
PHASE1_FLAG="$PROJECT_DIR/.phase1_docker_done"
PHASE2_FLAG="$PROJECT_DIR/.phase2_odoo_started"
INSTALLED_MODULES_FILE="$PROJECT_DIR/.installed_modules"

# MÒDULS
DEFAULT_MODULES=(web portal contacts sale account event website website_event website_event_sale payment point_of_sale pos_sale pos_hr pos_restaurant crm l10n_es)
CUSTOM_MODULES=(saldo_favor familia event_family_registration payment_with_saldo importador_usuaris_portal productes_esdeveniment)

# FASE 1: Docker i dependències
if [ ! -f "$PHASE1_FLAG" ]; then
    echo "🔧 [FASE 1] Instal·lant Docker i dependències..."
    sudo apt -y remove docker docker-engine docker.io containerd runc || true
    sudo apt update
    sudo apt install -y ca-certificates curl gnupg lsb-release python3 python3-pip

    if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
    fi

    if ! grep -q docker /etc/apt/sources.list.d/docker.list 2>/dev/null; then
        echo "🗂️ Afegint repositori oficial de Docker..."
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    fi

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable --now docker

    if ! groups $USER | grep -q docker; then
        echo "➕ Afegint $USER al grup docker..."
        sudo usermod -aG docker $USER
    fi

    echo "✅ Docker instal·lat correctament."
    echo "🔁 Reinicia la màquina perquè s'apliquen els permisos."
    mkdir -p "$PROJECT_DIR"
    touch "$PHASE1_FLAG"
    exit 0
fi

# FASE 2: Estructura i arrencada d’Odoo
if [ ! -f "$PHASE2_FLAG" ]; then
    echo "📂 [FASE 2] Creant estructura de carpetes i fitxers..."
    mkdir -p "$PROJECT_DIR"/{config_odoo,dev_addons,log}
    cd "$PROJECT_DIR"

    cat > config_odoo/odoo.conf <<EOF
[options]
addons_path = /mnt/extra-addons
data_dir = /var/lib/odoo
proxy_mode = True
db_host = db
db_port = $ODOO_PG_PORT
db_user = odoo
db_password = myodoo
xmlrpc_interface = 0.0.0.0
xmlrpc_port = $ODOO_PORT
admin_passwd = $ODOO_MASTER_PASS
logfile = /var/log/odoo/odoo.log
log_level = info
EOF

    cat > Dockerfile <<'EOF'
FROM odoo:16.0
USER root
RUN pip uninstall jinja2 markupsafe -y && \
    pip install jinja2==3.1.2 markupsafe==2.1.1 requests pandas && \
    mkdir -p /var/log/odoo && \
    chown -R odoo:odoo /var/log/odoo
COPY ./dev_addons/* /mnt/extra-addons/
USER odoo
WORKDIR /mnt/extra-addons
EOF

    cat > docker-compose.yml <<EOF
services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
    depends_on:
      - db
    ports:
      - "$ODOO_PORT:$ODOO_PORT"
    volumes:
      - odoo-web-data:/var/lib/odoo
      - ./config_odoo:/etc/odoo
      - ./dev_addons:/mnt/extra-addons
      - ./log:/var/log/odoo
      - /var/www/certbot:/var/www/certbot
    environment:
      - HOST=db
      - USER=odoo
      - PASSWORD=myodoo
      - TZ=Europe/Madrid
    restart: always
    command: odoo -c /etc/odoo/odoo.conf --dev=all --log-level=info
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  db:
    image: postgres:latest
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_PASSWORD=myodoo
      - POSTGRES_USER=odoo
      - PGDATA=/var/lib/postgresql/data/pgdata
    volumes:
      - odoo-db-data:/var/lib/postgresql/data/pgdata
    restart: always

volumes:
  odoo-web-data:
  odoo-db-data:
EOF

    echo "⬇️ Clonant mòduls..."
    cd "$ADDONS_DIR"
    for repo in "${CUSTOM_MODULES[@]}"; do
        if [ ! -d "$repo" ]; then
            git clone https://github.com/juatafe/$repo.git
        fi
    done

    cd "$PROJECT_DIR"
    docker compose build
    docker compose up -d

    echo "⌛ Esperant que PostgreSQL estiga disponible..."
    until docker exec odoo_server-db-1 pg_isready -U odoo > /dev/null 2>&1; do
      sleep 2
    done
    echo "✅ PostgreSQL disponible!"

    echo "🛠️ Creant base de dades..."
    docker compose exec web odoo -d "$ODOO_DB_NAME" -i base --without-demo=all --load-language=ca --stop-after-init

    echo "🔐 Establint contrasenya de l'usuari admin..."
    docker compose exec -T web python3 <<EOF
import odoo
from odoo import api, SUPERUSER_ID
odoo.tools.config['db_name'] = '$ODOO_DB_NAME'
with odoo.api.Environment.manage():
    with odoo.sql_db.db_connect('$ODOO_DB_NAME').cursor() as cr:
        env = api.Environment(cr, SUPERUSER_ID, {})
        admin = env['res.users'].search([('login', '=', 'admin')], limit=1)
        if admin:
            admin.write({'password': '$ODOO_DB_PASS'})
            print("✅ Contrasenya establerta correctament")
EOF

    touch "$PHASE2_FLAG"
    exit 0
fi

# FASE 3: Instal·lació de mòduls
mkdir -p "$PROJECT_DIR/.logs"
if [ ! -f "$INSTALLED_MODULES_FILE" ]; then
    echo "🔍 Detectant mòduls ja instal·lats en la base de dades..."
    docker compose exec web odoo shell -d "$ODOO_DB_NAME" --no-http --no-xmlrpc --no-netrpc <<EOF > "$INSTALLED_MODULES_FILE"
installed = env['ir.module.module'].search([('state','=','installed')])
for m in installed:
    print(m.name)
EOF
fi


echo "📦 [FASE 3] Instal·lant mòduls d’Odoo..."
cd "$PROJECT_DIR"

for modul in "${DEFAULT_MODULES[@]}" "${CUSTOM_MODULES[@]}"; do
    if grep -Fxq "$modul" "$INSTALLED_MODULES_FILE"; then
        echo "⏭️ Ja instal·lat: $modul"
        continue
    fi
    echo "🔹 Instal·lant: $modul..."
    if docker compose exec web odoo -i "$modul" -d "$ODOO_DB_NAME" --without-demo=all --stop-after-init; then
        echo "$modul" >> "$INSTALLED_MODULES_FILE"
    else
        echo "❌ ERROR instal·lant $modul. Pots tornar a executar l’script."
        exit 1
    fi
done

echo "🔄 Recompilant assets web..."
docker compose exec web odoo -d "$ODOO_DB_NAME" -i web_asset --stop-after-init

echo "✅ Mòduls instal·lats correctament!"
docker compose restart web
exit 0
