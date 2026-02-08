# Annex C: Configuració avançada i producció d'Odoo

Aquest annex cobreix tots els aspectes necessaris per a un desplegament professional d'Odoo en entorns de producció, incloent seguretat, rendiment, monitoratge, backup i manteniment segons estàndards empresarials.

## Introducció

La transició d'un entorn de desenvolupament o proves a producció requereix consideracions específiques que van més enllà de la simple instal·lació. Aquest annex proporciona:

- **Seguretat multicapa**: Protecció a tots els nivells
- **Optimització de rendiment**: Configuració per a entorns d'alta càrrega
- **Monitoratge proactiu**: Detecció i resolució de problemes
- **Estratègies de backup**: Protecció de dades i continuïtat del negoci
- **Automatització**: Desplegament i manteniment automatitzats

## Seguretat multicapa per a producció

### Arquitectura de seguretat

Una configuració de producció robusta implementa seguretat en múltiples capes:

```{mermaid}
graph TD
    A[Internet] --> B[Firewall/WAF]
    B --> C[Load Balancer/Reverse Proxy]
    C --> D[Odoo Application]
    D --> E[PostgreSQL Database]
    
    F[SSL/TLS] --> C
    G[Authentication] --> D
    H[Network Segmentation] --> E
```

### 1) Configuració de firewall avançada

```bash
#!/bin/bash
# firewall-setup.sh - Configuració de firewall per a producció

# Variables de configuració
ADMIN_IPS="192.168.1.0/24,10.0.0.0/8"
OFFICE_IPS="203.0.113.0/24"
WEB_PORTS="80,443"
SSH_PORT="2222"  # Port SSH no estàndard per seguretat

echo "🔒 Configurant firewall per a entorn de producció..."

# Reset UFW
sudo ufw --force reset

# Politiques per defecte (deny all)
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH només des d'IPs administratives
for ip in $(echo $ADMIN_IPS | tr ',' ' '); do
    sudo ufw allow from $ip to any port $SSH_PORT proto tcp comment "SSH Admin"
done

# Web traffic des de qualsevol lloc
for port in $(echo $WEB_PORTS | tr ',' ' '); do
    sudo ufw allow $port/tcp comment "Web Traffic"
done

# PostgreSQL només local
sudo ufw allow from 127.0.0.1 to any port 5432 proto tcp comment "PostgreSQL Local"

# Odoo només local (reverse proxy)
sudo ufw allow from 127.0.0.1 to any port 8069 proto tcp comment "Odoo Local"

# Bloquejar accés directe a Odoo des d'exterior
sudo ufw deny 8069/tcp comment "Block external Odoo access"

# Rate limiting per SSH
sudo ufw limit $SSH_PORT/tcp comment "SSH Rate Limit"

# Logging
sudo ufw logging medium

# Activar firewall
sudo ufw --force enable

echo "✅ Firewall configurat correctament"
sudo ufw status numbered
```

### 2) Configuració SSL/TLS professional

```bash
# ssl-config.sh - Configuració SSL amb múltiples dominis

#!/bin/bash

DOMAINS="odoo.empresa.com,erp.empresa.com,www.odoo.empresa.com"
EMAIL="admin@empresa.com"
WEBROOT="/var/www/html"

echo "🔐 Configurant SSL/TLS per a múltiples dominis..."

# Instal·lar Certbot amb plugin Apache
sudo apt update
sudo apt install -y certbot python3-certbot-apache

# Crear certificat per a múltiples dominis
sudo certbot certonly \
    --webroot \
    --webroot-path=$WEBROOT \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --expand \
    -d $(echo $DOMAINS | tr ',' ' -d ')

# Configurar renovació automàtica amb notificacions
sudo tee /etc/systemd/system/certbot-renew.service > /dev/null <<EOF
[Unit]
Description=Certbot Renewal
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/certbot renew --quiet --post-hook "systemctl reload apache2"
ExecStartPost=/usr/bin/systemctl reload apache2
EOF

sudo tee /etc/systemd/system/certbot-renew.timer > /dev/null <<EOF
[Unit]
Description=Certbot Renewal Timer
Requires=certbot-renew.service

[Timer]
OnCalendar=*-*-* 03:00:00
RandomizedDelaySec=3600
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Activar timer de renovació
sudo systemctl enable certbot-renew.timer
sudo systemctl start certbot-renew.timer

# Test de renovació
sudo certbot renew --dry-run

echo "✅ SSL/TLS configurat amb renovació automàtica"
```

### 3) Configuració de seguretat d'aplicació

```ini
# /etc/odoo/odoo-production.conf
[options]
# Configuració de base de dades
db_host = localhost
db_port = 5432
db_user = odoo_prod
db_password = contrasenya_segura_generada
db_name = False  # No permetre creació de BD des de web
db_template = template0

# Seguretat de sessions
session_timeout = 3600  # 1 hora
max_cron_threads = 2

# Limits de seguretat
limit_memory_hard = 2684354560  # 2.5GB
limit_memory_soft = 2147483648  # 2GB
limit_request_body = 104857600  # 100MB
limit_time_cpu = 600           # 10 minuts
limit_time_real = 1200         # 20 minuts

# Workers per a producció
workers = 6  # 2 * CPU cores + 1
max_cron_threads = 2

# Proxy i interfície
proxy_mode = True
xmlrpc_interface = 127.0.0.1
xmlrpc_port = 8069
longpolling_port = 8072

# Logs de seguretat
log_level = warn
log_handler = :WARNING,werkzeug:CRITICAL,odoo.addons.base.models.ir_mail_server:WARNING
logfile = /var/log/odoo/odoo.log
logrotate = True

# Desactivar funcions perilloses en producció
test_enable = False
dev_mode = False
list_db = False
admin_passwd = $pbkdf2-sha512$...  # Hash generat amb werkzeug
```

