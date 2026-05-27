#!/bin/bash
# deploy-odoo-docker.sh - Desplegament automatitzat d'Odoo amb Docker

set -e

# Colors per a output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables de configuració
PROJECT_NAME="odoo_server"
PROJECT_DIR=~/odoo_server
ODOO_DB_NAME="morrallaodoo"
ADMIN_EMAIL="admin@empresa.com"
ADMIN_PASSWORD="AdminPassword2026!"

# Mòduls personalitzats a instal·lar
CUSTOM_MODULES=()

# Flags de control de fases
PHASE1_FLAG="$PROJECT_DIR/.phase1_docker_done"
PHASE2_FLAG="$PROJECT_DIR/.phase2_odoo_started"
PHASE3_FLAG="$PROJECT_DIR/.phase3_modules_installed"

# Funció de logging
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"
}

log_info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] ℹ️  $1${NC}"
}

# Verificar prerequisits
check_prerequisites() {
    log_info "Verificant prerequisits..."
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker no està instal·lat. Instal·la Docker primer."
        exit 1
    fi
    
    # Verificar Docker Compose
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose no està disponible."
        exit 1
    fi
    
    # Verificar permisos Docker
    if ! docker ps &> /dev/null; then
        log_error "L'usuari no té permisos per executar Docker. Afegeix l'usuari al grup docker."
        exit 1
    fi
    
    # Verificar espai en disc
    available_space=$(df ~ | awk 'NR==2 {print $4}')
    required_space=5242880  # 5GB en KB
    
    if [ "$available_space" -lt "$required_space" ]; then
        log_warning "Poc espai en disc disponible: $(($available_space/1024/1024))GB"
        log_warning "Es recomanen almenys 5GB lliures"
    fi
    
    log "✅ Prerequisits verificats"
}

# Fase 1: Configuració inicial
phase1_setup() {
    if [ -f "$PHASE1_FLAG" ]; then
        log_info "Fase 1 ja completada, saltant..."
        return 0
    fi
    
    log "🏗️  Fase 1: Configuració inicial del projecte"
    
    # Crear estructura de directoris
    log_info "Creant estructura de directoris..."
    mkdir -p "$PROJECT_DIR"/{config_odoo,dev_addons,log,backups,scripts}
    
    cd "$PROJECT_DIR"
    
    # Crear fitxer de configuració d'Odoo
    log_info "Creant configuració d'Odoo..."
    cat > config_odoo/odoo.conf <<EOF
[options]
admin_passwd = $ADMIN_PASSWORD
db_host = db
db_port = 5432
db_user = odoo
db_password = myodoo
addons_path = /usr/lib/python3/dist-packages/odoo/addons,/mnt/extra-addons
data_dir = /var/lib/odoo
logfile = /var/log/odoo/odoo.log
log_level = info
xmlrpc_interface = 0.0.0.0
proxy_mode = True
workers = 0
max_cron_threads = 2
without_demo = True
EOF
    
    # Crear docker-compose.yml
    log_info "Creant configuració Docker Compose..."
    cat > docker-compose.yml <<'EOF'
services:
  web:
    build: .
    depends_on:
      - db
    ports:
      - "8069:8069"
    volumes:
      - odoo-web-data:/var/lib/odoo
      - ./config_odoo:/etc/odoo:ro
      - ./dev_addons:/mnt/extra-addons:ro
      - ./log:/var/log/odoo
    environment:
      - HOST=db
      - USER=odoo
      - PASSWORD=myodoo
    restart: unless-stopped

  db:
    image: postgres:16
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_PASSWORD=myodoo
      - POSTGRES_USER=odoo
      - PGDATA=/var/lib/postgresql/data/pgdata
    volumes:
      - odoo-db-data:/var/lib/postgresql/data/pgdata
    restart: unless-stopped

volumes:
  odoo-web-data:
  odoo-db-data:
EOF
    
    # Crear Dockerfile
    log_info "Creant Dockerfile personalitzat..."
    cat > Dockerfile <<'EOF'
FROM odoo:16.0

USER root

# Actualitzar dependències Python per compatibilitat
RUN pip uninstall jinja2 markupsafe -y && \
    pip install jinja2==3.1.2 markupsafe==2.1.1 requests pandas && \
    mkdir -p /var/log/odoo && \
    chown -R odoo:odoo /var/log/odoo

USER odoo
EOF
    
    # Marcar fase com completada
    touch "$PHASE1_FLAG"
    log "✅ Fase 1 completada"
}

