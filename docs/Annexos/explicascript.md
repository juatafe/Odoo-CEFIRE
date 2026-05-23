# Exercici pràctic: Automatització de la instal·lació d’Odoo amb Docker

## Introducció

Quan desenvolupem projectes amb **Odoo** és fonamental **mantindre el control sobre el procés d’instal·lació, configuració i actualització**.  Fer-ho manualment cada vegada és lent i propens a errors.  La millor pràctica en entorns professionals és **automatitzar les tasques repetitives** mitjançant scripts.

Ara que ja saps com instal·lar Odoo tant en local com dins de Docker, podem donar un pas més:  
crear un **script Bash** que instal·le totes les dependències, genere els fitxers de configuració i arranque el servidor completament configurat amb només una ordre.





:::{tip} Truc
<b>Descarrega l'script complet d'automatització:</b><br>
<a href="https://github.com/juatafe/Odoo-CEFIRE/blob/amazon/scriptsetupOdoo.sh" style="text-align: left;">https://github.com/juatafe/Odoo-CEFIRE/blob/amazon/scriptsetupOdoo.sh</a>
:::


**Abans d'executar l’script**, recorda modificar el nom del repositori personalitzat
que es clona automàticament a la línia:

```bash
CUSTOM_REPO="odoo-cpa-addons"
git clone https://github.com/juatafe/$CUSTOM_REPO.git
```
Si tens els teus propis mòduls, substitueix:

```bash
juatafe/odoo-cpa-addons
```

pel teu repositori, per exemple:

 ```bash
 githubuser/odoo-myaddons
 ```

 També pots crear el teu repositori buit a GitHub abans d'executar l’script perquè es clone
 automàticament dins de `dev_addons/`.


## Objectiu

Aprendre a comprendre i executar un **script Bash d’automatització** que:

- Instal·la Docker i les seues dependències.
- Crea l’estructura del projecte Odoo (carpetes, fitxers i configuració).
- Construeix i arranca els contenidors (Odoo, PostgreSQL i MailHog).
- Crea la base de dades i instal·la mòduls automàticament.
- Controla l’estat de cada fase mitjançant fitxers de senyal (`.phase1_docker_done`, etc.).


## Vista general de l’script

L’script complet es pot dividir en tres fases principals:  
  - Instal·lació de Docker i dependències.  
  - Creació de l’estructura d’Odoo i arrancada dels contenidors.  
  - Instal·lació de mòduls i configuració final.

A continuació veurem el codi i explicarem cada secció pas a pas.


## Capçalera i configuració inicial

```bash
#!/bin/bash
set -e
```

- `#!/bin/bash` indica l’intèrpret de comandes que s’utilitzarà per executar l’script.  
- `set -e` fa que l’script s’ature automàticament si es produeix algun error.

Això és important per a evitar que continue un procés d’instal·lació si alguna fase ha fallat.


## Definició de variables

```bash
PROJECT_DIR=~/odoo_server
ODOO_PORT=8069
ODOO_DB_NAME=cpa
ODOO_DB_USER=admin
ODOO_DB_PASS='Pa$$w0rd'
ODOO_MASTER_PASS='Pa$$w0rd'
ODOO_PG_PORT=5432
ADDONS_DIR=$PROJECT_DIR/dev_addons
```

Aquestes variables determinen on es crearà el projecte i quins ports, noms i contrasenyes es faran servir.  Per exemple, `PROJECT_DIR` defineix el directori base (`~/odoo_server`) i `ODOO_PORT` el port pel qual accedirem a Odoo. També hi ha variables per a la base de dades (`ODOO_DB_NAME`, `ODOO_PG_PORT`) i les carpetes on es guardaran els *addons* o mòduls personalitzats.


## Fitxers de control i mòduls per defecte

```bash
PHASE1_FLAG="$PROJECT_DIR/.phase1_docker_done"
PHASE2_FLAG="$PROJECT_DIR/.phase2_odoo_started"
INSTALLED_MODULES_FILE="$PROJECT_DIR/.installed_modules"

DEFAULT_MODULES=(web portal contacts sale account event website website_event website_event_sale payment point_of_sale pos_sale pos_hr pos_restaurant crm l10n_es)
CUSTOM_REPO="odoo-cpa-addons"
```

Aquests fitxers de control serveixen per a indicar quina fase s’ha completat.  L’script és **idempotent**: si el tornes a executar, només farà les parts pendents.  També es defineix una llista de mòduls base i el repositori personalitzat (`odoo-cpa-addons`).


## Fase 1 — Instal·lació de Docker i dependències

Aquesta fase comprova si Docker està instal·lat. Si no, el configura completament.

```bash
if [ ! -f "$PHASE1_FLAG" ]; then
    echo "🔧 [FASE 1] Instal·lant Docker i dependències..."
    sudo apt -y remove docker docker-engine docker.io containerd runc || true
    sudo apt update
    sudo apt install -y ca-certificates curl gnupg lsb-release python3 python3-pip
```

