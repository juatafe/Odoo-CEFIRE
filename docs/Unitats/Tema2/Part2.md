Part 2: Desplegament d'Odoo amb Docker
=========================================

Aquest document cobreix el desplegament complet d'Odoo 16 utilitzant contenidors Docker i Docker Compose. Aquesta metodologia moderna ofereix avantatges significatius en portabilitat, escalabilitat i gestió d'entorns, sent especialment valuosa per a desenvolupament ràpid i desplegaments professionals.

## Introducció

Docker revoluciona la manera de desplegar aplicacions empresarials com Odoo, proporcionant un entorn consistent i reproducible que elimina els problemes de "funciona a la meva màquina". Aquesta aproximació és ideal per a:

- **Equips de desenvolupament** que necessiten entorns idèntics
- **Desplegaments múltiples** en diferents servidors
- **Escalabilitat ràpida** amb requeriments canviants
- **Manteniment simplificat** amb actualitzacions controlades
- **Entorns híbrids** cloud i on-premise

### Arquitectura del sistema amb Docker

```{mermaid}
graph TD
    A[Cliente Web] --> B[Load Balancer/Proxy]
    B --> C[Odoo Container]
    C --> D[PostgreSQL Container]
    
    E[Docker Host] --> F[Docker Networks]
    F --> C
    F --> D
    
    G[Volumes] --> C
    G --> D
    
    H[Custom Modules] --> C
    I[Configuration Files] --> C
```

### Avantatges vs inconvenients

| ✅ **Avantatges** | ❌ **Inconvenients** |
|------------------|---------------------|
| Portabilitat completa entre entorns | Corba d'aprenentatge de Docker |
| Aïllament total de dependències | Overhead mínim de rendiment |
| Desplegament en minuts | Necessita gestió de volums |
| Escalabilitat horitzontal | Debugging més complex |
| Rollback instantani | Requereix conceptes de contenidors |
| Reproducibilitat del 100% | Gestió de xarxes específica |

### Comparativa amb instal·lació tradicional

| **Aspecte** | **Instal·lació Tradicional** | **Docker** |
|-------------|------------------------------|------------|
| **Temps desplegament** | 2-4 hores | 15-30 minuts |
| **Configuració inicial** | Manual i complexa | Automatitzada |
| **Manteniment** | Actualitzacions manuals | `docker-compose pull` |
| **Backup** | Scripts específics del sistema | Volums standarditzats |
| **Escalabilitat** | Configuració manual | Orchestració automàtica |
| **Desenvolupament** | Un entorn per màquina | Múltiples entorns aïllats |

### Prerequisites del sistema

:::{admonition} Requisits per a Docker
:class: important
**Hardware recomanat:**
- CPU: 4+ cores (2.5+ GHz)
- RAM: 8+ GB (Docker necessita recursos adicionals)
- Disc: 50+ GB d'espai lliure (imatges i volums)
- Xarxa: Connexió estable a Internet per descarregar imatges

**Software:**
- Ubuntu 20.04 LTS o posterior (o equivalent)
- Accés sudo al sistema
- Ports 8069 i 5432 lliures

**Coneixements tècnics:**
- Conceptes bàsics de contenidors
- YAML per a configuració
- Línia d'ordres de Linux
- Gestió bàsica de xarxes
:::

### Docker vs Docker Compose

**Docker** és la plataforma de contenidors, mentre que **Docker Compose** és l'eina d'orquestració que permet gestionar aplicacions multi-contenidor mitjançant fitxers YAML.

**Per què Docker Compose per a Odoo?**
- Odoo necessita múltiples serveis (app + base de dades)
- Gestió automàtica de xarxes entre contenidors
- Configuració declarativa i versionable
- Facilita operacions com backup, escalament i monitoratge

## Arquitectura de la solució

### Estructura del projecte

Una implementació professional amb Docker segueix aquesta estructura organitzativa:

