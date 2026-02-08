#!/bin/bash
# restore-docker.sh - Script de restauració per a Odoo Docker

set -e

# Variables
BACKUP_DIR="$(dirname "$0")/../data"
PROJECT_DIR="$(dirname "$0")/../.."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] $1${NC}"
}

log_info() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] $1${NC}"
}

log_error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] $1${NC}"
}

# Funció per mostrar ajuda
show_help() {
    echo "Ús: $0 [DATA_BACKUP]"
    echo ""
    echo "DATA_BACKUP: Data del backup en format YYYYMMDD_HHMMSS"
    echo ""
    echo "Backups disponibles:"
    ls -1 "$BACKUP_DIR"/db_*.sql.gz 2>/dev/null | sed 's/.*db_\(.*\)\.sql\.gz/  \1/' || echo "  Cap backup disponible"
}

# Verificar paràmetres
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

BACKUP_DATE="$1"

# Verificar que existeixen els fitxers de backup
DB_BACKUP="$BACKUP_DIR/db_$BACKUP_DATE.sql.gz"
VOLUMES_BACKUP="$BACKUP_DIR/volumes_$BACKUP_DATE.tar.gz"
CONFIG_BACKUP="$BACKUP_DIR/config_$BACKUP_DATE.tar.gz"

if [ ! -f "$DB_BACKUP" ]; then
    log_error "No s'ha trobat el backup de BD: $DB_BACKUP"
    show_help
    exit 1
fi

log "🔄 Iniciant restauració del backup: $BACKUP_DATE"

cd "$PROJECT_DIR"

# Confirmació de l'usuari
echo ""
log_info "⚠️  ATENCIÓ: Aquesta operació eliminarà les dades actuals!"
echo "Vols continuar amb la restauració? [y/N]"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    log_info "Restauració cancel·lada"
    exit 0
fi

# Aturar contenidors
log "🛑 Aturant contenidors..."
docker compose down

# Eliminar volums existents
log "🗑️  Eliminant volums existents..."
docker volume rm "${PWD##*/}_odoo-web-data" 2>/dev/null || true
docker volume rm "${PWD##*/}_odoo-db-data" 2>/dev/null || true

# Restaurar configuració si existeix
if [ -f "$CONFIG_BACKUP" ]; then
    log "⚙️  Restaurant configuració..."
    tar xzf "$CONFIG_BACKUP" -C .
fi

# Iniciar només la base de dades
log "🐘 Iniciant PostgreSQL..."
docker compose up -d db

# Esperar que PostgreSQL estigui disponible
log "⏳ Esperant PostgreSQL..."
timeout=60
counter=0
until docker compose exec db pg_isready -U odoo > /dev/null 2>&1; do
    counter=$((counter + 1))
    if [ $counter -gt $timeout ]; then
        log_error "Timeout esperant PostgreSQL"
        exit 1
    fi
    sleep 2
done

# Restaurar base de dades
log "📊 Restaurant base de dades..."
gunzip -c "$DB_BACKUP" | docker compose exec -T db psql -U odoo

# Restaurar volums si existeix el backup
if [ -f "$VOLUMES_BACKUP" ]; then
    log "💾 Restaurant volums..."
    
    # Crear volum buit
    docker volume create "${PWD##*/}_odoo-web-data"
    
    # Restaurar contingut
    docker run --rm \
        -v "${PWD##*/}_odoo-web-data":/data \
        -v "$PWD/$BACKUP_DIR":/backup \
        alpine tar xzf "/backup/volumes_$BACKUP_DATE.tar.gz" -C /data
fi

# Iniciar tots els serveis
log "🚀 Iniciant tots els serveis..."
docker compose up -d

# Esperar que Odoo estigui disponible
log "⏳ Esperant Odoo..."
timeout=120
counter=0
until curl -f http://localhost:8069/web/database/selector > /dev/null 2>&1; do
    counter=$((counter + 1))
    if [ $counter -gt $timeout ]; then
        log_error "Timeout esperant Odoo"
        break
    fi
    sleep 3
done

log "✅ Restauració completada!"
log_info "📍 URL d'accés: http://localhost:8069"

# Verificar estat final
echo ""
log "🔍 Estat final dels serveis:"
docker compose ps