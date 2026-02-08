# Annex B: Operacions habituals amb Docker per a Odoo

Aquest annex cobreix les operacions més freqüents en la gestió diària d'entorns Odoo desplegats amb Docker, basant-se en la pràctica real de desenvolupament i manteniment.

## Introducció

La gestió d'Odoo amb Docker requereix conèixer un conjunt d'operacions específiques que difereixen de la gestió tradicional. Aquest annex proporciona una guia pràctica per a:

- **Desenvolupadors**: Operacions de desenvolupament i testing
- **Administradors**: Gestió de producció i manteniment
- **DevOps**: Automatització i monitoratge

Totes les operacions estan provades en entorns reals i inclouen explicacions detallades per facilitar l'aprenentatge.

## Gestió bàsica de contenidors

### Operacions diàries amb Docker Compose

```bash
# Parar tots els serveis
docker compose down

# Iniciar amb reconstrucció d'imatges
docker compose up -d --build

# Reiniciar només el servei web d'Odoo
docker compose restart web

# Accedir al contenidor per a tasques administratives
docker compose exec web bash

# Veure logs en temps real
docker compose logs -f web

# Veure logs de tots els serveis
docker compose logs -f

# Iniciar en mode detached (segon pla)
docker compose up -d

# Veure l'estat de tots els contenidors
docker compose ps
```

**Explicació de les operacions:**

**Gestió de cicle de vida:**
- `docker compose down`: Atura i elimina tots els contenidors, xarxes i volums temporals del projecte. Les dades dels volums anomenats es mantenen.
- `docker compose up -d`: Inicia tots els serveis en mode daemon (background)
- `--build`: Força la reconstrucció de les imatges abans d'iniciar, útil quan s'han fet canvis al Dockerfile
- `docker compose restart web`: Només reinicia el contenidor d'Odoo sense afectar la base de dades ni altres serveis

**Accés i debugging:**
- `docker compose exec web bash`: Obre una sessió interactiva dins del contenidor per executar ordres d'Odoo directament
- `docker compose logs -f web`: Segueix els logs del servei web en temps real, essencial per detectar errors

### Verificació de l'estat del sistema

```bash
# Verificar que tots els serveis estan funcionant
docker compose ps

# Verificar l'ús de recursos
docker stats

# Verificar l'espai utilitzat per Docker
docker system df

# Informació detallada dels contenidors
docker compose top

# Verificar xarxes Docker
docker network ls

# Verificar volums Docker
docker volume ls
```

## Gestió de mòduls d'Odoo

### Instal·lació i actualització de mòduls

```bash
# Instal·lar un mòdul específic
docker compose exec web odoo -i nom_modul -d nom_base_dades

# Actualitzar un mòdul existent
docker compose exec web odoo -u nom_modul -d nom_base_dades

# Actualitzar sense interfície web (mode terminal)
docker compose exec web odoo --no-xmlrpc -u nom_modul -d nom_base_dades

# Exemple real d'actualització de mòdul familia
docker compose restart web && docker compose exec web odoo -u familia -d provestalens

# Instal·lar múltiples mòduls alhora
docker compose exec web odoo -i modul1,modul2,modul3 -d nom_base_dades

# Actualitzar tots els mòduls (ATENCIÓ: pot ser lent)
docker compose exec web odoo -u all -d nom_base_dades
```

**Explicació de les operacions amb mòduls:**

**Paràmetres essencials:**
- `-i nom_modul`: Instal·la el mòdul especificat (install)
- `-u nom_modul`: Actualitza el mòdul especificat (update)
- `-d nom_base_dades`: Especifica la base de dades on fer l'operació
- `--no-xmlrpc`: Desactiva la interfície web, útil per a operacions que poden donar conflictes

**Bones pràctiques:**
- Sempre reiniciar el servei web abans d'actualitzar mòduls (`docker compose restart web`)
- Usar `--no-xmlrpc` per a operacions en batch o scripts automatitzats
- Provar primer en entorns de desenvolupament abans d'aplicar a producció

### Gestió avançada de mòduls