```
odoo_project/
├── docker-compose.yml           # Orquestració principal
├── docker-compose.override.yml  # Configuració de desenvolupament
├── docker-compose.prod.yml      # Configuració de producció
├── Dockerfile                   # Imatge personalitzada d'Odoo
├── .env                         # Variables d'entorn
├── config_odoo/
│   ├── odoo.conf               # Configuració principal
│   └── odoo-dev.conf           # Configuració de desenvolupament
├── dev_addons/                 # Mòduls personalitzats
│   ├── modul_custom_1/
│   │   ├── __manifest__.py
│   │   ├── models/
│   │   ├── views/
│   │   └── static/
│   └── modul_custom_2/
├── backups/                    # Scripts i dades de backup
│   ├── scripts/
│   └── data/
├── log/                        # Logs del sistema
└── scripts/                    # Scripts d'automatització
    ├── deploy.sh
    ├── backup.sh
    └── monitor.sh
```

### Components de l'arquitectura

**1. Contenidor PostgreSQL:**
- Imatge oficial `postgres:15`
- Volums persistents per a dades
- Configuració optimitzada per a Odoo
- Variables d'entorn per a seguretat

**2. Contenidor Odoo:**
- Basada en imatge oficial `odoo:16.0`
- Personalitzada amb mòduls específics
- Muntatge de volums per a configuració i dades
- Comunicació amb PostgreSQL via xarxa Docker

**3. Volums Docker:**
- `odoo-db-data`: Persistència de la base de dades
- `odoo-web-data`: Filestore i sessions d'Odoo
- Muntatges bind per a desenvolupament

**4. Xarxa Docker:**
- Xarxa interna per a comunicació segura
- Exposició controlada de ports
- Resolució DNS automàtica entre contenidors

## Preparació de l'entorn

### Instal·lació de Docker

La instal·lació de Docker és el primer pas fonamental. Començarem eliminant versions anteriors i instal·lant la versió oficial estable.

```bash
# Eliminar versions anteriors de Docker (si existeixen)
sudo apt-get remove -y docker docker-engine docker.io containerd runc

# Neteja de dependències
sudo apt-get autoremove -y
sudo apt-get autoclean

# Actualitzar sistema
sudo apt-get update
sudo apt-get upgrade -y

# Instal·lar dependències
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

# Afegir clau GPG oficial de Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Afegir repositori oficial
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Actualitzar llista de paquets
sudo apt-get update

# Instal·lar Docker Engine
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verificar la instal·lació
sudo docker run hello-world
```

**Components instal·lats:**
- `docker-ce`: Docker Community Edition (motor principal)
- `docker-ce-cli`: Interfície de línia d'ordres
- `containerd.io`: Runtime de contenidors
- `docker-buildx-plugin`: Constructor avançat d'imatges
- `docker-compose-plugin`: Compose v2 integrat

### Configuració d'usuari i permisos

```bash
# Afegir usuari actual al grup docker
sudo usermod -aG docker $USER

# Aplicar canvis de grup (reiniciar sessió o usar newgrp)
newgrp docker

# Verificar que funciona sense sudo
docker version
docker compose version

# Configurar inici automàtic de Docker
sudo systemctl enable docker
sudo systemctl enable containerd
```

## Configuració del projecte

### Creació de l'estructura de directoris

```bash
# Crear directori principal del projecte
PROJECT_DIR=~/odoo_server
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Crear estructura de directoris
mkdir -p {config_odoo,dev_addons,log,backups,scripts}

# Crear subdirectoris específics
mkdir -p backups/{scripts,data}
mkdir -p scripts/{maintenance,deployment}

# Verificar estructura
tree $PROJECT_DIR || ls -la $PROJECT_DIR
```

### Configuració de Docker Compose

El fitxer `docker-compose.yml` és el cor de la configuració. Aquest fitxer defineix els serveis, xarxes i volums necessaris per a Odoo.