### 4) Configuració avançada de PostgreSQL

```sql
-- postgresql-production.conf
-- Configuració optimitzada per a Odoo en producció

-- Memòria i cache
shared_buffers = 1GB                    -- 25% de la RAM
effective_cache_size = 3GB              -- 75% de la RAM
work_mem = 64MB                         -- Per a operacions de sort/hash
maintenance_work_mem = 512MB            -- Per a VACUUM, CREATE INDEX

-- Connexions
max_connections = 200                   -- Suficient per a workers d'Odoo
superuser_reserved_connections = 3

-- WAL (Write-Ahead Logging)
wal_buffers = 16MB
checkpoint_completion_target = 0.9
checkpoint_timeout = 10min
max_wal_size = 2GB
min_wal_size = 1GB

-- Logging i monitoring
log_statement = 'mod'                   -- Log modificacions
log_min_duration_statement = 1000       -- Log queries >1s
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on

-- Rendiment específic per a Odoo
random_page_cost = 1.1                  -- Per a SSD
effective_io_concurrency = 200          -- Per a SSD
default_statistics_target = 100
```

```bash
# PostgreSQL hardening script
#!/bin/bash
# postgresql-hardening.sh

echo "🔒 Configurant seguretat de PostgreSQL..."

# Crear usuari específic per a producció
sudo -u postgres psql <<EOF
-- Crear usuari amb permisos limitats
CREATE USER odoo_prod WITH PASSWORD 'contrasenya_segura_generada';

-- Crear base de dades específica
CREATE DATABASE odoo_production OWNER odoo_prod;

-- Revocar permisos per defecte
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON DATABASE template0 FROM PUBLIC;
REVOKE ALL ON DATABASE template1 FROM PUBLIC;

-- Configurar permisos específics
GRANT CONNECT ON DATABASE odoo_production TO odoo_prod;
GRANT CREATE ON DATABASE odoo_production TO odoo_prod;
\q
EOF

# Configurar autenticació
sudo cp /etc/postgresql/*/main/pg_hba.conf /etc/postgresql/*/main/pg_hba.conf.backup

sudo tee -a /etc/postgresql/*/main/pg_hba.conf > /dev/null <<EOF
# Configuració de seguretat per a producció
local   odoo_production    odoo_prod                     md5
host    odoo_production    odoo_prod    127.0.0.1/32     md5
host    odoo_production    odoo_prod    ::1/128          md5
EOF

# Reload configuració
sudo systemctl reload postgresql

echo "✅ PostgreSQL configurat per a producció"
```

## Optimització de rendiment

### Monitoratge de rendiment en temps real

```bash
#!/bin/bash
# performance-monitor.sh - Monitoratge avançat de rendiment

LOG_FILE="/var/log/odoo/performance.log"
THRESHOLD_CPU=80
THRESHOLD_MEM=85
THRESHOLD_DISK=90

monitor_system() {
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # CPU
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    
    # Memòria
    MEM_USAGE=$(free | grep Mem | awk '{printf("%.2f", ($3/$2) * 100.0)}')
    
    # Disc
    DISK_USAGE=$(df -h /var/lib/odoo | awk 'NR==2{print $5}' | sed 's/%//')
    
    # PostgreSQL
    PG_CONNECTIONS=$(sudo -u postgres psql -t -c "SELECT count(*) FROM pg_stat_activity WHERE state = 'active';" 2>/dev/null || echo "0")
    
    # Odoo processes
    ODOO_PROCESSES=$(ps aux | grep -c "[o]doo-bin")
    
    # Log mètriques
    echo "$TIMESTAMP,CPU:${CPU_USAGE},MEM:${MEM_USAGE},DISK:${DISK_USAGE},PG_CONN:${PG_CONNECTIONS},ODOO_PROC:${ODOO_PROCESSES}" >> $LOG_FILE
    
    # Alertes
    if (( $(echo "$CPU_USAGE > $THRESHOLD_CPU" | bc -l) )); then
        echo "$TIMESTAMP - ⚠️ CPU alta: ${CPU_USAGE}%" | logger -t odoo-monitor
    fi
    
    if (( $(echo "$MEM_USAGE > $THRESHOLD_MEM" | bc -l) )); then
        echo "$TIMESTAMP - ⚠️ Memòria alta: ${MEM_USAGE}%" | logger -t odoo-monitor
    fi
}

monitor_odoo_performance() {
    # Queries lentes de PostgreSQL
    SLOW_QUERIES=$(sudo -u postgres psql -d odoo_production -t -c "
        SELECT count(*) FROM pg_stat_activity 
        WHERE state = 'active' 
        AND now() - query_start > interval '30 seconds';" 2>/dev/null || echo "0")
    
    if [ "$SLOW_QUERIES" -gt 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ⚠️ $SLOW_QUERIES queries lentes detectades" | logger -t odoo-monitor
        
        # Log de les queries lentes
        sudo -u postgres psql -d odoo_production -c "
            SELECT query_start, now() - query_start AS duration, query 
            FROM pg_stat_activity 
            WHERE state = 'active' 
            AND now() - query_start > interval '30 seconds';" >> /var/log/odoo/slow_queries.log
    fi
}

# Bucle principal
while true; do
    monitor_system
    monitor_odoo_performance
    sleep 60
done
```

### Optimització de configuració segons càrrega