```bash
# Detectar mòduls instal·lats
docker compose exec web odoo shell -d nom_base_dades <<EOF
modules = self.env['ir.module.module'].search([('state', '=', 'installed')])
for module in modules:
    print(f"{module.name} - {module.shortdesc}")
EOF

# Desinstal·lar un mòdul (cal fer des de la interfície web o shell)
docker compose exec web odoo shell -d nom_base_dades <<EOF
module = self.env['ir.module.module'].search([('name', '=', 'nom_modul')])
if module:
    module.button_immediate_uninstall()
EOF

# Verificar dependències d'un mòdul
docker compose exec web bash -c "
cd /mnt/extra-addons/nom_modul
cat __manifest__.py | grep -A 10 'depends'"
```

## Gestió de la base de dades

### Operacions amb PostgreSQL

```bash
# Accedir a la consola PostgreSQL
docker compose exec db psql -U odoo -d nom_base_dades

# També es pot accedir des del contenidor principal (alternativa)
docker exec -it odoo_dev-db-1 psql -U odoo -d provestalens

# Executar scripts SQL des de fitxer
cat script.sql | docker compose exec -T db psql -U odoo -d nom_base_dades

# Executar consulta SQL directa
docker compose exec db psql -U odoo -d nom_base_dades -c "SELECT COUNT(*) FROM res_users;"

# Exemple d'operació SQL directa per corregir sessions POS
docker compose exec db psql -U odoo -d provestalens -c "
UPDATE pos_session 
SET state = 'closed', stop_at = now() 
WHERE name = 'POS/00006';"

# Llistar totes les bases de dades
docker compose exec db psql -U odoo -c "\l"

# Llistar taules d'una base de dades
docker compose exec db psql -U odoo -d nom_base_dades -c "\dt"
```

### Operacions de manteniment de la base de dades

```bash
# Crear backup de la base de dades
docker compose exec db pg_dump -U odoo nom_base_dades > backup_$(date +%Y%m%d_%H%M%S).sql

# Restaurar backup
cat backup_file.sql | docker compose exec -T db psql -U odoo nom_base_dades

# Crear una nova base de dades
docker compose exec db createdb -U odoo nom_nova_bd

# Eliminar una base de dades (ATENCIÓ!)
docker compose exec db dropdb -U odoo nom_bd_eliminar

# Verificar la mida de les bases de dades
docker compose exec db psql -U odoo -c "
SELECT datname as database_name,
       pg_size_pretty(pg_database_size(datname)) as size
FROM pg_database
WHERE datistemplate = false
ORDER BY pg_database_size(datname) DESC;"

# Optimitzar la base de dades (VACUUM)
docker compose exec db psql -U odoo -d nom_base_dades -c "VACUUM ANALYZE;"
```

## Desenvolupament i debugging

### Eines per a desenvolupament

```bash
# Instal·lar paquets Python addicionals durant el desenvolupament
docker compose exec web pip3 install pandas requests beautifulsoup4

# Accedir amb permisos de root per a configuracions avançades
docker compose exec -u root web /bin/bash

# Reconstruir només la imatge personalitzada
docker compose build web

# Reconstruir forçant descàrrega de dependències
docker compose build --no-cache web

# Forçar reinstal·lació d'un mòdul problemàtic
docker compose restart web && docker compose exec web odoo -i nom_modul -d nom_bd

# Executar Odoo en mode desenvolupament
docker compose exec web odoo --dev=all -d nom_base_dades

# Accedir a la shell d'Odoo per a debugging
docker compose exec web odoo shell -d nom_base_dades
```

### Debugging avançat

```bash
# Executar Odoo amb debugging activat
docker compose exec web odoo --dev=xml,reload,qweb -d nom_base_dades

# Generar logs més detallats
docker compose exec web odoo --log-level=debug -d nom_base_dades

# Verificar la configuració actual d'Odoo
docker compose exec web odoo --config=/etc/odoo/odoo.conf --test-enable --stop-after-init

# Executar tests específics d'un mòdul
docker compose exec web odoo -i nom_modul --test-enable --stop-after-init -d test_db

# Detectar mòduls amb errors
docker compose logs web | grep -E "(ERROR|CRITICAL|WARNING)" | tail -20
```