Primer desinstal·la versions antigues i instal·la paquets essencials per a treballar amb Docker. Després afegeix el repositori oficial de Docker si encara no està al sistema:

```bash
    if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
    fi
```

I finalment instal·la Docker i `docker-compose-plugin`, habilita el servei i afegeix l’usuari al grup `docker` per no haver d’usar `sudo`. Al final crea el fitxer `.phase1_docker_done` per indicar que la fase ha acabat correctament.

```text
Docker instal·lat correctament.
Reinicia la màquina perquè s'apliquen els permisos.
```


## Fase 2 — Creació de l’estructura i configuració d’Odoo

Quan Docker ja està llest, l’script passa a preparar l’entorn Odoo.

### Creació de carpetes i fitxers

```bash
mkdir -p "$PROJECT_DIR"/{config_odoo,dev_addons,log}
cd "$PROJECT_DIR"
```

Això crea tres carpetes bàsiques: configuració, mòduls personalitzats i logs. A continuació genera automàticament el fitxer `config_odoo/odoo.conf`:

```bash
cat > config_odoo/odoo.conf <<EOF
[options]
addons_path = /mnt/extra-addons
data_dir = /var/lib/odoo
db_host = db
db_user = odoo
admin_passwd = $ODOO_MASTER_PASS
xmlrpc_port = $ODOO_PORT
EOF
```

Aquest fitxer conté la configuració bàsica d’Odoo (ruta dels addons, base de dades i ports).

### Dockerfile personalitzat

```bash
cat > Dockerfile <<'EOF'
FROM odoo:16.0
USER root
RUN pip install requests pandas
COPY ./dev_addons/* /mnt/extra-addons/
USER odoo
WORKDIR /mnt/extra-addons
EOF
```

Este `Dockerfile` crea una imatge pròpia a partir de `odoo:16.0` i instal·la llibreries addicionals com `requests` o `pandas`.

### Fitxer `docker-compose.yml`

```bash
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
      - ./config_odoo:/etc/odoo
      - ./dev_addons:/mnt/extra-addons
      - ./log:/var/log/odoo
  db:
    image: postgres:latest
    environment:
      - POSTGRES_USER=odoo
      - POSTGRES_PASSWORD=myodoo
  mailhog:
    image: mailhog/mailhog:latest
    ports:
      - "8025:8025"
      - "1025:1025"
EOF
```

Aquest fitxer defineix tres contenidors: `web` (Odoo), `db` (PostgreSQL) i `mailhog` (simulador SMTP). Després es construeix i s’inicia tot amb:

```bash
docker compose build
docker compose up -d
```

Quan tot està funcionant, crea la base de dades inicial i assigna la contrasenya a l’administrador.



## Fase 3 — Instal·lació de mòduls

Ara que el servidor Odoo està funcionant, s’instal·len els mòduls automàticament.

```bash
CUSTOM_MODULES=()
if [ -d "$ADDONS_DIR/$CUSTOM_REPO" ]; then
    for dir in "$ADDONS_DIR/$CUSTOM_REPO"/*/ ; do
        if [ -f "$dir/__manifest__.py" ]; then
            module_name=$(basename "$dir")
            CUSTOM_MODULES+=("$module_name")
        fi
    done
fi
```

Aquesta part busca tots els mòduls dins del repositori personalitzat i els afegeix a la llista. Després els instal·la un per un:

```bash
for modul in "${DEFAULT_MODULES[@]}" "${CUSTOM_MODULES[@]}"; do
    docker compose exec web odoo -i "$modul" -d "$ODOO_DB_NAME" --without-demo=all --stop-after-init
    echo " Instal·lat: $modul"
done
```

Al final, recompila els *assets* d’Odoo i reinicia el contenidor:

```bash
docker compose exec web odoo -d "$ODOO_DB_NAME" -i web_asset --stop-after-init
docker compose restart web
```


## Execució

Guarda l’script amb el nom `setup_odoo.sh`, dona-li permisos i executa’l:

```bash
chmod +x setup_odoo.sh
./setup_odoo.sh
```

Després de la primera fase reinicia l’ordinador(la màquina virtual) i torna a executar-lo per continuar amb la següent.


## Resultat final

Quan el procés acabe, tindràs:

- **Odoo:** [http://localhost:8069](http://localhost:8069)
- **MailHog:** [http://localhost:8025](http://localhost:8025)
- **Usuari:** `admin`
- **Contrasenya:** `Pa$$w0rd`
- **Base de dades:** `cpa`

Tot queda automatitzat i preparat per treballar.


## Consell final

Versiona l’script amb `git` i comenta cada canvi. Pots ampliar-lo per afegir:

- Fase de còpia de seguretat i restauració.
- Desplegament remot automàtic.
- Còpia de mòduls personalitzats des d’altres repositoris.

> Amb aquest procés, passes de fer instal·lacions manuals a **desplegar Odoo completament automatitzat** amb Docker i Bash.