```bash
#!/bin/bash
# auto-tune-odoo.sh - Optimització automàtica segons recursos

# Detectar recursos del sistema
TOTAL_RAM_GB=$(free -g | awk 'NR==2{print $2}')
CPU_CORES=$(nproc)
DISK_TYPE=$(lsblk -d -o name,rota | grep -v NAME | awk '{if ($2 == 0) print "SSD"; else print "HDD"}' | head -1)

echo "🔧 Optimitzant configuració per a:"
echo "   RAM: ${TOTAL_RAM_GB}GB"
echo "   CPU: ${CPU_CORES} cores"
echo "   Disc: ${DISK_TYPE}"

# Calcular workers òptims
if [ $TOTAL_RAM_GB -lt 4 ]; then
    WORKERS=2
elif [ $TOTAL_RAM_GB -lt 8 ]; then
    WORKERS=4
elif [ $TOTAL_RAM_GB -lt 16 ]; then
    WORKERS=$((CPU_CORES + 1))
else
    WORKERS=$((CPU_CORES * 2))
fi

# Limits de memòria
MEMORY_SOFT=$((TOTAL_RAM_GB * 1024 * 1024 * 1024 / WORKERS))  # Per worker
MEMORY_HARD=$((MEMORY_SOFT * 120 / 100))  # 20% més que soft

# Generar configuració optimitzada
sudo tee /etc/odoo/odoo-optimized.conf > /dev/null <<EOF
[options]
# Configuració optimitzada automàticament
# Generat el $(date) per a:
# RAM: ${TOTAL_RAM_GB}GB, CPU: ${CPU_CORES} cores, Disc: ${DISK_TYPE}

# Workers optimitzats
workers = $WORKERS
max_cron_threads = 2

# Limits de memòria per worker
limit_memory_soft = $MEMORY_SOFT
limit_memory_hard = $MEMORY_HARD

# PostgreSQL segons tipus de disc
$(if [ "$DISK_TYPE" = "SSD" ]; then
    echo "# Optimització per a SSD"
    echo "db_template = template0"
else
    echo "# Optimització per a HDD"
    echo "db_template = template1"
fi)

# Timeouts segons recursos
limit_time_cpu = $((600 + TOTAL_RAM_GB * 60))
limit_time_real = $((1200 + TOTAL_RAM_GB * 120))

# Configuració de cache
$(if [ $TOTAL_RAM_GB -gt 8 ]; then
    echo "# Cache avançat per a sistemes amb >8GB RAM"
    echo "worker_connections = 1024"
else
    echo "# Cache conservador per a sistemes amb <8GB RAM"
    echo "worker_connections = 512"
fi)

EOF

echo "✅ Configuració optimitzada generada a /etc/odoo/odoo-optimized.conf"
```

## Monitoratge professional

### Sistema de monitoratge complet

```bash
#!/bin/bash
# monitoring-setup.sh - Configuració de monitoratge professional

# Instal·lar eines de monitoratge
sudo apt update
sudo apt install -y htop iotop nethogs ncdu prometheus-node-exporter

# Configurar Prometheus Node Exporter
sudo systemctl enable prometheus-node-exporter
sudo systemctl start prometheus-node-exporter

# Script de mètriques personalitzades
sudo tee /usr/local/bin/odoo-metrics.sh > /dev/null <<'EOF'
#!/bin/bash
# odoo-metrics.sh - Mètriques específiques d'Odoo

METRICS_FILE="/var/lib/prometheus/node-exporter/odoo.prom"

# Mètriques d'Odoo
ODOO_PROCESSES=$(ps aux | grep -c "[o]doo-bin")
ODOO_MEMORY=$(ps aux | grep "[o]doo-bin" | awk '{sum+=$6} END {print sum*1024}')

# Mètriques de PostgreSQL
if command -v psql >/dev/null 2>&1; then
    PG_CONNECTIONS=$(sudo -u postgres psql -t -c "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null || echo "0")
    PG_DATABASE_SIZE=$(sudo -u postgres psql -t -c "SELECT pg_database_size('odoo_production');" 2>/dev/null || echo "0")
    PG_ACTIVE_QUERIES=$(sudo -u postgres psql -t -c "SELECT count(*) FROM pg_stat_activity WHERE state = 'active';" 2>/dev/null || echo "0")
else
    PG_CONNECTIONS=0
    PG_DATABASE_SIZE=0
    PG_ACTIVE_QUERIES=0
fi

# Mètriques d'Apache (si està configurat)
if systemctl is-active --quiet apache2; then
    APACHE_CONNECTIONS=$(netstat -an | grep ":80\|:443" | grep ESTABLISHED | wc -l)
else
    APACHE_CONNECTIONS=0
fi

# Generar fitxer de mètriques Prometheus
cat > $METRICS_FILE <<METRICS
# HELP odoo_processes Number of Odoo processes
# TYPE odoo_processes gauge
odoo_processes $ODOO_PROCESSES

# HELP odoo_memory_bytes Memory used by Odoo processes
# TYPE odoo_memory_bytes gauge
odoo_memory_bytes $ODOO_MEMORY

# HELP postgresql_connections Total PostgreSQL connections
# TYPE postgresql_connections gauge
postgresql_connections $PG_CONNECTIONS

# HELP postgresql_active_queries Active PostgreSQL queries
# TYPE postgresql_active_queries gauge
postgresql_active_queries $PG_ACTIVE_QUERIES

# HELP postgresql_database_size_bytes Database size in bytes
# TYPE postgresql_database_size_bytes gauge
postgresql_database_size_bytes $PG_DATABASE_SIZE

# HELP apache_connections Active Apache connections
# TYPE apache_connections gauge
apache_connections $APACHE_CONNECTIONS
METRICS

EOF

chmod +x /usr/local/bin/odoo-metrics.sh

# Cron per a mètriques cada minut
echo "* * * * * /usr/local/bin/odoo-metrics.sh" | sudo crontab -

echo "✅ Sistema de monitoratge configurat"
```