## Neteja i manteniment

### Operacions de neteja i manteniment

```bash
# Neteja completa del sistema (ATENCIÓ: elimina dades!)
docker compose down
docker system prune --volumes -f
docker compose up -d

# Neteja selectiva (manté volums)
docker compose down
docker system prune -f
docker compose up -d

# Neteja de cache i fitxers temporals dins del contenidor
docker compose exec web bash -c "
rm -rf /var/lib/odoo/.local/share/Odoo/filestore/nom_bd
rm -rf /var/lib/odoo/.local/share/Odoo/web/assets
find /mnt/extra-addons -name '*.pyc' -delete
find /mnt/extra-addons -name '__pycache__' -type d -exec rm -r {} + 2>/dev/null || true
"

# Neteja de logs antics
docker compose exec web bash -c "
find /var/log/odoo -name '*.log' -mtime +7 -delete
truncate -s 0 /var/log/odoo/odoo.log
"

# Gestió d'espai en disc (informativa)
docker system df
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
```

**Explicació de la neteja:**

**Nivells de neteja:**
- `docker system prune --volumes -f`: Elimina contenidors, xarxes, imatges i volums no utilitzats (DESTRUCTIU)
- `docker system prune -f`: Elimina només contenidors, xarxes i imatges (manté volums)
- La neteja de filestore i assets força la regeneració de fitxers cache
- `*.pyc` i `__pycache__`: Fitxers cache de Python que poden causar problemes de compatibilitat

### Neteja específica per a desenvolupament

```bash
# Script de neteja per a desenvolupament
#!/bin/bash
# clean_dev.sh

echo "🧹 Netejant entorn de desenvolupament..."

# Parar serveis
docker compose down

# Neteja de cache Python
docker compose run --rm web bash -c "
find /mnt/extra-addons -name '*.pyc' -delete
find /mnt/extra-addons -name '__pycache__' -type d -exec rm -r {} + 2>/dev/null || true
echo 'Cache Python netejat'
"

# Eliminar imatges orfes
docker image prune -f

# Reiniciar serveis
docker compose up -d

echo "✅ Neteja completada"
```

## Gestió de repositoris Git dins dels mòduls

### Operacions Git per a mòduls personalitzats

```bash
# Clonar mòduls de repositoris externes (exemple OCA)
cd dev_addons/
git clone -b 16.0 https://github.com/OCA/account-financial-tools
git clone -b 16.0 https://github.com/OCA/server-tools

# Inicialitzar repositori per a mòdul propi
cd dev_addons/nom_modul/
git init
git add .
git commit -m "Primer commit - Mòdul personalitzat"

# Configurar repositori remot
git remote add origin https://github.com/usuari/nom_modul.git
git branch -M main
git push -u origin main

# Actualitzar tots els repositoris de mòduls
cd dev_addons/
for dir in */; do
    if [ -d "$dir/.git" ]; then
        echo "Actualitzant $dir"
        cd "$dir"
        git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || echo "Error actualitzant $dir"
        cd ..
    fi
done
```

### Gestió avançada de mòduls amb Git

```bash
# Script per verificar l'estat de tots els repositoris
#!/bin/bash
# git_status_all.sh

cd dev_addons/

echo "📊 Estat dels repositoris de mòduls:"
echo "======================================"

for dir in */; do
    if [ -d "$dir/.git" ]; then
        cd "$dir"
        
        echo "📁 $dir"
        
        # Verificar si hi ha canvis pendents
        if ! git diff-index --quiet HEAD --; then
            echo "  ⚠️  Canvis pendents de commit"
            git status --porcelain | head -5
        else
            echo "  ✅ Sense canvis pendents"
        fi
        
        # Verificar si està al dia amb el remot
        LOCAL=$(git rev-parse @)
        REMOTE=$(git rev-parse @{u} 2>/dev/null)
        
        if [ "$LOCAL" != "$REMOTE" ] && [ -n "$REMOTE" ]; then
            echo "  📥 Actualitzacions disponibles al remot"
        fi
        
        echo ""
        cd ..
    fi
done
```

## Backup i restauració

### Estratègies de backup