```yaml
# docker-compose.yml
version: '3.8'

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: odoo_server-web-1
    depends_on:
      - db
    ports:
      - "8069:8069"
      - "8072:8072"  # Longpolling per a notificacions en temps real
    volumes:
      - odoo-web-data:/var/lib/odoo
      - ./config_odoo:/etc/odoo:ro
      - ./dev_addons:/mnt/extra-addons:ro
      - ./log:/var/log/odoo
    environment:
      - HOST=db
      - USER=odoo
      - PASSWORD=myodoo
      - TZ=Europe/Madrid
      - PYTHONPATH=/mnt/extra-addons
    restart: unless-stopped
    command: >
      bash -c "
        odoo --config /etc/odoo/odoo.conf 
             --dev=all 
             --log-level=info
             --without-demo=all
      "
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8069/web/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  db:
    image: postgres:15
    container_name: odoo_server-db-1
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_PASSWORD=myodoo
      - POSTGRES_USER=odoo
      - PGDATA=/var/lib/postgresql/data/pgdata
      - TZ=Europe/Madrid
    volumes:
      - odoo-db-data:/var/lib/postgresql/data/pgdata
    restart: unless-stopped
    ports:
      - "5432:5432"  # Només per a desenvolupament - eliminar en producció
    command: >
      postgres -c max_connections=200
               -c shared_buffers=256MB
               -c effective_cache_size=1GB
               -c work_mem=32MB
               -c maintenance_work_mem=128MB
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U odoo"]
      interval: 30s
      timeout: 5s
      retries: 5

volumes:
  odoo-web-data:
    driver: local
  odoo-db-data:
    driver: local

networks:
  default:
    name: odoo_network
```

**Explicació dels components principals:**

**Servei web (Odoo):**
- `depends_on`: Assegura que PostgreSQL s'iniciï abans d'Odoo
- `ports`: Exposició de ports (8069 web, 8072 longpolling)
- `volumes`: Muntatge de dades persistents i configuració
- `healthcheck`: Verificació automàtica de l'estat del servei

**Servei db (PostgreSQL):**
- `image: postgres:15`: Versió específica i estable
- `command`: Paràmetres d'optimització específics per a Odoo
- `PGDATA`: Ubicació personalitzada de les dades

### Dockerfile personalitzat

El Dockerfile permet personalitzar la imatge d'Odoo amb les nostres necessitats específiques:

```dockerfile
# Dockerfile
FROM odoo:16.0

# Metadades
LABEL maintainer="your-email@company.com"
LABEL description="Odoo 16 personalitzat amb mòduls específics"
LABEL version="1.0"

# Canviar a usuari root per instal·lacions
USER root

# Variables d'entorn
ENV ODOO_VERSION=16.0
ENV ODOO_USER=odoo
ENV ODOO_EXTRA_ADDONS=/mnt/extra-addons

# Actualitzar sistema i instal·lar dependències addicionals
RUN apt-get update && apt-get install -y \
    # Eines de desenvolupament
    vim \
    git \
    curl \
    wget \
    # Biblioteques Python addicionals
    python3-dev \
    build-essential \
    # Neteja
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Actualitzar pip i dependències Python
RUN pip3 install --upgrade pip setuptools wheel

# Instal·lar biblioteques Python addicionals
RUN pip3 install \
    # Compatibilitat i estabilitat
    jinja2==3.1.2 \
    markupsafe==2.1.1 \
    # Biblioteques per a funcionalitats extenses
    requests \
    pandas \
    openpyxl \
    xlsxwriter \
    # Desenvolupament i debugging
    ipython \
    pudb

# Crear directoris necessaris
RUN mkdir -p /var/log/odoo \
    && mkdir -p /mnt/extra-addons \
    && chown -R odoo:odoo /var/log/odoo \
    && chown -R odoo:odoo /mnt/extra-addons

# Crear fitxer de log
RUN touch /var/log/odoo/odoo.log \
    && chown odoo:odoo /var/log/odoo/odoo.log

# Tornar a usuari odoo per seguretat
USER odoo

# Establir directori de treball
WORKDIR /usr/lib/python3/dist-packages/odoo

# Comando per defecte
CMD ["odoo"]
```