### Dashboard de monitoratge en temps real

```bash
#!/bin/bash
# dashboard.sh - Dashboard de monitoratge en terminal

print_header() {
    clear
    echo "╔════════════════════════════════════════════════════════════════════════════════╗"
    echo "║                           ODOO PRODUCTION DASHBOARD                           ║"
    echo "║                            $(date '+%Y-%m-%d %H:%M:%S')                            ║"
    echo "╚════════════════════════════════════════════════════════════════════════════════╝"
    echo
}

print_system_metrics() {
    echo "📊 SISTEMA:"
    echo "────────────"
    
    # CPU
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    echo "   CPU: ${CPU_USAGE}%"
    
    # Memòria
    MEM_INFO=$(free -h | grep Mem)
    MEM_TOTAL=$(echo $MEM_INFO | awk '{print $2}')
    MEM_USED=$(echo $MEM_INFO | awk '{print $3}')
    MEM_PERCENT=$(free | grep Mem | awk '{printf("%.1f", ($3/$2) * 100.0)}')
    echo "   RAM: ${MEM_USED}/${MEM_TOTAL} (${MEM_PERCENT}%)"
    
    # Disc
    DISK_INFO=$(df -h / | grep -v Filesystem)
    DISK_USED=$(echo $DISK_INFO | awk '{print $3}')
    DISK_TOTAL=$(echo $DISK_INFO | awk '{print $2}')
    DISK_PERCENT=$(echo $DISK_INFO | awk '{print $5}')
    echo "   Disc: ${DISK_USED}/${DISK_TOTAL} (${DISK_PERCENT})"
    
    # Load Average
    LOAD=$(uptime | awk -F'load average:' '{print $2}')
    echo "   Load:${LOAD}"
    echo
}

print_odoo_metrics() {
    echo "🐍 ODOO:"
    echo "─────────"
    
    # Processos d'Odoo
    ODOO_PROCESSES=$(ps aux | grep -c "[o]doo-bin")
    echo "   Processos: $ODOO_PROCESSES"
    
    # Memòria d'Odoo
    ODOO_MEM=$(ps aux | grep "[o]doo-bin" | awk '{sum+=$6} END {printf("%.1f", sum/1024)}')
    echo "   Memòria: ${ODOO_MEM}MB"
    
    # Port 8069
    if netstat -tlnp | grep -q ":8069"; then
        echo "   Port 8069: ✅ Actiu"
    else
        echo "   Port 8069: ❌ Inactiu"
    fi
    
    # Últims logs
    echo "   Últims logs:"
    if [ -f /var/log/odoo/odoo.log ]; then
        tail -n 3 /var/log/odoo/odoo.log | while read line; do
            echo "     $(echo $line | cut -c1-70)..."
        done
    else
        echo "     No es troben logs"
    fi
    echo
}

print_postgresql_metrics() {
    echo "🐘 POSTGRESQL:"
    echo "──────────────"
    
    if command -v psql >/dev/null 2>&1; then
        # Connexions
        PG_CONNECTIONS=$(sudo -u postgres psql -t -c "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null | tr -d ' ')
        PG_ACTIVE=$(sudo -u postgres psql -t -c "SELECT count(*) FROM pg_stat_activity WHERE state = 'active';" 2>/dev/null | tr -d ' ')
        echo "   Connexions: $PG_CONNECTIONS (Actives: $PG_ACTIVE)"
        
        # Mida de BD
        PG_SIZE=$(sudo -u postgres psql -t -c "SELECT pg_size_pretty(pg_database_size('odoo_production'));" 2>/dev/null | tr -d ' ')
        echo "   Mida BD: $PG_SIZE"
        
        # Queries lentes
        SLOW_QUERIES=$(sudo -u postgres psql -t -c "SELECT count(*) FROM pg_stat_activity WHERE state = 'active' AND now() - query_start > interval '10 seconds';" 2>/dev/null | tr -d ' ')
        if [ "$SLOW_QUERIES" -gt 0 ]; then
            echo "   ⚠️  Queries lentes: $SLOW_QUERIES"
        else
            echo "   Queries lentes: $SLOW_QUERIES"
        fi
    else
        echo "   PostgreSQL no disponible"
    fi
    echo
}

print_network_metrics() {
    echo "🌐 XARXA:"
    echo "─────────"
    
    # Connexions HTTP/HTTPS
    HTTP_CONN=$(netstat -an | grep ":80" | grep ESTABLISHED | wc -l)
    HTTPS_CONN=$(netstat -an | grep ":443" | grep ESTABLISHED | wc -l)
    echo "   HTTP: $HTTP_CONN connexions"
    echo "   HTTPS: $HTTPS_CONN connexions"
    
    # Tràfic de xarxa
    RX_BYTES=$(cat /proc/net/dev | grep eth0 | awk '{print $2}')
    TX_BYTES=$(cat /proc/net/dev | grep eth0 | awk '{print $10}')
    echo "   RX: $(numfmt --to=iec $RX_BYTES)B"
    echo "   TX: $(numfmt --to=iec $TX_BYTES)B"
    echo
}

# Bucle principal
while true; do
    print_header
    print_system_metrics
    print_odoo_metrics
    print_postgresql_metrics
    print_network_metrics
    
    echo "Prem Ctrl+C per eixir | Actualització cada 5 segons"
    sleep 5
done
```

## Estratègies de backup robustes

### Backup complet amb rotació i verificació