```bash
# Backup complet de la instal·lació Docker
#!/bin/bash
# backup_complete.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/odoo"
PROJECT_DIR="$HOME/odoo_server"

mkdir -p $BACKUP_DIR
cd $PROJECT_DIR

echo "🔄 Iniciant backup complet..."

# 1. Backup de base de dades
echo "📊 Backup de PostgreSQL..."
docker compose exec -T db pg_dump -U odoo postgres > $BACKUP_DIR/db_$DATE.sql

# 2. Backup de volums Docker (filestore, sessions, etc.)
echo "💾 Backup de volums de dades..."
docker run --rm \
  -v odoo_server_odoo-web-data:/data \
  -v $BACKUP_DIR:/backup \
  busybox tar czf /backup/volumes_$DATE.tar.gz -C /data .

# 3. Backup de configuració i mòduls personalitzats
echo "⚙️ Backup de configuració..."
tar czf $BACKUP_DIR/config_$DATE.tar.gz config_odoo/ dev_addons/ docker-compose.yml

# 4. Backup de logs (opcional)
echo "📝 Backup de logs..."
tar czf $BACKUP_DIR/logs_$DATE.tar.gz log/ 2>/dev/null || echo "No hi ha logs per fer backup"

# 5. Crear fitxer de verificació
echo "🔍 Creant fitxer de verificació..."
ls -la $BACKUP_DIR/*_$DATE.* > $BACKUP_DIR/backup_verification_$DATE.txt

# 6. Neteja de backups antics (mantenir últims 7 dies)
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "✅ Backup completat: $DATE"
echo "📁 Fitxers creats:"
ls -lh $BACKUP_DIR/*_$DATE.*
```

### Restauració des de backup

```bash
# Script de restauració
#!/bin/bash
# restore_backup.sh

BACKUP_DATE=$1
BACKUP_DIR="/backups/odoo"
PROJECT_DIR="$HOME/odoo_server"

if [ -z "$BACKUP_DATE" ]; then
    echo "Ús: $0 YYYYMMDD_HHMMSS"
    echo "Backups disponibles:"
    ls $BACKUP_DIR/db_*.sql | sed 's/.*db_\(.*\)\.sql/\1/'
    exit 1
fi

echo "⚠️ ATENCIÓ: Això restaurarà completament el sistema Odoo"
read -p "Estàs segur? (sí/no): " confirm

if [ "$confirm" != "sí" ]; then
    echo "Operació cancel·lada"
    exit 0
fi

cd $PROJECT_DIR

# 1. Parar serveis
echo "🛑 Parant serveis..."
docker compose down

# 2. Restaurar base de dades
echo "📊 Restaurant base de dades..."
docker compose up -d db
sleep 10
cat $BACKUP_DIR/db_$BACKUP_DATE.sql | docker compose exec -T db psql -U odoo postgres

# 3. Restaurar volums
echo "💾 Restaurant volums..."
docker run --rm \
  -v odoo_server_odoo-web-data:/data \
  -v $BACKUP_DIR:/backup \
  busybox tar xzf /backup/volumes_$BACKUP_DATE.tar.gz -C /data

# 4. Restaurar configuració
echo "⚙️ Restaurant configuració..."
tar xzf $BACKUP_DIR/config_$BACKUP_DATE.tar.gz

# 5. Iniciar serveis
echo "🚀 Iniciant serveis..."
docker compose up -d

echo "✅ Restauració completada!"
```

## Scripts d'automatització avançats

### Script d'actualització de mòdul