### Configuració d'Odoo

El fitxer de configuració d'Odoo adaptat per a Docker:

```ini
# config_odoo/odoo.conf
[options]
# Configuració de base de dades
db_host = db
db_port = 5432
db_user = odoo
db_password = myodoo
db_maxconn = 64

# Configuració d'aplicació
admin_passwd = SuperAdminPassword2024!
xmlrpc_port = 8069
xmlrpc_interface = 0.0.0.0
longpolling_port = 8072
proxy_mode = True

# Rutes de mòduls i dades
addons_path = /usr/lib/python3/dist-packages/odoo/addons,/mnt/extra-addons
data_dir = /var/lib/odoo

# Configuració de logging
logfile = /var/log/odoo/odoo.log
log_level = info
log_handler = :INFO
logrotate = True

# Configuració de rendiment
workers = 0  # Single-threaded per desenvolupament
max_cron_threads = 2
limit_memory_hard = 2684354560  # 2.5GB
limit_memory_soft = 2147483648  # 2GB
limit_request = 8192
limit_time_cpu = 600
limit_time_real = 1200

# Configuració de seguretat
list_db = True  # False en producció
db_template = template0
without_demo = True

# Configuració específica per a Docker
server_wide_modules = base,web
```

**Diferències clau per a Docker:**

- `db_host = db`: Nom del servei definit en docker-compose.yml
- `xmlrpc_interface = 0.0.0.0`: Permet connexions externes al contenidor
- `proxy_mode = True`: Preparació per a reverse proxy

## Desplegament automatitzat

### Script de desplegament complet

:::{admonition} 📥 Script de desplegament disponible
:class: note
**Pots descarregar l'script complet de desplegament:**

**[deploy-odoo-docker.sh](../../../scripts/deploy-odoo-docker.sh)**: Script automatitzat que gestiona tot el procés de desplegament en tres fases:


1. **Fase 1**: Configuració inicial del projecte
2. **Fase 2**: Descàrrega de mòduls i desplegament dels contenidors
3. **Fase 3**: Configuració i instal·lació de mòduls personalitzats

L'script inclou:
- Verificació de prerequisits
- Gestió d'errors amb neteja automàtica
- Logging detallat amb colors
- Control de fases per evitar duplicacions
- Verificació final del desplegament
  
**Instal·lació:**
```bash
# Copiar script de desplegament
cp docs/scripts/deploy-odoo-docker.sh ~/
chmod +x ~/deploy-odoo-docker.sh
```
:::

Per executar el desplegament:

```bash
# Executar el desplegament complet
./deploy-odoo-docker.sh
```

L'script mostrarà una sortida similar a:

```
🚀 Iniciant desplegament automatitzat d'Odoo amb Docker
✅ Prerequisits verificats
🏗️  Fase 1: Configuració inicial del projecte
📦 Fase 2: Descàrrega de mòduls i desplegament
🔧 Fase 3: Configuració de mòduls
🎉 Desplegament d'Odoo completat correctament!
```


:::{admonition} 📥 Scripts de verificació disponibles
:class: note
Pots descarregar els següents scripts per verificar la instal·lació:

- **[test-docker-installation.sh](../../../scripts/test-docker-installation.sh)**: Verificació completa de Docker
- **[diagnostic.sh](../../../scripts/diagnostic.sh)**: Diagnòstic del sistema Docker
- **[monitor.sh](../../../scripts/monitor.sh)**: Monitoratge en temps real

Aquests scripts et ajudaran a verificar que tot funciona correctament abans de continuar.

**Instal·lació dels scripts:**
```bash
# Crear directoris en el projecte
mkdir -p ~/odoo_server/scripts
mkdir -p ~/odoo_server/backups/scripts

# Copiar scripts des de la documentació
cp test-docker-installation.sh ~/odoo_server/scripts/
cp diagnostic.sh ~/odoo_server/scripts/
cp monitor.sh ~/odoo_server/scripts/

# Fer-los executables
chmod +x ~/odoo_server/scripts/*.sh
```
:::