```bash
#!/bin/bash
# backup-production.sh - Sistema de backup professional

# Configuració
BACKUP_BASE_DIR="/backups/odoo"
BACKUP_RETENTION_DAYS=30
BACKUP_RETENTION_WEEKS=12
BACKUP_RETENTION_MONTHS=12
DB_NAME="odoo_production"
PROJECT_DIR="/opt/odoo"

# Configuració de notificacions
NOTIFICATION_EMAIL="admin@empresa.com"
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# Funcions auxiliars
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$BACKUP_BASE_DIR/backup.log"
}

send_notification() {
    local status="$1"
    local message="$2"
    
    # Email
    if command -v mail >/dev/null 2>&1; then
        echo "$message" | mail -s "Backup Odoo - $status" "$NOTIFICATION_EMAIL"
    fi
    
    # Slack
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"🔄 Backup Odoo - $status\n$message\"}" \
            "$SLACK_WEBHOOK_URL" >/dev/null 2>&1
    fi
    
    # Syslog
    logger -t odoo-backup "$status: $message"
}

create_backup_dirs() {
    mkdir -p "$BACKUP_BASE_DIR"/{daily,weekly,monthly,temp}
    chmod 750 "$BACKUP_BASE_DIR"
}

backup_database() {
    local backup_file="$1"
    
    log_message "Iniciant backup de base de dades..."
    
    # Backup amb compressió
    if sudo -u postgres pg_dump -Fc "$DB_NAME" > "$backup_file.pgdump"; then
        log_message "✅ Backup de BD completat: $(ls -lh $backup_file.pgdump | awk '{print $5}')"
        
        # Verificar integritat
        if pg_restore --list "$backup_file.pgdump" >/dev/null 2>&1; then
            log_message "✅ Verificació d'integritat: OK"
            return 0
        else
            log_message "❌ Error en verificació d'integritat"
            return 1
        fi
    else
        log_message "❌ Error en backup de base de dades"
        return 1
    fi
}

backup_filestore() {
    local backup_file="$1"
    
    log_message "Iniciant backup de filestore..."
    
    if [ -d "/var/lib/odoo/filestore" ]; then
        tar czf "$backup_file.filestore.tar.gz" -C "/var/lib/odoo" filestore/ 2>/dev/null
        if [ $? -eq 0 ]; then
            log_message "✅ Backup de filestore completat: $(ls -lh $backup_file.filestore.tar.gz | awk '{print $5}')"
            return 0
        else
            log_message "❌ Error en backup de filestore"
            return 1
        fi
    else
        log_message "ℹ️ No es troba directori filestore"
        return 0
    fi
}

backup_configuration() {
    local backup_file="$1"
    
    log_message "Iniciant backup de configuració..."
    
    tar czf "$backup_file.config.tar.gz" \
        /etc/odoo/ \
        /etc/apache2/sites-available/ \
        /etc/systemd/system/odoo.service \
        "$PROJECT_DIR" \
        2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_message "✅ Backup de configuració completat"
        return 0
    else
        log_message "❌ Error en backup de configuració"
        return 1
    fi
}

encrypt_backup() {
    local backup_dir="$1"
    local encrypted_file="$2"
    
    log_message "Xifrant backup..."
    
    # Comprimir tots els fitxers del backup
    tar czf - -C "$(dirname $backup_dir)" "$(basename $backup_dir)" | \
    gpg --symmetric --cipher-algo AES256 --compress-algo 1 \
        --output "$encrypted_file" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_message "✅ Backup xifrat correctament"
        rm -rf "$backup_dir"
        return 0
    else
        log_message "❌ Error xifrant backup"
        return 1
    fi
}

sync_to_remote() {
    local local_file="$1"
    local remote_path="$2"
    
    log_message "Sincronitzant amb backup remot..."
    
    # Exemple amb rsync (configurar segons necessitats)
    if command -v rsync >/dev/null 2>&1; then
        rsync -avz --progress "$local_file" "$remote_path" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            log_message "✅ Sincronització remota completada"
            return 0
        else
            log_message "❌ Error en sincronització remota"
            return 1
        fi
    fi
    
    # Exemple amb rclone per a cloud storage
    if command -v rclone >/dev/null 2>&1; then
        rclone copy "$local_file" remote:backups/odoo/ >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            log_message "✅ Backup pujat al núvol"
            return 0
        else
            log_message "❌ Error pujant backup al núvol"
            return 1
        fi
    fi
}

cleanup_old_backups() {
    log_message "Netejant backups antics..."
    
    # Backups diaris (mantenir 30 dies)
    find "$BACKUP_BASE_DIR/daily" -name "*.gpg" -mtime +$BACKUP_RETENTION_DAYS -delete
    
    # Backups setmanals (mantenir 12 setmanes)
    find "$BACKUP_BASE_DIR/weekly" -name "*.gpg" -mtime +$((BACKUP_RETENTION_WEEKS * 7)) -delete
    
    # Backups mensuals (mantenir 12 mesos)
    find "$BACKUP_BASE_DIR/monthly" -name "*.gpg" -mtime +$((BACKUP_RETENTION_MONTHS * 30)) -delete
    
    log_message "✅ Neteja de backups antics completada"
}

# Funció principal de backup
main() {
    local backup_type="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$BACKUP_BASE_DIR/temp/backup_$timestamp"
    
    log_message "=== Iniciant backup $backup_type ==="
    
    create_backup_dirs
    mkdir -p "$backup_dir"
    
    # Executar backups
    local success=true
    
    if ! backup_database "$backup_dir/db"; then
        success=false
    fi
    
    if ! backup_filestore "$backup_dir/filestore"; then
        success=false
    fi
    
    if ! backup_configuration "$backup_dir/config"; then
        success=false
    fi
    
    if [ "$success" = true ]; then
        # Xifrar backup
        local final_backup="$BACKUP_BASE_DIR/$backup_type/odoo_backup_$timestamp.tar.gz.gpg"
        
        if encrypt_backup "$backup_dir" "$final_backup"; then
            # Sincronitzar amb remot
            sync_to_remote "$final_backup" "/remote/backup/path/"
            
            # Neteja
            cleanup_old_backups
            
            log_message "=== Backup $backup_type completat correctament ==="
            send_notification "ÈXIT" "Backup $backup_type completat correctament
Fitxer: $(basename $final_backup)
Mida: $(ls -lh $final_backup | awk '{print $5}')
Timestamp: $timestamp"
        else
            success=false
        fi
    fi
    
    if [ "$success" = false ]; then
        log_message "=== Backup $backup_type FALLIT ==="
        send_notification "ERROR" "Backup $backup_type ha fallat
Revisa els logs a $BACKUP_BASE_DIR/backup.log
Timestamp: $timestamp"
        exit 1
    fi
}

# Determinar tipus de backup segons el dia
case "$1" in
    "daily"|"weekly"|"monthly")
        main "$1"
        ;;
    *)
        # Auto-determinar segons el dia
        day_of_month=$(date +%d)
        day_of_week=$(date +%u)
        
        if [ "$day_of_month" = "01" ]; then
            main "monthly"
        elif [ "$day_of_week" = "7" ]; then
            main "weekly"
        else
            main "daily"
        fi
        ;;
esac
```