```bash
#!/bin/bash
# update_module.sh

MODULE_NAME=$1
DB_NAME=${2:-"provestalens"}

if [ -z "$MODULE_NAME" ]; then
    echo "Ús: $0 nom_modul [nom_bd]"
    exit 1
fi

echo "🔄 Actualitzant mòdul $MODULE_NAME a la base de dades $DB_NAME"

# Verificar que el mòdul existeix
if [ ! -d "dev_addons/$MODULE_NAME" ]; then
    echo "❌ Error: El mòdul $MODULE_NAME no existeix a dev_addons/"
    exit 1
fi

# Verificar que els serveis estan funcionant
if ! docker compose ps | grep -q "Up"; then
    echo "🚀 Iniciant serveis..."
    docker compose up -d
    sleep 10
fi

# Reiniciar el servei web
echo "🔄 Reiniciant servei web..."
docker compose restart web
sleep 5

# Actualitzar el mòdul
echo "📦 Actualitzant mòdul..."
docker compose exec web odoo -u $MODULE_NAME -d $DB_NAME

if [ $? -eq 0 ]; then
    echo "✅ Mòdul $MODULE_NAME actualitzat correctament"
else
    echo "❌ Error actualitzant el mòdul $MODULE_NAME"
    exit 1
fi
```

### Script de desplegament automàtic

```bash
#!/bin/bash
# deploy.sh

set -e  # Aturar en cas d'error

PROJECT_NAME=${1:-"odoo_dev"}
DB_NAME=${2:-"provestalens"}
MODULES=("familia" "event_family_registration" "payment_with_saldo")

echo "🚀 Iniciant desplegament de $PROJECT_NAME"

# 1. Verificar que estem al directori correcte
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: No es troba docker-compose.yml al directori actual"
    exit 1
fi

# 2. Parar serveis existents
echo "🛑 Parant serveis existents..."
docker compose down

# 3. Actualitzar repositoris de mòduls
echo "📥 Actualitzant repositoris de mòduls..."
for module in "${MODULES[@]}"; do
    if [ -d "dev_addons/$module/.git" ]; then
        echo "  📥 Actualitzant repositori $module"
        cd "dev_addons/$module"
        git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || echo "  ⚠️ No es pot actualitzar $module"
        cd ../..
    else
        echo "  ℹ️ $module no és un repositori Git"
    fi
done

# 4. Reconstruir i iniciar serveis
echo "🔨 Reconstruint i iniciant serveis..."
docker compose up -d --build

# 5. Esperar que PostgreSQL estigui disponible
echo "⏳ Esperant PostgreSQL..."
timeout=60
counter=0
until docker compose exec db pg_isready -U odoo > /dev/null 2>&1; do
    sleep 2
    counter=$((counter + 2))
    if [ $counter -ge $timeout ]; then
        echo "❌ Timeout esperant PostgreSQL"
        exit 1
    fi
done

echo "✅ PostgreSQL disponible"

# 6. Verificar que Odoo està funcionant
echo "⏳ Esperant Odoo..."
timeout=120
counter=0
until curl -f http://localhost:8069/web/database/selector > /dev/null 2>&1; do
    sleep 5
    counter=$((counter + 5))
    if [ $counter -ge $timeout ]; then
        echo "❌ Timeout esperant Odoo"
        exit 1
    fi
done

echo "✅ Odoo disponible"

# 7. Actualitzar mòduls
echo "🔄 Actualitzant mòduls..."
for module in "${MODULES[@]}"; do
    echo "  🔄 Actualitzant mòdul $module"
    if docker compose exec web odoo -u $module -d $DB_NAME; then
        echo "  ✅ $module actualitzat correctament"
    else
        echo "  ⚠️ Error actualitzant $module, continuant amb els següents..."
    fi
done

# 8. Mostrar estat final
echo ""
echo "🎉 Desplegament completat!"
echo "📊 Estat dels serveis:"
docker compose ps

echo ""
echo "📝 Seguint logs (Ctrl+C per aturar):"
docker compose logs -f web
```

## Monitoratge de rendiment amb exemples reals

### Interpretació de docker stats

L'ordre `docker stats` proporciona informació en temps real sobre l'ús de recursos:

```bash
# Exemple real de monitoratge d'Odoo amb Docker
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

CONTAINER ID   NAME                CPU %     MEM USAGE / LIMIT    MEM %     NET I/O         BLOCK I/O        PIDS 
aa9ae22cf873   odoo_server-web-1   0.05%     412.2MiB / 5.74GiB   7.01%     405MB / 465MB   458MB / 1.19MB   13 
891dd38f6e33   odoo_server-db-1    0.04%     201.2MiB / 5.74GiB   3.42%     304MB / 402MB   177MB / 1.25GB   15 
```

