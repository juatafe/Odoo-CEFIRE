# ✍️ Pràctica 1  
## Instal·lació i configuració d'Odoo

### Introducció

En aquesta pràctica aprendràs a instal·lar i configurar **Odoo**, un dels sistemes de gestió empresarial (ERP) més populars i utilitzats actualment. Odoo és una plataforma modular que permet gestionar diferents aspectes d'una empresa: vendes, compres, inventari, comptabilitat, recursos humans, etc.

Com a futur tècnic superior en Desenvolupament d'Aplicacions Multiplataforma, és important que coneguis aquestes eines, ja que moltes empreses les utilitzen per gestionar els seus processos de negoci. A més, treballaràs amb tecnologies com Linux, bases de dades PostgreSQL i aplicacions web, competències clau en el teu perfil professional.

:::{admonition} Objectius d'aprenentatge
:class: note
Al final d'aquesta pràctica hauràs après a:

- **Configurar una màquina virtual** amb Ubuntu Server 24.04 LTS
- **Instal·lar i configurar un sistema ERP** (Odoo 16) en un entorn Linux
- **Treballar amb la línia d'ordres** de Linux per a tasques d'administració
- **Configurar xarxes virtuals** per permetre l'accés remot a serveis
- **Documentar processos tècnics** de manera professional
- **Verificar el funcionament** d'un servei web empresarial

Aquests coneixements són fonamentals per treballar en entorns empresarials reals.
:::

:::{admonition} Temps estimat i modalitat
:class: tip
- **Temps de realització**: 4-6 hores (distribuïdes en diverses sessions)
- **Modalitat**: Semipresencial - pots fer-ho a casa i consultar dubtes a classe
- **Suport**: Documentació disponible 24/7, dubtes resolts a les sessions presencials
:::

:::{admonition} Requisits tècnics
:class: important
**Maquinari mínim:**
- Ordinador amb 8 GB de RAM (mínim 4 GB disponibles per la VM)
- 25 GB d'espai lliure en disc dur
- Processador amb suport per virtualització (Intel VT-x o AMD-V)

**Programari necessari:**
- VirtualBox 7.x o superior (gratuït)
- ISO d'Ubuntu Server 24.04 LTS (descarrega gratuïta)
- Connexió a Internet estable

**Coneixements previs:**
- Conceptes bàsics de sistemes operatius
- Nocions elementals de xarxes (IP, ports)
- Familiaritat amb la instal·lació de programari
:::

## Fase 1: Preparació de l'entorn de treball

Abans de començar amb la instal·lació, necessitem preparar l'entorn de virtualització i assegurar-nos que tenim tot el necessari.

### Descàrrega del programari necessari

:::{admonition} Ubuntu Server 24.04 LTS
:class: tip
**Què és?** Ubuntu Server és la versió de Ubuntu optimitzada per a servidors, sense interfície gràfica i centrada en estabilitat i rendiment.

**Descàrrega:**
- Web oficial: https://ubuntu.com/download/server
- Tria la versió 24.04 LTS (Long Term Support)
- Fitxer: ubuntu-24.04.x-live-server-amd64.iso (aproximadament 1.4 GB)

**Per què LTS?** Les versions LTS tenen suport durant 5 anys, ideals per a entorns de producció.
:::

### Configuració inicial de VirtualBox

VirtualBox és un hipervisor gratuït que ens permet executar màquines virtuals. Anirem pas a pas segons el teu sistema operatiu.

#### Verificació de requisits del sistema

Abans d'instal·lar VirtualBox, comprova que el teu ordinador compleix els requisits:

:::{admonition} Verificació de la virtualització
:class: important
**Windows:**
1. Obri el Gestor de tasques (Ctrl+Shift+Esc)
2. Ves a la pestanya "Rendiment" → "CPU"
3. Comprova que apareix "Virtualització: Activada"

```{image} /_static/assets/img/Tema2/virtuHabi.PNG
:alt: Virtualització habilitada al Gestor de tasques de Windows
:width: 60%
:align: center
```

**Si està desactivada:**
- Reinicia l'ordinador
- Entra a la BIOS/UEFI (normalment F2, F12, Del durant l'arrencada)
- Busca "Virtualization Technology", "Intel VT-x" o "AMD-V"
- Activa-ho i guarda els canvis

**macOS/Linux:**
La virtualització normalment està activada per defecte.
:::

```{code-block} bash
# En Linux, pots verificar-ho amb:
grep -E "(vmx|svm)" /proc/cpuinfo
# Si apareixen resultats, la virtualització està disponible
```

#### Instal·lació de VirtualBox

**Tria el teu sistema operatiu:**

:::{admonition} Windows 
:class: tip
**Opció 1: Instal·lació amb winget (Windows 10/11)**
```{code-block} powershell
# Obri PowerShell com a administrador i executa:
winget install -e --id Oracle.VirtualBox
```

**Opció 2: Descàrrega manual**
1. Ves a https://www.virtualbox.org/wiki/Downloads
2. Clica "Windows hosts" per descarregar l'instal·lador
3. Executa el fitxer com a administrador
4. Segueix l'assistent (accepta tots els valors per defecte)

**Important:** Durant la instal·lació, accepta instal·lar els controladors de xarxa d'Oracle
:::

:::{admonition} macOS
:class: note
**Instal·lació amb Homebrew:**
```{code-block} bash
# Si no tens Homebrew:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Instal·la VirtualBox:
brew install --cask virtualbox
```

**Notes per a macOS:**
- Pot demanar autoritzar l'extensió a Preferències → Seguretat i Privadesa
- En Apple Silicon (M1/M2/M3), si tens problemes, prova UTM com a alternativa
:::

:::{admonition} Linux
:class: note
```{code-block} bash
# Ubuntu/Debian:
sudo apt update && sudo apt install -y virtualbox

# Fedora:
sudo dnf install VirtualBox

# Arch:
sudo pacman -S virtualbox
```
:::

## Fase 2: Creació i configuració de la màquina virtual

### Pas 1: Crear la nova VM

1. **Obri VirtualBox** i clica "Nova" (New)
2. **Configura els paràmetres:**
   - **Nom**: `Odoo-Server` (o el que preferisques)
   - **Tipus**: Linux
   - **Versió**: Ubuntu (64-bit)
3. **Clica "Següent"**

### Pas 2: Configurar la memòria RAM

:::{admonition} Recomanacions de RAM
:class: tip
- **Si tens 4 GB**: Assigna 1024 MB (1 GB) - mínim funcional
- **Si tens 8 GB**: Assigna 2048-4096 MB (2-4 GB) - recomanat
- **Si tens 16 GB**: Assigna 4096-6144 MB (4-6 GB) - òptim

**Regla d'or:** No assignis més del 75% de la RAM del teu ordinador
:::

### Pas 3: Crear el disc dur virtual

1. **Selecciona**: "Crea un disc dur virtual ara"
2. **Tipus**: VDI (VirtualBox Disk Image)
3. **Emmagatzematge**: "Assignat dinàmicament" 
4. **Mida**: 25 GB (mínim per a Odoo i el sistema)

### Pas 4: Configurar la xarxa (molt important)

Abans d'instal·lar Ubuntu, configurem la xarxa per poder accedir remotament:

1. **Selecciona la VM** → **Configuració** (Settings)
2. **Xarxa** → **Adapter 1**:
   - **Connectat a**: NAT
   - **Avançat** → **Port Forwarding**
   - **Afegeix aquestes regles:**

| Nom  | Protocol | Port Host | Port Guest |
|------|----------|-----------|------------|
| SSH  | TCP      | 2222      | 22         |
| Odoo | TCP      | 8069      | 8069       |

```{image} /_static/assets/img/Tema2/redericcionament.png
:alt: Configurar socket de connexió. La MV sempre la mateixa ip assignada per NAT.
:width: 60%
:align: center
```

:::{admonition} Què fa això?
:class: tip
- **SSH (port 2222 → 22)**: Permet connectar remotament per administrar el servidor
- **Odoo (port 8069 → 8069)**: Permet accedir a la interfície web d'Odoo des del teu navegador

Després podràs usar:
- `ssh -p 2222 usuari@localhost` per administrar
- `http://localhost:8069` per accedir a Odoo
:::

## Fase 3: Instal·lació d'Ubuntu Server 24.04

### Pas 1: Muntar la ISO i iniciar la VM

1. **A VirtualBox**, selecciona la VM i clica **Configuració**
2. **Emmagatzematge** → clica la icona del CD buit
3. **Trieu fitxer de disc** → selecciona la ISO d'Ubuntu Server descarregada
4. **Accepta** i **inicia la VM**

### Pas 2: Instal·lació d'Ubuntu Server

:::{admonition} Configuració d'idioma i teclat
:class: note
1. **Idioma**: Pots triar English (recomanat per compatibilitat) o Español
2. **Teclat**: Selecciona "Spanish" si tens teclat en espanyol
3. **Continua** amb les opcions per defecte fins arribar a la configuració de xarxa
:::

#### Configuració de xarxa

1. **Xarxa**: Deixa la configuració per defecte (DHCP)
2. **Proxy**: Deixa en blanc si no tens proxy
3. **Mirror d'Ubuntu**: Deixa el per defecte

#### Configuració del disc

1. **Emmagatzematge guiat**: Selecciona "Use an entire disk"
2. **Selecciona el disc virtual** creat anteriorment
3. **File system setup**: Revisa que està bé i continua

#### Configuració del perfil

:::{admonition} Dades del usuari (IMPORTANT - anota-ho!)
:class: warning
1. **Your name**: El teu nom real
2. **Your server's name**: `odoo-server` (o el que preferisques)
3. **Pick a username**: `estudiant` (o el que preferisques, però recorda'l!)
4. **Choose a password**: Una contrasenya segura (recorda-la!)

**Molt important:** Anota aquests datos! Els necessitaràs per connectar via SSH.
:::

#### Configuració SSH

1. **SSH Setup**: **MARCA** "Install OpenSSH server" ✓
2. **SSH keys**: Deixa en blanc de moment

#### Snaps i paquets addicionals

1. **Featured Server Snaps**: No seleccionis res, clica "Done"
2. **Espera** que es completi la instal·lació (pot trigar 10-15 minuts)

### Pas 3: Primer accés al sistema

1. Quan aparega "Installation complete!", **reinicia** la VM
2. **Retira la ISO**: Configuració → Emmagatzematge → Retira el disc
3. **Inicia la VM** i espera que aparega el prompt de login
4. **Fes login** amb l'usuari i contrasenya que has creat

:::{admonition} Primer comandament important
:class: tip
Un cop dins del sistema, executa:
```{code-block} bash
sudo apt update && sudo apt upgrade -y
```
Això actualitza el sistema amb les últimes correccions de seguretat. En acabar serà un bon moment per crear una snapshot de la MV.
:::

## Fase 4: Instal·lació d'Odoo 16

### Pas 1: Preparació del sistema

Primer instal·lem les dependències necessàries:

```{code-block} bash
# Actualitzar el sistema si no ho has fet ja
sudo apt update && sudo apt upgrade -y

# Instal·lar PostgreSQL (base de dades)
sudo apt install -y postgresql postgresql-contrib

# Instal·lar Python i dependències
sudo apt install -y python3 python3-pip python3-dev python3-venv
sudo apt install -y libxml2-dev libxslt1-dev libevent-dev libsasl2-dev libldap2-dev pkg-config libtiff5-dev libjpeg8-dev libopenjp2-7-dev zlib1g-dev libfreetype6-dev liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev net-tools

# Instal·lar dependències addicionals
sudo apt install -y build-essential wget git gdebi-core fontconfig libpq-dev
```

### Pas 2: Configurar PostgreSQL

```{code-block} bash
# Crear usuari PostgreSQL per Odoo
sudo -u postgres createuser -s odoo
sudo -u postgres createdb odoo

# Configurar contrasenya per l'usuari odoo (opcional però recomanat)
sudo -u postgres psql
# Dins de PostgreSQL:
ALTER USER odoo PASSWORD 'odoo_password';
\q
```

### Pas 3: Crear usuari del sistema per Odoo

```{code-block} bash
# Crear usuari del sistema
sudo adduser --system --home=/opt/odoo --group odoo
sudo passwd odoo
```

### Pas 4: Descarregar i instal·lar Odoo

```{code-block} bash
# Canviar a l'usuari odoo
sudo -u odoo -s

# Descarregar Odoo 16 des de GitHub
cd /opt/odoo
git clone https://www.github.com/odoo/odoo --depth 1 --branch 16.0 --single-branch odoo16

# Crear entorn virtual de Python
python3 -m venv odoo16-venv
source /opt/odoo/odoo16-venv/bin/activate

# Instal·lar dependències Python d'Odoo
pip install wheel PyPDF2 psycopg2-binary
pip install -r odoo16/requirements.txt

# Sortir de l'usuari odoo
exit
```

### Pas 5: Configurar Odoo

```{code-block} bash
# Crear directori de configuració
sudo mkdir /etc/odoo
sudo mkdir /var/log/odoo

# Crear fitxer de configuració
sudo nano /etc/odoo/odoo.conf
```

**Contingut del fitxer `/etc/odoo/odoo.conf`:**

```{code-block} ini
[options]
; This is the password that allows database operations:
admin_passwd = admin_password_change_me
db_host = localhost
db_port = 5432
db_user = odoo
db_password = odoo_password
logfile = /var/log/odoo/odoo.log
addons_path = /opt/odoo/odoo16/addons
xmlrpc_port = 8069
```

```{code-block} bash
# Assignar permisos adequats
sudo chown odoo:odoo /etc/odoo/odoo.conf
sudo chmod 640 /etc/odoo/odoo.conf
sudo chown odoo:odoo /var/log/odoo
```

### Pas 6: Crear servei systemd per Odoo

```{code-block} bash
sudo nano /etc/systemd/system/odoo.service
```

**Contingut del fitxer `/etc/systemd/system/odoo.service`:**

```{code-block} ini
[Unit]
Description=Odoo
Documentation=http://www.odoo.com
After=network.target postgresql.service

[Service]
Type=simple
SyslogIdentifier=odoo
PermissionsStartOnly=true
User=odoo
Group=odoo
ExecStart=/opt/odoo/odoo16-venv/bin/python /opt/odoo/odoo16/odoo-bin -c /etc/odoo/odoo.conf
StandardOutput=journal+console
KillMode=mixed

[Install]
WantedBy=multi-user.target
```

```{code-block} bash
# Habilitar i iniciar el servei
sudo systemctl daemon-reload
sudo systemctl enable odoo
sudo systemctl start odoo

# Verificar que funciona
sudo systemctl status odoo
```

## Fase 5: Verificació i proves

### Pas 1: Verificar que Odoo funciona

```{code-block} bash
# Reiniciar i comprovar que el servei està actiu
sudo systemctl status odoo

# Comprovar que escolta al port 8069
sudo netstat -tlnp | grep 8069

# Revisar els logs si hi ha problemes
sudo journalctl -u odoo -f
```

### Pas 2: Accedir a Odoo des del teu ordinador

1. **Obri el navegador** al teu ordinador (no la VM)
2. **Ves a**: `http://localhost:8069`
3. **Si tot va bé**, veuràs la pantalla de configuració d'Odoo

:::{admonition} Configuració inicial d'Odoo
:class: tip
1. **Master Password**: La que has posat a `/etc/odoo/odoo.conf` com `admin_passwd`
2. **Database Name**: `produccion` (o el nom que preferisques)
3. **Email**: El teu email
4. **Password**: Contrasenya per a l'administrador d'Odoo
5. **Demo data**: No marcar (per a dades reals)

Clica "Create database" i espera uns minuts.
:::

### Pas 3: Connexió SSH des del teu ordinador

```{code-block} bash
# Des del terminal del teu ordinador (no la VM):
ssh -p 2222 estudiant@localhost

# Si funciona, ja tens accés remot per administrar el servidor
```

## Fase 6: Documentació i lliurament

### Què has de documentar

Crea un document (Word, PDF o Markdown) que inclogui:

1. **Introducció**
   - Què és Odoo i per què és important
   - Objectius de la pràctica

2. **Instal·lació del sistema base**
   - Captures de pantalla de la configuració de VirtualBox
   - Captures del procés d'instal·lació d'Ubuntu Server
   - Configuració de xarxa realitzada

3. **Instal·lació d'Odoo**
   - Passos seguits per instal·lar PostgreSQL
   - Configuració de l'usuari i base de dades
   - Instal·lació d'Odoo i dependències

4. **Configuració**
   - Contingut dels fitxers de configuració creats
   - Configuració del servei systemd

5. **Verificació**
   - Captures de pantalla de:
     - Odoo funcionant al navegador
     - Estat del servei via SSH
     - Primera configuració d'Odoo

6. **Problemes i solucions**
   - Quins problemes has tingut?
   - Com els has resolt?

7. **Conclusions**
   - Què has après?
   - Aplicacions pràctiques d'aquest coneixement

### Criteris d'avaluació

| Criteri | Pes | Descripció |
|---------|-----|------------|
| **Instal·lació tècnica** | 40% | Odoo funciona correctament, accessible via web |
| **Documentació** | 30% | Document complet, clar i amb captures |
| **Configuració** | 20% | Configuració correcta de xarxa, usuaris i serveis |
| **Resolució de problemes** | 10% | Capacitat per identificar i resoldre incidències |

### Format de lliurament

- **Fitxer**: PDF amb el nom `Cognom_Nom_Practica1_Odoo.pdf`
- **Termini**: [Consulta la data a Aules]
- **Com lliurar**: Aules, secció de la pràctica

:::{admonition} Consells per a la documentació
:class: tip
- **Captures nítides**: Usa Alt+Impr Pant per capturar finestres específiques
- **Explica els passos**: No només digues "he fet això", explica per què
- **Inclou errors**: Els errors i com els has resolt són molt valuosos
- **Revisa abans de lliurar**: Comprova que tot s'entén bé
:::

:::{admonition} Recursos addicionals
:class: note
- **Documentació oficial d'Odoo**: https://www.odoo.com/documentation/16.0/
- **Ubuntu Server Guide**: https://ubuntu.com/server/docs
- **PostgreSQL Docs**: https://www.postgresql.org/docs/
- **Consultes**: Fes servir les sessions presencials per resoldre dubtes
:::

## Annex: Resolució de problemes comuns

### Problema: No puc accedir a Odoo des del navegador

**Possibles causes i solucions:**

1. **Port Forwarding mal configurat:**
   ```{code-block} bash
   # Comprova la configuració a VirtualBox
   VBoxManage showvminfo "nom-de-la-vm" | grep Forwarding
   ```

2. **Odoo no està executant-se:**
   ```{code-block} bash
   sudo systemctl status odoo
   sudo systemctl start odoo
   ```

3. **Firewall bloquejant el port:**
   ```{code-block} bash
   sudo ufw status
   sudo ufw allow 8069
   ```

### Problema: Error de dependències Python

```{code-block} bash
# Reinstal·lar dependències
sudo -u odoo -s
cd /opt/odoo
source odoo16-venv/bin/activate
pip install --upgrade pip
pip install -r odoo16/requirements.txt
```

### Problema: Error de base de dades

```{code-block} bash
# Comprovar que PostgreSQL funciona
sudo systemctl status postgresql
sudo -u postgres psql -c "\l"
```

### Problema: No puc fer SSH

1. **Comprova que SSH està instal·lat:**
   ```{code-block} bash
   sudo systemctl status ssh
   ```

2. **Comprova el Port Forwarding** a VirtualBox

3. **Prova des de la pròpia VM primer:**
   ```{code-block} bash
   ssh localhost
   ```