### Configuració de cron per a backups

```bash
# crontab-backup.sh - Configuració de cron per a backups

# Afegir al crontab del sistema
sudo tee -a /etc/crontab > /dev/null <<EOF

# Backups d'Odoo
# Backup diari a les 2:00 AM
0 2 * * * root /usr/local/bin/backup-production.sh daily

# Verificació setmanal de backups (diumenges a les 3:00 AM)
0 3 * * 0 root /usr/local/bin/verify-backups.sh

# Neteja mensual d'espai (primer diumenge del mes a les 4:00 AM)
0 4 1-7 * 0 root /usr/local/bin/cleanup-system.sh

EOF

# Script de verificació de backups
sudo tee /usr/local/bin/verify-backups.sh > /dev/null <<'EOF'
#!/bin/bash
# verify-backups.sh - Verificació de backups

BACKUP_DIR="/backups/odoo"
LOG_FILE="$BACKUP_DIR/verification.log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

verify_recent_backups() {
    log_message "=== Verificació de backups recents ==="
    
    # Verificar backup diari (últimes 24h)
    DAILY_BACKUP=$(find "$BACKUP_DIR/daily" -name "*.gpg" -mtime -1 | head -1)
    if [ -n "$DAILY_BACKUP" ]; then
        log_message "✅ Backup diari trobat: $(basename $DAILY_BACKUP)"
        
        # Test de desxifratge
        if gpg --decrypt "$DAILY_BACKUP" >/dev/null 2>&1 <<< "passphrase"; then
            log_message "✅ Backup diari es pot desxifrar"
        else
            log_message "❌ Error desxifrant backup diari"
        fi
    else
        log_message "❌ No es troba backup diari recent"
    fi
    
    # Verificar espai disponible
    AVAILABLE_SPACE=$(df "$BACKUP_DIR" | awk 'NR==2 {print $4}')
    REQUIRED_SPACE=10485760  # 10GB en KB
    
    if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
        log_message "⚠️ Poc espai disponible per a backups: $(($AVAILABLE_SPACE/1024/1024))GB"
    else
        log_message "✅ Espai suficient per a backups: $(($AVAILABLE_SPACE/1024/1024))GB"
    fi
}

verify_remote_sync() {
    log_message "=== Verificació de sincronització remota ==="
    
    if command -v rclone >/dev/null 2>&1; then
        REMOTE_FILES=$(rclone ls remote:backups/odoo/ | wc -l)
        log_message "📁 Fitxers al backup remot: $REMOTE_FILES"
        
        if [ "$REMOTE_FILES" -lt 5 ]; then
            log_message "⚠️ Pocs fitxers al backup remot"
        fi
    fi
}

# Executar verificacions
verify_recent_backups
verify_remote_sync

log_message "=== Verificació completada ==="
EOF

chmod +x /usr/local/bin/verify-backups.sh

echo "✅ Configuració de backups programada"
```

## Desplegament continu i DevOps

### Pipeline CI/CD complet