**Interpretació de les mètriques:**

**CPU Usage:**
- `0.05%` (Odoo) i `0.04%` (PostgreSQL): Ús molt baix, sistema en repòs
- **Normal en producció**: 5-20% en pics d'activitat
- **Alerta si >50%**: Possible sobrecàrrega o consultes lentes

**Memory Usage:**
- **Odoo**: 412.2MiB de 5.74GiB disponibles (7.01%)
- **PostgreSQL**: 201.2MiB (3.42%)
- **Regla general**: Odoo sol usar 1.5-2x més RAM que PostgreSQL
- **Límits recomanats**: 
  - Odoo: 2-4GB per entorns mitjans
  - PostgreSQL: 1-2GB (25-30% de la RAM total del sistema)

**Network I/O:**
- `405MB / 465MB`: Dades rebudes/enviades pel contenidor Odoo
- `304MB / 402MB`: Tràfic de la base de dades
- **Ràtio normal**: Odoo rep més dades (interfície web) que PostgreSQL

**Block I/O:**
- `458MB / 1.19MB` (Odoo): Molt poc accés a disc
- `177MB / 1.25GB` (PostgreSQL): Major escriptura a disc (normal per BD)

**PIDS (Process IDs):**
- 13 processos (Odoo) i 15 (PostgreSQL): Valors normals
- **Alerta si >100**: Possible problema de configuració

### Comandaments addicionals per al diagnòstic

```bash
# Monitoratge continu cada 2 segons
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemPerc}}\t{{.NetIO}}"

# Verificar logs per correlacionar amb mètriques
docker compose logs --tail=50 web | grep -E "(ERROR|WARNING|CRITICAL)"

# Monitoratge de PostgreSQL intern
docker compose exec db psql -U odoo -c "
SELECT query, state, query_start, now() - query_start AS duration 
FROM pg_stat_activity 
WHERE state != 'idle' 
ORDER BY duration DESC;"

# Monitoratge d'espai en disc per contenidor
docker system df
```

### Script de monitoratge automatitzat

```bash
#!/bin/bash
# monitor_odoo.sh

# Variables de configuració
CPU_LIMIT=50
MEM_LIMIT=80
LOG_FILE="/var/log/odoo-monitor.log"

echo "🔍 Iniciant monitoratge d'Odoo Docker..."

while true; do
    # Obtenir mètriques
    STATS=$(docker stats --no-stream --format "{{.CPUPerc}} {{.MemPerc}}" odoo_server-web-1 2>/dev/null)
    
    if [ -z "$STATS" ]; then
        echo "⚠️ ALERTA: Contenidor Odoo no trobat o no està funcionant" | tee -a $LOG_FILE
        sleep 30
        continue
    fi
    
    CPU=$(echo $STATS | cut -d' ' -f1 | sed 's/%//')
    MEM=$(echo $STATS | cut -d' ' -f2 | sed 's/%//')
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log mètriques
    echo "$TIMESTAMP - CPU: ${CPU}% | MEM: ${MEM}%" >> $LOG_FILE
    
    # Verificar límits
    if (( $(echo "$CPU > $CPU_LIMIT" | bc -l) )); then
        echo "$TIMESTAMP - ⚠️ ALERTA: CPU alt: ${CPU}%" | tee -a $LOG_FILE
        # Aquí es pot afegir codi per enviar notificacions
    fi
    
    if (( $(echo "$MEM > $MEM_LIMIT" | bc -l) )); then
        echo "$TIMESTAMP - ⚠️ ALERTA: Memòria alta: ${MEM}%" | tee -a $LOG_FILE
    fi
    
    sleep 30
done
```

## Resolució de problemes habituals

### Problemes comuns i solucions

**🔧 Error: "permission denied" en executar docker**
```bash
# Verificar que l'usuari està al grup docker
groups $USER

# Si no apareix 'docker', afegir-lo i reiniciar sessió
sudo usermod -aG docker $USER
# Tancar sessió i tornar a entrar, o:
newgrp docker
```