## Gestió operativa

### Operacions bàsiques

Aquestes són les operacions més habituals per gestionar l'entorn Docker d'Odoo:

```bash
# Iniciar els serveis
docker compose up -d

# Aturar els serveis
docker compose down

# Reiniciar un servei específic
docker compose restart web

# Veure l'estat dels contenidors
docker compose ps

# Seguir logs en temps real
docker compose logs -f web

# Accedir al shell del contenidor
docker compose exec web bash

# Executar ordres d'Odoo
docker compose exec web odoo shell -d nom_base_dades
```

### Monitoratge del sistema

```bash
# Monitoratge de recursos dels contenidors
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

# Exemple de sortida:
CONTAINER ID   NAME                CPU %     MEM USAGE / LIMIT    MEM %     NET I/O         
aa9ae22cf873   odoo_server-web-1   0.05%     412.2MiB / 5.74GiB   7.01%     405MB / 465MB   
891dd38f6e33   odoo_server-db-1    0.04%     201.2MiB / 5.74GiB   3.42%     304MB / 402MB   
```

**Interpretació de les mètriques:**
- **CPU**: 0.05% indica sistema en repòs; >50% pot indicar sobrecàrrega
- **Memory**: Odoo sol usar 1.5-2x més RAM que PostgreSQL
- **Network I/O**: Útil per detectar pics d'activitat

### Backup i restauració

:::{admonition} 📥 Scripts de backup disponibles
:class: note
Pots descarregar els scripts de backup:

- **[backup-docker.sh](../../../scripts/backup-docker.sh)**: Backup complet de base de dades, volums i configuració
- **[restore-docker.sh](../../../scripts/restore-docker.sh)**: Restauració des de backups anteriors

Aquests scripts gestionen automàticament:
- Backup de base de dades PostgreSQL
- Backup de volums Docker
- Backup de configuració i mòduls personalitzats
- Compressió i organització per dates
  

**Instal·lació:**
```bash
# Copiar scripts de backup
cp backup-docker.sh ~/odoo_server/backups/scripts/
cp restore-docker.sh ~/odoo_server/backups/scripts/
chmod +x ~/odoo_server/backups/scripts/*.sh
```
:::

Operacions bàsiques de backup:

```bash
# Backup de base de dades
docker compose exec -T db pg_dump -U odoo postgres > backup_$(date +%Y%m%d).sql

# Backup de volums
docker run --rm \
  -v odoo_server_odoo-web-data:/data \
  -v $PWD:/backup \
  alpine tar czf /backup/volumes_$(date +%Y%m%d).tar.gz -C /data .
```

## Configuració avançada

### Entorn de producció

Per a entorns de producció, necessitem configuracions adicionals:

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  web:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G
      restart_policy:
        condition: on-failure
        delay: 10s
        max_attempts: 3
    environment:
      - ODOO_DEV=False
    # Eliminar port 5432 de db per seguretat
    
  db:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
    # Eliminar exposició del port 5432
```

### Desenvolupament local

Per a desenvolupament, podem optimitzar l'entorn:

```yaml
# docker-compose.dev.yml
version: '3.8'

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile.dev
    volumes:
      - ./dev_addons:/mnt/extra-addons
      - ./config_odoo:/etc/odoo
      - ./log:/var/log/odoo
    environment:
      - ODOO_DEV=True
    command: odoo --dev=all --log-level=debug
```

## Resolució de problemes

### Problemes comuns

**🔧 Contenidor no s'inicia:**

```bash
# Verificar logs detallats
docker compose logs web

# Verificar configuració
docker compose config

# Forçar rebuild
docker compose build --no-cache web
docker compose up -d
```

**🔧 Problemes de connectivitat:**

```bash
# Verificar xarxes Docker
docker network ls
docker network inspect odoo_network

# Test de connectivitat entre contenidors
docker compose exec web ping db
docker compose exec web nc -zv db 5432
```

**🔧 Problemes de rendiment:**

```bash
# Verificar recursos disponibles
docker stats
free -h
df -h

# Optimitzar base de dades
docker compose exec db psql -U odoo -c "VACUUM ANALYZE;"
```

### Debugging avançat

```bash
# Accedir al contenidor per debugging
docker compose exec web bash

# Iniciar shell d'Odoo per testing
docker compose exec web odoo shell -d nom_base_dades

# Executar tests específics
docker compose exec web odoo -i nom_modul --test-enable --stop-after-init
```

## Referències avançades

:::{admonition} 📖 Documentació ampliada
:class: note
Per a configuracions més avançades, consulta aquests documents complementaris:

**[Annex B: Operacions habituals amb Docker per a Odoo](Annexos/Docker_Operations.md)**
- Gestió avançada de contenidors i serveis
- Scripts d'automatització professionals
- Monitoratge de rendiment detallat
- Gestió de repositoris Git i mòduls

**[Annex C: Configuració avançada i producció d'Odoo](Annexos/Configuracio_Avancada.md)**
- Seguretat multicapa (firewall, SSL/TLS, aplicació)
- Optimització de PostgreSQL i Odoo per a producció
- Monitoratge professional amb mètriques i alertes
- Estratègies de backup robustes
- Pipelines de desplegament continu (CI/CD)
:::

## Conclusions

### ✅ Avantatges aconseguits

El desplegament d'Odoo amb Docker proporciona:

- **Desplegament ràpid**: De 4 hores a 30 minuts
- **Portabilitat completa**: Funciona igual en qualsevol entorn
- **Escalabilitat fàcil**: Replicació i load balancing simplificats
- **Manteniment automatitzat**: Scripts per a totes les operacions
- **Desenvolupament eficient**: Entorns múltiples i aïllats

### 📚 Coneixements adquirits

Durant aquest procés has après:

- Conceptes fonamentals de Docker i contenidors
- Orquestració amb Docker Compose
- Gestió de volums i xarxes Docker
- Estratègies de monitoratge i debugging
- Automatització de desplegaments
- Configuració per a entorns de producció

### 🚀 Pròxims passos en un entorn real

1. **Implementar els annexos** per operacions avançades i producció
2. **Configurar CI/CD** per desplegaments automatitzats
3. **Establir monitoratge** amb alertes professionals
4. **Configurar backup automatitzat** amb programació
5. **Implementar SSL/TLS** per a connexions segures

:::{admonition} 📖 Aprofundiment en CI/CD
:class: note
Per comprendre en detall què és CI/CD i com implementar-lo amb Odoo, consulta:

**[Annex D: Integració i Desplegament Continu (CI/CD)](Annexos/Annex_CICD.md)**

Aquest annex cobreix:
- Conceptes fonamentals de CI/CD explicats de manera accessible
- Comparatives entre processos manuals i automatitzats
- Exemples pràctics amb GitHub Actions i GitLab CI
- Scripts complets per implementar pipelines d'Odoo
- Estratègies avançades (Blue-Green, Canary deployments)
- Cases d'estudi reals amb mètriques de ROI
:::

Aquesta metodologia amb Docker et proporciona una base sòlida per desenvolupar, provar i desplegar sistemes Odoo professionals de manera eficient i escalable. 🎯

### 🔗 Recursos addicionals

- **[Documentació oficial de Docker](https://docs.docker.com/)**
- **[Docker Compose reference](https://docs.docker.com/compose/compose-file/)**
- **[Odoo Docker Hub](https://hub.docker.com/_/odoo)**
- **[Best practices per a Dockerfile](https://docs.docker.com/develop/dev-best-practices/)**

Amb aquesta configuració professional de Docker, tens una plataforma robusta per qualsevol projecte Odoo! 🐳✨
