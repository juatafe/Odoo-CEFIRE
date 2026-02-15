#!/bin/bash
set -e

# VARIABLES
PROJECT_DIR=~/odoo_server
ODOO_PORT=8069
ODOO_DB_NAME=cpa
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
CUSTOM_REPO="odoo-cpa-addons"  # Repositori únic amb tots els mòduls personalitzats

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
      - mailhog
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
    volumes:
      - odoo-db-data:/var/lib/postgresql/data
    restart: always

  mailhog:
    image: mailhog/mailhog:latest
    container_name: mailhog
    ports:
      - "8025:8025"   # Interfície web (on veurem els correus)
      - "1025:1025"   # Port SMTP que utilitzarà Odoo per enviar
    restart: always

volumes:
  odoo-web-data:
  odoo-db-data:
EOF

    echo "⬇️ Clonant repositori de mòduls personalitzats..."
    cd "$ADDONS_DIR"
    if [ ! -d "$CUSTOM_REPO" ]; then
        echo "📦 Clonant $CUSTOM_REPO..."
        git clone https://github.com/juatafe/$CUSTOM_REPO.git || echo "⚠️ Repositori $CUSTOM_REPO no existeix encara o no està accessible."
    fi

    cd "$PROJECT_DIR"
    docker compose build
    docker compose up -d

    echo "⌛ Esperant que PostgreSQL estiga disponible..."
    until docker exec odoo_server-db-1 pg_isready -U odoo > /dev/null 2>&1; do
      sleep 2
    done
    echo "✅ PostgreSQL disponible!"

    echo "🛠️ Creant base de dades i instal·lant mòduls bàsics..."
    docker compose exec web odoo -d "$ODOO_DB_NAME" -i base,web --without-demo=all --load-language=ca --stop-after-init

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
echo "📦 [FASE 3] Instal·lant mòduls d'Odoo..."
cd "$PROJECT_DIR"

# Detectar mòduls personalitzats disponibles al repositori
CUSTOM_MODULES=()
if [ -d "$ADDONS_DIR/$CUSTOM_REPO" ]; then
    for dir in "$ADDONS_DIR/$CUSTOM_REPO"/*/ ; do
        if [ -f "$dir/__manifest__.py" ] || [ -f "$dir/__openerp__.py" ]; then
            module_name=$(basename "$dir")
            CUSTOM_MODULES+=("$module_name")
        fi
    done
    echo "🔍 Trobats ${#CUSTOM_MODULES[@]} mòduls personalitzats: ${CUSTOM_MODULES[*]}"
else
    echo "ℹ️ No s'han trobat mòduls personalitzats encara."
fi

# Actualitzar llista de mòduls disponibles
echo "🔄 Actualitzant llista de mòduls..."
docker compose exec web odoo -d "$ODOO_DB_NAME" -u base --stop-after-init

# Detectar mòduls ja instal·lats
echo "🔍 Detectant mòduls ja instal·lats..."
rm -f "$INSTALLED_MODULES_FILE"
docker compose exec -T web odoo shell -d "$ODOO_DB_NAME" <<EOF > "$INSTALLED_MODULES_FILE"
installed = env['ir.module.module'].search([('state','=','installed')])
for m in installed:
    print(m.name)
exit()
EOF

# Instal·lar mòduls un per un
for modul in "${DEFAULT_MODULES[@]}" "${CUSTOM_MODULES[@]}"; do
    if grep -qFx "$modul" "$INSTALLED_MODULES_FILE" 2>/dev/null; then
        echo "⏭️  Ja instal·lat: $modul"
        continue
    fi
    echo "🔹 Instal·lant: $modul..."
    if docker compose exec web odoo -i "$modul" -d "$ODOO_DB_NAME" --without-demo=all --stop-after-init 2>&1 | tee /tmp/odoo_install.log; then
        echo "$modul" >> "$INSTALLED_MODULES_FILE"
        echo "✅ $modul instal·lat"
    else
        if grep -q "already installed" /tmp/odoo_install.log || grep -q "No module named" /tmp/odoo_install.log; then
            echo "⚠️  $modul no disponible o ja instal·lat, continuant..."
            continue
        fi
        echo "❌ ERROR instal·lant $modul. Continuant amb els següents..."
    fi
done

echo "✅ Instal·lació de mòduls completada!"
docker compose restart web
echo "🎉 Odoo està llest! Accedeix a http://localhost:8069"
echo "   Usuari: admin"
echo "   Contrasenya: Pa\$\$w0rd"
echo "   Base de dades: $ODOO_DB_NAME"
exit 0