**🔧 Error: "port 8069 already in use"**
```bash
# Trobar què ocupa el port
sudo lsof -i :8069
sudo netstat -tlnp | grep 8069

# Parar el procés que l'ocupa
sudo systemctl stop odoo  # Si és Odoo tradicional
docker stop <container_id>  # Si és un altre contenidor
```

**🔧 Error: "no space left on device"**
```bash
# Verificar espai
docker system df

# Neteja completa (ATENCIÓ: elimina imatges no usades)
docker system prune -a

# Neteja més selectiva
docker image prune
docker container prune
```

**🔧 Error: "could not connect to database"**
```bash
# Verificar que PostgreSQL està en marxa
docker compose ps

# Verificar logs de la base de dades
docker compose logs db

# Reiniciar només la base de dades
docker compose restart db

# Verificar connectivitat des del contenidor web
docker compose exec web nc -zv db 5432
```

**🔧 Error: "build failed" o dependències**
```bash
# Forçar rebuild sense cache
docker compose build --no-cache

# Verificar Dockerfile syntax
docker build --no-cache .

# Netejar builds orfes
docker builder prune

# Verificar espai disponible
df -h
```

**🔧 Performance: contenidors lents**
```bash
# Verificar recursos
docker stats

# Verificar si hi ha swapping
free -h
cat /proc/swaps

# Verificar I/O de disc
sudo iotop

# En Docker Desktop, assignar més recursos:
# Settings → Resources → Advanced
```

### Debugging avançat de problemes

```bash
# Diagnostic complet del sistema
#!/bin/bash
# diagnostic.sh

echo "🔍 DIAGNÒSTIC COMPLET DEL SISTEMA ODOO DOCKER"
echo "============================================="

echo ""
echo "📊 Estat dels contenidors:"
docker compose ps

echo ""
echo "💾 Ús de recursos:"
docker stats --no-stream

echo ""
echo "💿 Espai en disc:"
docker system df

echo ""
echo "🌐 Connectivitat de xarxa:"
docker compose exec web nc -zv db 5432 && echo "✅ Connexió a BD: OK" || echo "❌ Connexió a BD: FALLA"

echo ""
echo "📋 Logs recents d'errors:"
docker compose logs --tail=20 web | grep -E "(ERROR|CRITICAL)" || echo "No hi ha errors recents"

echo ""
echo "🔧 Configuració d'Odoo:"
docker compose exec web cat /etc/odoo/odoo.conf | head -10

echo ""
echo "📂 Mòduls disponibles:"
docker compose exec web ls -la /mnt/extra-addons/ | wc -l
echo "mòduls detectats"

echo ""
echo "✅ Diagnòstic completat!"
```

## Optimització basada en mètriques reals

Basant-nos en l'exemple de mètriques anterior (sistema poc carregat), aquestes són les optimitzacions típiques:

### Si el CPU és alt (>30% constant)

```yaml
# docker-compose.yml - Limitar recursos per evitar monopolització
services:
  web:
    deploy:
      resources:
        limits:
          cpus: '2.0'
        reservations:
          cpus: '1.0'
```

### Si la memòria és alta (>80%)

```ini
# config_odoo/odoo.conf
[options]
limit_memory_hard = 2147483648  # 2GB límit dur
limit_memory_soft = 1610612736  # 1.5GB límit suau
workers = 4  # Ajustar segons CPU disponibles
```

### Si el disc I/O és alt

```yaml
# Usar volums amb millor rendiment
volumes:
  odoo-db-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /mnt/ssd-fast/odoo-db  # SSD ràpid per BD
```

## Conclusions

Aquest annex proporciona una guia completa per a la gestió professional d'entorns Odoo amb Docker. Les operacions documentades estan basades en experiència real i cobreixen des d'operacions bàsiques fins a scripts d'automatització avançats.

### Punts clau a recordar:

- **Sempre fer backup** abans d'operacions importants
- **Verificar l'estat** dels serveis abans de fer canvis
- **Monitoritzar recursos** regularment per prevenir problemes
- **Automatitzar** operacions repetitives amb scripts
- **Documentar** canvis i configuracions personalitzades

Amb aquestes operacions i scripts, la gestió diària d'Odoo amb Docker esdevé més eficient i menys propensa a errors.