# Fase 2: Descàrrega de mòduls i desplegament
phase2_deploy() {
    if [ -f "$PHASE2_FLAG" ]; then
        log_info "Fase 2 ja completada, saltant..."
        return 0
    fi
    
    log "📦 Fase 2: Descàrrega de mòduls i desplegament"
    
    cd "$PROJECT_DIR"
    
    # Clonar repositoris de mòduls personalitzats
    log_info "Descarregant mòduls personalitzats..."

    # Construir i iniciar contenidors
    log_info "Construint imatges Docker..."
    docker compose build
    
    log_info "Iniciant serveis..."
    docker compose up -d
    
    # Esperar que PostgreSQL estigui disponible
    log_info "Esperant que PostgreSQL estigui disponible..."
    timeout=120
    counter=0
    until docker compose exec db pg_isready -U odoo > /dev/null 2>&1; do
        counter=$((counter + 1))
        if [ $counter -gt $timeout ]; then
            log_error "Timeout esperant PostgreSQL"
            exit 1
        fi
        sleep 2
    done
    
    log "✅ PostgreSQL disponible"
    
    # Esperar que Odoo estigui disponible
    log_info "Esperant que Odoo estigui disponible..."
    timeout=180
    counter=0
    until curl -f http://localhost:8069/web/database/selector > /dev/null 2>&1; do
        counter=$((counter + 1))
        if [ $counter -gt $timeout ]; then
            log_error "Timeout esperant Odoo"
            log_info "Logs d'Odoo:"
            docker compose logs web | tail -20
            exit 1
        fi
        sleep 3
    done
    
    log "✅ Odoo disponible"
    
    # Crear base de dades
    log_info "Creant base de dades '$ODOO_DB_NAME'..."
    
    # Verificar si la BD ja existeix
    if docker compose exec db psql -U odoo -lqt | cut -d \| -f 1 | grep -qw "$ODOO_DB_NAME"; then
        log_warning "La base de dades '$ODOO_DB_NAME' ja existeix"
    else
        docker compose exec db createdb -U odoo "$ODOO_DB_NAME"
        log "✅ Base de dades creada"
    fi
    
    # Marcar fase com completada
    touch "$PHASE2_FLAG"
    log "✅ Fase 2 completada"
}