```yaml
# .gitlab-ci.yml - Pipeline de desplegament continu per a Odoo
stages:
  - test
  - security
  - build
  - deploy-staging
  - test-staging
  - deploy-production

variables:
  DOCKER_IMAGE: "$CI_REGISTRY_IMAGE/odoo"
  POSTGRES_DB: "test_odoo"
  POSTGRES_USER: "odoo"
  POSTGRES_PASSWORD: "test_password"

# Fase de testing
test_modules:
  stage: test
  image: odoo:16.0
  services:
    - postgres:13
  variables:
    POSTGRES_DB: $POSTGRES_DB
    POSTGRES_USER: $POSTGRES_USER
    POSTGRES_PASSWORD: $POSTGRES_PASSWORD
  script:
    - pip install -r requirements.txt
    - odoo -i base --test-enable --stop-after-init --log-level=test
    - odoo -i custom_module --test-enable --stop-after-init --log-level=test
  coverage: '/TOTAL.*\s+(\d+%)$/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml

# Auditoria de seguretat
security_scan:
  stage: security
  image: python:3.9
  script:
    - pip install safety bandit
    - safety check -r requirements.txt
    - bandit -r ./custom_modules/ -f json -o bandit-report.json
  artifacts:
    reports:
      security: bandit-report.json
  allow_failure: true

# Construcció d'imatge Docker
build_image:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $DOCKER_IMAGE:$CI_COMMIT_SHA .
    - docker tag $DOCKER_IMAGE:$CI_COMMIT_SHA $DOCKER_IMAGE:latest
    - docker push $DOCKER_IMAGE:$CI_COMMIT_SHA
    - docker push $DOCKER_IMAGE:latest
  only:
    - main
    - develop

# Desplegament a staging
deploy_staging:
  stage: deploy-staging
  image: alpine:latest
  before_script:
    - apk add --no-cache openssh-client
    - eval $(ssh-agent -s)
    - echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -
    - mkdir -p ~/.ssh
    - chmod 700 ~/.ssh
    - ssh-keyscan $STAGING_SERVER >> ~/.ssh/known_hosts
  script:
    - |
      ssh $STAGING_USER@$STAGING_SERVER << EOF
        cd /opt/odoo-staging
        docker-compose pull
        docker-compose up -d --no-deps web
        docker-compose exec -T web odoo -u all -d staging_db --stop-after-init
      EOF
  environment:
    name: staging
    url: https://staging.odoo.empresa.com
  only:
    - develop

# Tests d'integració en staging
test_staging:
  stage: test-staging
  image: python:3.9
  script:
    - pip install requests pytest
    - pytest tests/integration/ --staging-url=$STAGING_URL
  dependencies:
    - deploy_staging
  only:
    - develop

# Desplegament a producció
deploy_production:
  stage: deploy-production
  image: alpine:latest
  before_script:
    - apk add --no-cache openssh-client
    - eval $(ssh-agent -s)
    - echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -
    - mkdir -p ~/.ssh
    - chmod 700 ~/.ssh
    - ssh-keyscan $PRODUCTION_SERVER >> ~/.ssh/known_hosts
  script:
    - |
      ssh $PRODUCTION_USER@$PRODUCTION_SERVER << EOF
        # Backup abans del desplegament
        /usr/local/bin/backup-production.sh daily
        
        # Desplegament amb zero downtime
        cd /opt/odoo-production
        
        # Actualitzar codi
        docker-compose pull
        
        # Rolling update
        docker-compose up -d --no-deps --scale web=2 web
        sleep 30
        docker-compose up -d --no-deps --scale web=1 web
        
        # Actualitzar mòduls
        docker-compose exec -T web odoo -u custom_module -d production_db --stop-after-init
        
        # Verificar estat
        curl -f http://localhost:8069/web/health || exit 1
      EOF
  environment:
    name: production
    url: https://odoo.empresa.com
  when: manual
  only:
    - main
```

### Scripts de desplegament amb zero downtime

```bash
#!/bin/bash
# zero-downtime-deploy.sh - Desplegament sense interrupcions

set -e

# Configuració
PROJECT_DIR="/opt/odoo-production"
BACKUP_DIR="/backups/odoo"
HEALTH_CHECK_URL="http://localhost:8069/web/health"
MAX_WAIT_TIME=300  # 5 minuts

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

wait_for_health() {
    local url="$1"
    local max_wait="$2"
    local wait_time=0
    
    log_message "Esperant que el servei estigui saludable..."
    
    while [ $wait_time -lt $max_wait ]; do
        if curl -f "$url" >/dev/null 2>&1; then
            log_message "✅ Servei saludable"
            return 0
        fi
        
        sleep 10
        wait_time=$((wait_time + 10))
        log_message "Esperant... ($wait_time/$max_wait segons)"
    done
    
    log_message "❌ Timeout esperant que el servei estigui saludable"
    return 1
}

backup_before_deploy() {
    log_message "Creant backup abans del desplegament..."
    
    if /usr/local/bin/backup-production.sh daily; then
        log_message "✅ Backup creat correctament"
    else
        log_message "❌ Error creant backup"
        exit 1
    fi
}

rolling_update() {
    log_message "Iniciant rolling update..."
    
    cd "$PROJECT_DIR"
    
    # Obtenir imatge actualitzada
    log_message "Descarregant nova imatge..."
    docker-compose pull web
    
    # Escalar a 2 instàncies
    log_message "Escalant a 2 instàncies..."
    docker-compose up -d --scale web=2 --no-recreate web
    
    # Esperar que la nova instància estigui preparada
    sleep 30
    
    # Verificar que ambdues instàncies funcionen
    if wait_for_health "$HEALTH_CHECK_URL" 60; then
        log_message "✅ Nova instància funcionant correctament"
        
        # Reduir a 1 instància (elimina l'antiga)
        log_message "Reduint a 1 instància..."
        docker-compose up -d --scale web=1 --no-recreate web
        
        log_message "✅ Rolling update completat"
    else
        log_message "❌ Nova instància no funciona, fent rollback..."
        docker-compose up -d --scale web=1 --no-recreate web
        exit 1
    fi
}

update_modules() {
    log_message "Actualitzant mòduls..."
    
    # Llista de mòduls a actualitzar
    MODULES_TO_UPDATE="custom_module1,custom_module2,custom_module3"
    
    if docker-compose exec -T web odoo -u "$MODULES_TO_UPDATE" -d production_db --stop-after-init; then
        log_message "✅ Mòduls actualitzats correctament"
    else
        log_message "❌ Error actualitzant mòduls"
        exit 1
    fi
}

post_deploy_checks() {
    log_message "Executant verificacions post-desplegament..."
    
    # Verificar servei principal
    if ! wait_for_health "$HEALTH_CHECK_URL" 60; then
        log_message "❌ Servei principal no funciona"
        exit 1
    fi
    
    # Verificar base de dades
    if docker-compose exec -T db psql -U odoo -d production_db -c "SELECT 1;" >/dev/null 2>&1; then
        log_message "✅ Base de dades accessible"
    else
        log_message "❌ Problemes amb la base de dades"
        exit 1
    fi
    
    # Verificar mòduls carregats
    if docker-compose exec -T web odoo shell -d production_db -c "self.env['ir.module.module'].search([('state', '=', 'installed')])" >/dev/null 2>&1; then
        log_message "✅ Mòduls carregats correctament"
    else
        log_message "❌ Problemes amb els mòduls"
        exit 1
    fi
    
    log_message "✅ Totes les verificacions post-desplegament han passat"
}

# Funció principal
main() {
    log_message "=== Iniciant desplegament zero downtime ==="
    
    backup_before_deploy
    rolling_update
    update_modules
    post_deploy_checks
    
    log_message "=== Desplegament completat correctament ==="
}

# Executar si s'invoca directament
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
```

