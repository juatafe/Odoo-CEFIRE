#!/bin/bash
# backup-docker.sh - Script de backup per a Odoo Docker

set -e

# Variables
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$(dirname "$0")/../data"
PROJECT_DIR="$(dirname "$0")/../.."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] $1${NC}"
}

log_info() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] $1${NC}"
}

# Crear directori de backup
mkdir -p "$BACKUP_DIR"

log "🔄 Iniciant backup Docker $DATE"

cd "$PROJECT_DIR"

# Verificar que els contenidors estan actius
if ! docker compose ps | grep -q "Up"; then
    log_info "⚠️  Els contenidors no estan actius. Iniciant-los..."
    docker compose up -d
    sleep 10
fi

# Backup de base de dades
log "📊 Backup de PostgreSQL..."
docker compose exec -T db pg_dump -U odoo postgres > "$BACKUP_DIR/db_$DATE.sql"

# Verificar que el backup de BD no està buit
if [ ! -s "$BACKUP_DIR/db_$DATE.sql" ]; then
    echo "❌ Error: El backup de la base de dades està buit"
    exit 1
fi

# Backup de volums Docker
log "💾 Backup de volums..."
docker run --rm \
  -v "${PWD##*/}_odoo-web-data":/data \
  -v "$PWD/$BACKUP_DIR":/backup \
  alpine tar czf "/backup/volumes_$DATE.tar.gz" -C /data .

# Backup de configuració
log "⚙️  Backup de configuració..."
tar czf "$BACKUP_DIR/config_$DATE.tar.gz" \
    config_odoo/ \
    dev_addons/ \
    docker-compose.yml \
    Dockerfile \
    2>/dev/null || true

# Comprimir backup de BD
log "🗜️  Comprimint backup de base de dades..."
gzip "$BACKUP_DIR/db_$DATE.sql"

# Neteja de backups antics (mantenir últims 7)
log "🧹 Netejant backups antics..."
cd "$BACKUP_DIR"
ls -t db_*.sql.gz 2>/dev/null | tail -n +8 | xargs rm -f || true
ls -t volumes_*.tar.gz 2>/dev/null | tail -n +8 | xargs rm -f || true
ls -t config_*.tar.gz 2>/dev/null | tail -n +8 | xargs rm -f || true

log "✅ Backup completat: $DATE"

# Mostrar informació del backup
echo ""
echo "📋 Informació del backup:"
ls -lh "$BACKUP_DIR"/*_$DATE.* 2>/dev/null || echo "No s'han creat fitxers de backup"

# Calcular mida total
total_size=$(du -sh "$BACKUP_DIR" | cut -f1)
echo "💾 Mida total dels backups: $total_size"