# Fase 3: Configuració de mòduls
phase3_modules() {
    if [ -f "$PHASE3_FLAG" ]; then
        log_info "Fase 3 ja completada, saltant..."
        return 0
    fi
    
    log "🔧 Fase 3: Configuració de mòduls"
    
    cd "$PROJECT_DIR"
    
    # Arxiu per registrar mòduls instal·lats
    INSTALLED_MODULES_FILE="$PROJECT_DIR/.installed_modules"
    
    # Funció per verificar si un mòdul està instal·lat
    is_module_installed() {
        local module_name="$1"
        grep -q "^$module_name$" "$INSTALLED_MODULES_FILE" 2>/dev/null
    }
    
    # Funció per marcar un mòdul com instal·lat
    mark_module_installed() {
        local module_name="$1"
        echo "$module_name" >> "$INSTALLED_MODULES_FILE"
    }
    
    # Instal·lar mòduls base necessaris
    BASE_MODULES=("base" "web" "mail" "portal")
    
    for module in "${BASE_MODULES[@]}"; do
        if ! is_module_installed "$module"; then
            log_info "Instal·lant mòdul base: $module"
            if docker compose exec web odoo -i "$module" -d "$ODOO_DB_NAME" --stop-after-init; then
                mark_module_installed "$module"
                log "✅ Mòdul $module instal·lat"
            else
                log_warning "Error instal·lant mòdul $module"
            fi
        else
            log_info "Mòdul $module ja està instal·lat"
        fi
    done
    
    # Instal·lar mòduls personalitzats
    for module in "${CUSTOM_MODULES[@]}"; do
        if ! is_module_installed "$module"; then
            log_info "Instal·lant mòdul personalitzat: $module"
            
            # Verificar que el mòdul existeix
            if [ -d "dev_addons/$module" ]; then
                if docker compose exec web odoo -i "$module" -d "$ODOO_DB_NAME" --stop-after-init; then
                    mark_module_installed "$module"
                    log "✅ Mòdul $module instal·lat correctament"
                else
                    log_warning "Error instal·lant mòdul $module, continuant..."
                fi
            else
                log_warning "Mòdul $module no trobat a dev_addons/"
            fi
        else
            log_info "Mòdul $module ja està instal·lat"
        fi
    done
    
    # Reiniciar Odoo per aplicar tots els canvis
    log_info "Reiniciant Odoo per aplicar canvis..."
    docker compose restart web
    
    # Esperar que Odoo estigui disponible després del reinici
    sleep 10
    timeout=60
    counter=0
    until curl -f http://localhost:8069/web/database/selector > /dev/null 2>&1; do
        counter=$((counter + 1))
        if [ $counter -gt $timeout ]; then
            log_error "Timeout després del reinici"
            break
        fi
        sleep 2
    done
    
    # Marcar fase com completada
    touch "$PHASE3_FLAG"
    log "✅ Fase 3 completada"
}

# Funció de verificació final
final_verification() {
    log "🔍 Verificació final del desplegament"
    
    cd "$PROJECT_DIR"
    
    # Verificar estat dels contenidors
    log_info "Estat dels contenidors:"
    docker compose ps
    
    # Verificar connectivitat
    log_info "Verificant connectivitat..."
    
    if curl -f http://localhost:8069/web/database/selector > /dev/null 2>&1; then
        log "✅ Odoo accessible"
    else
        log_error "Odoo no accessible"
        return 1
    fi
    
    # Verificar base de dades
    if docker compose exec db psql -U odoo -c "SELECT 1;" > /dev/null 2>&1; then
        log "✅ PostgreSQL accessible"
    else
        log_error "PostgreSQL no accessible"
        return 1
    fi
    
    # Informació del sistema
    log_info "Informació del desplegament:"
    echo "  📍 URL d'accés: http://localhost:8069"
    echo "  🏢 Base de dades: $ODOO_DB_NAME"
    echo "  👤 Email admin: $ADMIN_EMAIL"
    echo "  📁 Directori projecte: $PROJECT_DIR"
    echo "  🐳 Contenidors: $(docker compose ps --services | tr '\n' ' ')"
    
    log "🎉 Desplegament d'Odoo completat correctament!"
}

# Funció de neteja en cas d'error
cleanup_on_error() {
    log_error "Error detectat, executant neteja..."
    cd "$PROJECT_DIR" 2>/dev/null || return
    docker compose down 2>/dev/null || true
    log_info "Neteja completada"
}

# Configurar trap per neteja automàtica
trap cleanup_on_error ERR

# Funció principal
main() {
    log "🚀 Iniciant desplegament automatitzat d'Odoo amb Docker"
    log_info "Projecte: $PROJECT_NAME"
    log_info "Directori: $PROJECT_DIR"
    log_info "Base de dades: $ODOO_DB_NAME"
    
    check_prerequisites
    phase1_setup
    phase2_deploy
    phase3_modules
    final_verification
    
    log "✨ Procés completat exitosament!"
}

# Executar si s'invoca directament
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi