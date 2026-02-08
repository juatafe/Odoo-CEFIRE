# ✍️ Pràctica 2: Desplegament d'Odoo amb Docker Compose

**Objectiu:** Aprendre a desplegar **Odoo 16** utilitzant Docker i Docker Compose de manera pràctica i guiada.  

**Durada estimada:** 2-3 hores  
**Dificultat:** Intermèdia  

---

## Introducció
  En la pràctica anterior has après a instal·lar Odoo 16 manualment sobre un servidor Ubuntu, configurant PostgreSQL, usuaris i serveis.
  
  En aquesta segona pràctica explorarem una alternativa molt utilitzada en entorns professionals: Docker Compose, que permet desplegar aplicacions multi-contenidor d’una forma ràpida i portable.
  
  A més de comparar els dos mètodes, aprendràs a gestionar contenidors, revisar logs i preparar scripts de monitoratge.

---

## Què aprendràs
✅ Instal·lar i configurar Docker i Docker Compose  
✅ Crear un projecte Odoo amb Docker Compose  
✅ Gestionar contenidors (iniciar, aturar, monitorar)  
✅ Personalitzar la configuració d'Odoo  
✅ Comparar avantatges i inconvenients respecte a la instal·lació manual

---

## Requisits previs

Per mantindre la coherència amb la Pràctica 1, treballarem sobre el mateix entorn:
  - Màquina virtual Ubuntu Server 24.04 LTS creada a la Pràctica 1.
  - Torna a un estat net abans d’instal·lar Odoo manualment:
    - Recupera una instantània de VirtualBox guardada després de la instal·lació bàsica d’Ubuntu, abans de configurar Odoo.
    - O bé, fes una clonació de la màquina virtual i treballa sobre la còpia per a no perdre la configuració de la Pràctica 1.

Altres requisits tècnics:
  - Accés com a administrador (sudo) a la VM
  - 4 GB de RAM lliures i 10 GB d’espai en disc
  - Connexió a Internet activa

---

# Fase 1: Preparació de l'entorn

## Pas 1: Instal·lació de Docker
```bash
# 1. Actualitzar el sistema
sudo apt update
sudo apt upgrade -y

# 2. Instal·lar dependències
sudo apt install -y ca-certificates curl gnupg lsb-release

# 3. Afegir la clau GPG oficial de Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 4. Afegir el repositori de Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. Actualitzar la llista de paquets
sudo apt update

# 6. Instal·lar Docker
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

## Pas 2: Configurar permisos d'usuari
```bash
# Afegir el teu usuari al grup docker
sudo usermod -aG docker $USER

# Aplicar els canvis (o reinicia la sessió)
newgrp docker

# Verificar que funciona
docker --version
docker compose version
```

**Resultat esperat:**
```text
Docker version 24.0.x, build...
Docker Compose version v2.x.x
```

## Pas 3: Crear l'estructura del projecte
```bash
# Crear directori del projecte
mkdir ~/odoo-docker
cd ~/odoo-docker

# Crear estructura de directoris
mkdir -p {config,addons,logs,backups}

# Verificar l'estructura
ls -la
```

**Resultat esperat:**
```text
addons/
backups/
config/
logs/
```

---

# Fase 2: Configuració de Docker Compose

## Pas 4: Crear el fitxer *docker-compose.yml*
```bash
nano docker-compose.yml
```

```yaml
version: '3.8'

services:
  # Servei de base de dades PostgreSQL
  db:
    image: postgres:15
    container_name: odoo_postgres
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_USER=odoo
      - POSTGRES_PASSWORD=odoo123
      - PGDATA=/var/lib/postgresql/data/pgdata
    volumes:
      - odoo-db-data:/var/lib/postgresql/data/pgdata
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U odoo"]
      interval: 30s
      timeout: 5s
      retries: 3

  # Servei d'aplicació Odoo
  web:
    image: odoo:16.0
    container_name: odoo_app
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "8069:8069"
    environment:
      - HOST=db
      - USER=odoo
      - PASSWORD=odoo123
    volumes:
      - odoo-web-data:/var/lib/odoo
      - ./config:/etc/odoo
      - ./addons:/mnt/extra-addons
      - ./logs:/var/log/odoo
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8069/web/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

# Volums per persistir dades
volumes:
  odoo-web-data:
  odoo-db-data:

# Xarxa
networks:
  default:
    name: odoo_network
```

---

## Pas 5: Configuració personalitzada d'Odoo
```bash
nano config/odoo.conf
```

```ini
[options]
db_host = db
db_port = 5432
db_user = odoo
db_password = odoo123
db_maxconn = 64

xmlrpc_port = 8069
xmlrpc_interface = 0.0.0.0
proxy_mode = True

addons_path = /usr/lib/python3/dist-packages/odoo/addons,/mnt/extra-addons
data_dir = /var/lib/odoo

logfile = /var/log/odoo/odoo.log
log_level = info
logrotate = True

admin_passwd = admin123
list_db = True

workers = 0
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_time_cpu = 600
limit_time_real = 1200

without_demo = False
```

---

# Fase 3: Desplegament i verificació

## Pas 6: Iniciar els serveis
```bash
docker compose config
docker compose pull
docker compose up -d
```

## Pas 7: Verificar que tot funciona
```bash
docker compose ps
```

**Resultat esperat:**
```
NAME            IMAGE         STATUS                   PORTS
odoo_app        odoo:16.0     Up (healthy)             0.0.0.0:8069->8069/tcp
odoo_postgres   postgres:15   Up (healthy)             5432/tcp
```

## Pas 8: Accedir a Odoo
Obre el navegador i ves a:  
👉 http://localhost:8069

---

# Fase 4: Gestió operativa

## Pas 9: Operacions bàsiques
```bash
docker compose down         # Aturar serveis
docker compose up -d        # Iniciar serveis
docker compose restart web  # Reiniciar Odoo
docker compose logs web     # Veure logs
docker compose exec web bash # Accedir al contenidor
```

## Pas 10: Monitoratge del sistema
```bash
nano scripts/monitor.sh
```

```bash
#!/bin/bash
echo "=== ESTAT DELS CONTENIDORS ==="
docker compose ps

echo ""
echo "=== ÚS DE RECURSOS ==="
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

echo ""
echo "=== ESPAI EN DISC ==="
docker system df

echo ""
echo "=== CONNEXIONS ACTIVES ==="
curl -s http://localhost:8069/web/health && echo " - Odoo OK" || echo " - Odoo ERROR"
```

Fer executable:
```bash
chmod +x scripts/monitor.sh
./scripts/monitor.sh
```

---

# Fase 6: Resolució de problemes

🔧 **Problema 1: Els contenidors no s'inicien**
```bash
docker compose logs
docker compose down
docker compose up -d --force-recreate
```

🔧 **Problema 2: No puc accedir a http://localhost:8069**
```bash
sudo netstat -tlnp | grep 8069
docker compose ps web
docker compose logs web
```

🔧 **Problema 3: Error de memòria**
```bash
docker stats
docker system prune -f
```

---

# Entrega de la pràctica

**Has de lliurar:**

📸 Captures de pantalla:
- Odoo funcionant al navegador
- Output de `docker compose ps`
- Dashboard d'Odoo amb alguna dada creada

📂 Fitxers de configuració:
- `docker-compose.yml`
- `config/odoo.conf`

📑 Informe breu (1-2 pàgines) amb:
- Problemes trobats i solucions
- Avantatges de Docker vs instal·lació tradicional
- Propostes de millora per a producció

**Estructura de carpetes:**
```
Practica2_NomCognom/
├── captures/
│   ├── odoo_funcionant.png
│   ├── docker_ps.png
│   └── dashboard_odoo.png
├── configuracio/
│   ├── docker-compose.yml
│   └── odoo.conf
└── informe.pdf
```

---

# Criteris d'avaluació

| Criteri                  | Puntuació |
|---------------------------|-----------|
| Desplegament funcional    | 40%       |
| Configuració correcta     | 25%       |
| Scripts operatius         | 20%       |
| Documentació i captures   | 15%       |

---

# Recursos addicionals

```bash
docker images        # Veure imatges
docker image prune   # Netejar imatges
docker volume ls     # Veure volums
docker system info   # Informació Docker
docker system prune -a # Neteja completa
```

📚 **Referències:**
- [Docker Compose reference](https://docs.docker.com/compose/)
- [Odoo Docker documentation](https://hub.docker.com/_/odoo)

---

🎉 **Felicitats! Has completat la Pràctica 2**