## Compliment normatiu i auditoria

### Configuració per a compliment RGPD

```bash
#!/bin/bash
# gdpr-compliance.sh - Configuració per a compliment RGPD

# Configuració de logs d'auditoria
setup_audit_logging() {
    log_message "Configurant logs d'auditoria RGPD..."
    
    # Configuració d'Odoo per a auditoria
    cat >> /etc/odoo/odoo.conf <<EOF

# Configuració RGPD i auditoria
log_level = info
log_handler = odoo.addons.base.models.res_users:INFO,odoo.sql_db:WARNING
logrotate = True

# Activar logging de dades personals
data_dir = /var/lib/odoo
list_db = False
admin_passwd = \$pbkdf2-sha512\$...

# Sessions i seguretat
session_timeout = 3600
max_cron_threads = 2
EOF
    
    # Script de monitoratge d'accés a dades personals
    cat > /usr/local/bin/gdpr-audit.sh <<'EOF'
#!/bin/bash
# Monitoratge d'accés a dades personals per RGPD

AUDIT_LOG="/var/log/odoo/gdpr-audit.log"

# Monitorejar accessos a models amb dades personals
PERSONAL_DATA_MODELS="res.partner,hr.employee,res.users"

for model in $(echo $PERSONAL_DATA_MODELS | tr ',' ' '); do
    # Buscar accessos recents al model
    grep -E "(read|write|create|unlink).*$model" /var/log/odoo/odoo.log | \
    while read line; do
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] GDPR_ACCESS: $line" >> $AUDIT_LOG
    done
done
EOF
    
    chmod +x /usr/local/bin/gdpr-audit.sh
    
    # Cron per executar cada hora
    echo "0 * * * * /usr/local/bin/gdpr-audit.sh" >> /etc/crontab
}

# Configuració de retenció de dades
setup_data_retention() {
    log_message "Configurant retenció de dades..."
    
    cat > /usr/local/bin/gdpr-retention.py <<'EOF'
#!/usr/bin/env python3
# Script de retenció de dades per RGPD

import psycopg2
from datetime import datetime, timedelta
import logging

# Configuració
DB_CONFIG = {
    'host': 'localhost',
    'database': 'production_db',
    'user': 'odoo',
    'password': 'password'
}

RETENTION_POLICIES = {
    'mail.message': 2555,  # 7 anys (comunicacions)
    'ir.logging': 365,     # 1 any (logs tècnics)
    'res.partner': None,   # Conservar (clients actius)
    'hr.employee': 2555,   # 7 anys després de baixa
}

def cleanup_old_data():
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()
    
    for table, days in RETENTION_POLICIES.items():
        if days is None:
            continue
            
        cutoff_date = datetime.now() - timedelta(days=days)
        
        # Exemple per mail.message
        if table == 'mail.message':
            query = """
                DELETE FROM mail_message 
                WHERE create_date < %s 
                AND message_type = 'comment'
            """
            cursor.execute(query, (cutoff_date,))
            
        # Exemple per logs
        elif table == 'ir.logging':
            query = """
                DELETE FROM ir_logging 
                WHERE create_date < %s
            """
            cursor.execute(query, (cutoff_date,))
        
        conn.commit()
        print(f"Netejat {cursor.rowcount} registres de {table}")
    
    conn.close()

if __name__ == "__main__":
    cleanup_old_data()
EOF
    
    chmod +x /usr/local/bin/gdpr-retention.py
    
    # Executar mensualment
    echo "0 2 1 * * /usr/local/bin/gdpr-retention.py" >> /etc/crontab
}

# Configuració d'encriptació de dades
setup_encryption() {
    log_message "Configurant encriptació de dades sensibles..."
    
    # Encriptació de base de dades
    cat >> /etc/postgresql/*/main/postgresql.conf <<EOF

# Encriptació per RGPD
ssl = on
ssl_cert_file = '/etc/ssl/certs/postgresql.crt'
ssl_key_file = '/etc/ssl/private/postgresql.key'
ssl_ciphers = 'HIGH:MEDIUM:+3DES:!aNULL'
ssl_prefer_server_ciphers = on

# Logging per auditoria
log_statement = 'mod'
log_min_duration_statement = 1000
log_connections = on
log_disconnections = on
EOF
    
    # Generar certificats SSL per PostgreSQL
    openssl req -new -x509 -days 3650 -nodes -text \
        -out /etc/ssl/certs/postgresql.crt \
        -keyout /etc/ssl/private/postgresql.key \
        -subj "/CN=postgresql"
    
    chown postgres:postgres /etc/ssl/private/postgresql.key
    chmod 600 /etc/ssl/private/postgresql.key
}

main() {
    setup_audit_logging
    setup_data_retention
    setup_encryption
    
    log_message "✅ Configuració RGPD completada"
}

main
```
