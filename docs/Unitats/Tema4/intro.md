
## Introducció

Als capítols anteriors ja deixàrem Odoo ben instal·lat, configurat i amb accés a la base de dades.  
Si no és així, caldria realitzar un dels dos exercicis pràctics proposats a  
{doc}`Exercici pràctic 1: Instal·lació i configuració d'Odoo en Ubuntu Server <../../Annexos/Tema2_prac1>`  o  {doc}`Exercici pràctic 2: Desplegament d’Odoo amb Docker Compose <../../Annexos/Tema2_prac2>`. 
Ara toca fer el pas que tothom espera: **crear els nostres propis mòduls**.  Ací és on Odoo passa de ser “un programa” a ser “una plataforma programable”. Anirem poc a poc, que açò té faena, però no és cap mur de Berlín.

## Què és un mòdul en Odoo?

Un mòdul d’Odoo és, bàsicament, una carpeta amb una estructura concreta que Odoo sap interpretar per afegir funcionalitats noves. Un mòdul és com una mini-aplicació dins d’Odoo: pot afegir models, vistes, menús, informes, permisos etc. Tot el que vulgues fer, està dins d’un **mòdul**.

Un mòdul és simplement una **carpeta** que conté:

- un fitxer `__manifest__.py` → *el DNI del mòdul*
- un fitxer `__init__.py` → perquè Python sàpiga què carregar
- carpetes opcionals com:
  - `models/` → les classes i mètodes (Python)
  - `views/` → què veu l’usuari (XML)
  - `controllers/` → lògica web (Python)
  - `security/` → permisos i seguretat
  - `data/` → dades inicials o de configuració
  - `static/` → directori públic d’arxius estàtics (imatges, CSS, JS)
  - `report/` → informes personalitzats (QWeb)
  - `wizard/` → assistents o processos guiats


::: {admonition}  🧨 Punt clau: Odoo carrega TOTS els mòduls encara que no estiguen instal·lats. Cada vegada que arranques Odoo (o reinicies el servidor) passa açò:
:class: tip

  1. Odoo llig el codi Python de tots els mòduls que tens instal·lats
  2. Odoo llig el codi Python de tots els mòduls que NO tens instal·lats (però estan en addons_path)

> Odoo no els instal·la, simplement llegix el codi, les classes, els models, etc. Això és el que anomenem carregar els mòduls (load modules).

💡 És com quan obris un llibre per veure l’índex, però encara no l’has llegit.
:::


## El fitxer `__manifest__.py`  

Sense el manifest, Odoo ni sap que el mòdul existeix.

Un manifest típic:

```python
{
    'name': "Gestió d'Alumnes", #Nom comercial del mòdul
    'version': '16.0.1.0.0', #Versió del mòdul MAJOR.MINOR.PATCH.SUBPATCH.BUILD
    'summary': "Un mòdul d'exemple per entendre Odoo.",
    'description': "Gestiona alumnes, grups i matrícules.",
    'author': "IES Jaume II el Just",
    'website': "https://www.iesjaumeii.es",
    'license': 'LGPL-3',
    'category': 'Education', #Categoria on s'ubicarà el mòdul Accounting, Sales, Tools, etc.

    'depends': ['base'],  #Llista de mòduls que necessita per funcionar
    'data': [ #“Quins arxius XML vols que carregue Odoo quan instal·le el mòdul?”
        'security/ir.model.access.csv', #L’ordre importa → primer permisos, després vistes!
        'views/alumne_view.xml',
    ],

    'installable': True, #Si està a False, el mòdul apareix però no es pot instal·lar.
    'application': True, # si apareix en el menú principal
}
```

Cada camp té una funció, però els importants per començar són:

- **depends** → mòduls que necessita (quasi sempre `base`)
- **data** → els XML que s’han de carregar: vistes, menús, permisos…
- **application** → si ha d’aparéixer en el menú principal
- **demo**: carrega dades de demostració
    Si poses `demo`, Odoo carregarà dades de prova quan el mòdul s’instal·le en una base de dades nova.
Exemple:

```python
'demo': [
    'data/demo_alumnes.xml',
],
```


#### Com funciona?
Si la base de dades es crea amb “Load demo data” → sí que es carreguen. Load demo data està en la pantalla de creació de bases de dades.

```{image} /_static/assets/img/Tema5/load_demo_data.png
:alt: Load demo data
:width: 40%
:align: center
``` 


#### Nota important

Les dades demo dels mòduls NOMÉS es carregen si la base de dades es va crear amb “Load demo data”. Els demo no s’actualitzen quan actualitzes el mòdul. Només es carreguen en la instal·lació inicial.



:::{tip}   
**I si vull carregar dades demo encara que la base de dades no tinga activada la demo?**


Caldria afegir les dades a la secció `data` en lloc de `demo`. Però això no és recomanable, perquè les dades es carregarien sempre, fins i tot en producció.
:::

### Hooks d’instal·lació
Els hooks són funcions especials que Odoo crida en moments concrets del cicle de vida d’un mòdul. Hi ha quatre hooks principals relacionats amb la instal·lació i càrrega dels mòduls:
    - `post_load`
    - `pre_init_hook`
    - `post_init_hook`
    - `uninstall_hook`

Tots requereixen definir les funcions corresponents en un fitxer Python (normalment anomenat `hooks.py`) i referenciar-les en el manifest del mòdul. Al manifest, s’indica el nom de la funció que Odoo ha de cridar en cada moment.
El fitxer `hooks.py` ha d’estar importat en el `__init__.py` del mòdul perquè Odoo puga trobar les funcions i situar-lo en la carpeta `models/` o en la carpeta arrel del mòdul.

Exemple d’estructura del mòdul:
```bash
gestio_alumnes/
 ├── __init__.py
 ├── __manifest__.py
 ├── hooks.py        ← ací estan les funcions hook
 ├── models/
 ├── views/
 ├── security/
 └── ...
```
Quan Odoo executa alguns hooks especials durant la instal·lació d’un mòdul, passa dos objectes importants a les funcions: cr i registry. 
- `cr`: és el cursor de la base de dades que permet executar consultes SQL directament.
- `registry`: és el registre d’Odoo que conté informació sobre tots els models i dades carregades en el sistema.Només està disponible després que els models ja han sigut creats, per això sols apareix en `post_init_hook` i `uninstall_hook`.

```{caution} Resum dels hooks i els seus paràmetres
✔ `pre_init_hook(cr)`

Sempre rep un únic paràmetre: el cursor SQL cr.

✔ `post_init_hook(cr, registry)`

Rep dos paràmetres: SQL + models carregats.

✔ `uninstall_hook(cr, registry)`

Rep dos paràmetres.

✔ `post_load()`
No rep cap paràmetre.
```

### `post_load`: executar codi després de carregar el mòdul
`post_load` és un hook que s’executa després que Odoo haja carregat tot el codi Python, però abans de crear models en la base de dades, instal·lar dades o arrancar el servidor.

És a dir:
    - Odoo carrega el mòdul i els seus .py
    - Crida a la funció post_load (si existeix)
    - Després continua amb la resta de processos

```{danger}  
No té accés a la base de dades (no existeixen taules encara). És purament Python en memòria.
```



### `pre_init_hook`: executar codi abans d’instal·lar el mòdul

Quan l’usuari fa clic a **Instal·lar** en un mòdul, Odoo **no** crea les taules de seguida.  
Abans de començar la instal·lació crida, si existeix, la funció definida en `pre_init_hook`.

L’ordre simplificat és:

1. L’usuari prem **Instal·lar**.
2. Odoo comprova el manifest del mòdul.
3. Si hi ha un `pre_init_hook`, el crida.
4. Si el `pre_init_hook` acaba bé, Odoo continua la instal·lació normal.
5. Si el `pre_init_hook` llança una excepció, **s’atura la instal·lació** i no es canvia res.

En aquest punt:

- **Sí que tens accés a la base de dades** (mitjançant el cursor SQL `cr`),
- **Encara no existeixen les taules del teu mòdul**,
- Tampoc s’han carregat vistes, menús, permisos ni dades XML del mòdul.

**Exemple al manifest**

```python
'pre_init_hook': 'check_before_install',
```


Exemple de funció en **hooks.py**

```python
def check_before_install(cr):
    # Exemple: no volem instal·lar el mòdul si hi ha massa usuaris al sistema
    cr.execute("SELECT COUNT(*) FROM res_users")
    total = cr.fetchone()[0]

    if total > 200:
        raise Exception("Instal·lació cancel·lada: massa usuaris en la base de dades.")
```



### `post_init_hook`: executar codi després d’instal·lar el mòdul
Quan Odoo acaba d’instal·lar el mòdul (després de crear taules, carregar dades XML, etc.), crida la funció definida en `post_init_hook`.
Açò és útil per a tasques com:
- Població inicial de dades que depenen de les taules ja creades.
- Configuració addicional que necessita que el mòdul estiga completament instal·lat.
- Enviar notificacions o registrar esdeveniments després de la instal·lació.
- Realitzar comprovacions post-instal·lació per assegurar que tot està correcte.
- Integració amb altres mòduls que ja estan instal·lats.
- Qualsevol altra lògica que necessite que el mòdul estiga totalment operatiu abans d’executar-se.


**Exemple al manifest**

```python
'post_init_hook': 'setup_after_install',
``` 
Exemple de funció en **hooks.py**

```python
def setup_after_install(cr, registry):
    # Exemple: crear un registre inicial en una taula del mòdul
    env = api.Environment(cr, SUPERUSER_ID, {})

    # Crear un registre inicial
    env['centre.alumne'].create({
        'name': 'Alumne Inicial',
        'edat': 18,
        'curs': '1eso',
    })
```     

### `uninstall_hook`: executar codi abans d’eliminar el mòdul
Quan l’usuari fa clic a **Desinstal·lar** en un mòdul, Odoo crida la funció definida en `uninstall_hook` abans de procedir a eliminar-lo.
Açò és útil per a tasques com:
- Netejar dades relacionades que no es volen conservar.
- Registrar esdeveniments o enviar notificacions sobre la desinstal·lació.
- Realitzar comprovacions per assegurar que la desinstal·lació es pot dur a terme sense problemes.
- Integració amb altres mòduls per gestionar dependències o relacions.          
**Exemple al manifest**

```python
'uninstall_hook': 'cleanup_before_uninstall',
``` 

Exemple de funció en **hooks.py**

```python
def cleanup_before_uninstall(cr, registry):
    # Exemple: eliminar registres relacionats en altres taules
    env = api.Environment(cr, SUPERUSER_ID, {})                     
    # Suposem que volem eliminar tots els alumnes abans de desinstal·lar
    env['centre.alumne'].search([]).unlink()
```     


::: {admonition} Nota sobre `registry`
:class: tip

Encara que en els nostres exemples **no fem servir directament** l'objecte `registry`, és important saber què és.  
`registry` és la estructura interna d’Odoo que conté **tots els models carregats** del sistema (contactes, vendes, productes, i també els models del teu mòdul).

Gràcies a `registry`, Odoo pot crear l’objecte `env`, que és el que sí que utilitzarem per treballar amb l’ORM:  
```python
env = api.Environment(cr, SUPERUSER_ID, {})
```
:::




## El fitxer `__init__.py`

Cada carpeta d’un mòdul d’Odoo és també un “paquet Python”. El fitxer `__init__.py` és el que li diu a Python quins submòduls s’han de carregar quan Odoo carregue el mòdul. Sense aquest fitxer, Odoo no veurà els models ni les funcions que tingues dins.

Exemple:

```python
from . import models
from . import hooks
from . import controllers
```
Això indica que Odoo ha de carregar els submòduls `models`, `hooks` i `controllers` quan carregue el mòdul.Cada submòdul és una carpeta amb el seu propi `__init__.py` i dins de `models/__init__.py`:

```python
from . import alumne
```
Si no poses estos imports, Odoo no veurà les classes Python.



## Estructura d’un mòdul
Quan creem un mòdul en Odoo, realment estem creant una carpeta organitzada de forma molt concreta. Odoo només pot reconéixer el nostre mòdul si té la estructura mínima i els fitxers necessaris.

La següent secció explica què és imprescindible, què és opcional i com Odoo interpreta cada carpeta.
### Estructura mínima d’un mòdul
Un mòdul pot ser tan senzill com:
```text
nom_modul/
 ├── __init__.py
 └── __manifest__.py
```
Aquesta estructura mínima:
- És detectada per Odoo
- El mòdul apareix en el menú Instal·lar, però no fa absolutament res.
- Només serveix com a punt de partida.

### Estructura completa típica
En un mòdul real, la carpeta conté diverses subcarpetes:

```text
nom_modul/
 ├── __init__.py                 ← indica què ha de carregar Python
 ├── __manifest__.py             ← informació del mòdul (DNI)
 ├── models/                     ← models de dades (Python)
 │    ├── __init__.py
 │    └── alumne.py
 ├── views/                      ← vistes (XML)
 │    ├── alumne_view.xml
 │    └── menus.xml
 ├── security/                   ← permisos i accessos
 │    ├── ir.model.access.csv
 │    └── security.xml
 ├── data/                       ← dades inicials (XML)
 │    └── dades_inicials.xml
 ├── wizard/                     ← assistents (Python + XML)
 ├── controllers/                ← controladors web (Python)
 ├── report/                     ← informes QWeb (XML)
 └── static/                     ← recursos estàtics (CSS, JS, imatges)
      └── description/
           └── icon.png

```



### Crear l’estructura automàticament amb `scaffold`  
Odoo incorpora un comandament que crea automàticament tota l’estructura d’un mòdul: carpetes, manifest, init, models d’exemple, vistes bàsiques, etc.

La sintaxi general és:
```bash
./odoo scaffold nom_modul /ruta/dels/moduls
```

Si estàs treballant en Docker, cal entrar dins del contenidor on està Odoo abans d’executar scaffold. El tema de permisos pot resultar complicat, així que una forma senzilla és executar:

```bash
docker compose exec -u root web bash
```
Després, dins del contenidor, canviar els permisos en executar:

```bash
/usr/bin/odoo scaffold escola /mnt/extra-addons
chown -R odoo:odoo /mnt/extra-addons/escola
```

Açò genera automàticament tota l’estructura necessària.

:::{tip} 
**Sobre `scaffold` en entorns Docker**

En molts entorns Docker, Odoo **no inclou el fitxer `odoo-bin` ni el codi font complet**, ja que està instal·lat com a paquet Python.  
Això vol dir que **no es pot utilitzar l’ordre `scaffold` directament**. Pot estar en una ruta diferent, com `/usr/bin/odoo`, o que no estiga disponible.

És possible descarregar una còpia del codi font d’Odoo dins del contenidor (com hem fet per a proves) i usar `odoo-bin` només per a crear l’estructura d’un mòdul.  
Ara bé, **açò no sol compensar**:
- El repositori d’Odoo ocupa **moltes gigues**.
- Es carrega el contenidor amb fitxers que **no s’utilitzen en execució**.
- Complica el manteniment i l’enteniment de l’entorn.

Per això, en pràctica, **crear el mòdul a mà és igual de vàlid i molt més net**.  
`scaffold` només genera carpetes i fitxers bàsics: no aporta cap funcionalitat extra.
:::

:::{caution} 
**Recordatori important si treballes amb Docker**


Quan estàs fent mòduls en Docker, el codi real no viu dins del contenidor, sinó en el directori del teu ordinador que tens muntat com a volum (p. ex. ./extra-addons:/mnt/extra-addons).

Això vol dir que:

- Si fas scaffold dins del contenidor, el mòdul apareix igualment al teu PC.

- Si edites fitxers dins del contenidor, també es modifiquen fora.

- Contenidor i host veuen la mateixa carpeta, com dues finestres mirant al mateix hort.

Només seria un problema si /mnt/extra-addons no fora un volum muntat:
en eixe cas sí que estaries escrivint dins del contenidor i es perdria tot quan el borrares.

:::


### Creació manual d’un mòdul  
Si treballes amb docker vas a experimentar un problema de permisos. Per poder crear amb el comando scaffold has de ser usuari root dins del contenidor, però els fitxers creats així pertanyen a root i després Odoo no pot llegir-los i cal canviar els permisos manualment. Tampoc podràs editar-los des de fora del contenidor ja que el teu usuari no tindrà permisos. Una solució poc elegant es canviar els permisos després de crear el mòdul amb scaffold:
```bash
chown -R odoo:odoo /mnt/extra-addons/nom_modul
``` 
o donar permisos d’escriptura a tot el món:
```bash
chmod -R 777 /mnt/extra-addons/nom_modul
```

Però canviar el propietari seria per a no tocar més el mòdul fora del contenidor. L'altra, donar-li permisos a tot l’usuari (777), no és gens recomanable.

La solució passa per modificar el usuari al `docker-compose.yml` i posar el mateix usuari que tens a l’ordinador (normalment el teu UID és 1000). Així els fitxers creats dins del contenidor pertanyen al teu usuari i pots editar-los des de fora sense problemes. Pots obtenir el teu UID i GID amb el comando `id` a la terminal.
:::{tip} 
**Solució recomanada per a permisos en Docker**

En el `docker-compose.yml`, afegir la línia `user: "${UID}:${GID}"` al servei de Odoo:
```yaml 
services:
  web:
    image: odoo:16.0
    user: "${UID}:${GID}"
    ...
```
i un fitxer .env
```bash
UID=1000
GID=1000
```
Després d’això, cal reiniciar el contenidor per aplicar els canvis
```bash
docker compose down
docker compose up -d
```
:::


Per a crear el mòdul manualment, els passos bàsics són:

1. Crear carpeta nova dins d’`extra-addons`.
2. Crear `__manifest__.py`.
3. Crear `__init__.py`.
4. Crear la carpeta `models`, amb el seu `__init__.py`.
5. Crear un o més fitxers `.py` amb els models.
6. Crear la carpeta `views` amb els XML de les vistes.
7. Crear permisos en `security/ir.model.access.csv`.

### Exemple de model senzill
En Odoo, la carpeta `models/` conté totes les classes Python que definixen els models de dades, és a dir, les “taules intel·ligents” del sistema. Cada fitxer `.py` dins d’aquesta carpeta sol correspondre a un model, i cada classe hereta de `models.Model`, que és la manera que té Odoo de saber que volem crear un model propi dins del framework.

Per exemple, si volem crear un model per gestionar alumnes, podríem tenir un fitxer `alumne.py` dins de `models/` amb el següent contingut:

Fitxer: `models/alumne.py`

```python
from odoo import models, fields

class Alumne(models.Model):
    _name = 'centre.alumne'
    _description = 'Alumne del centre'

    name = fields.Char(string="Nom", required=True)
    edat = fields.Integer(string="Edat")
    curs = fields.Selection(
        [('1eso','1r ESO'), ('2eso','2n ESO')],qu
        string="Curs"
    )
```
Importem també el model en `models/__init__.py`:

```python
from . import alumne
``` 
Al fixer models/alumne.py hem definit un model anomenat `centre.alumne` amb tres camps: `name`, `edat` i `curs`. Aquest model es traduirà en una taula a la base de dades amb les columnes corresponents.

:::{image} /_static/assets/img/Tema5/curs-alumne.png
:alt: Model centre.alumne
:scale: 20%
:align: center
:::

En Python la classe `Alumne` hereta de `models.Model`, que és la manera que té Odoo de saber que volem crear un model propi dins del framework. A la base de dades, Odoo crearà automàticament una taula anomenada `centre_alumne` amb les columnes `name`, `edat` i `curs`. 

**Què és exactament un field en Odoo?**

En Odoo, cada camp (`fields.*`) és com una entrada del **diccionari de dades** del model. Cada vegada que declares un camp, li estàs dient a Odoo:
- Com es diu la columna(l'atribut) a la base de dades,
- Quin tipus de dada guarda,
- Quines condicions ha de complir (required, domain, selection, constraints),
- Com s’ha de mostrar a la interfície (string, help),
- I com es relaciona amb altres taules (Many2one, One2many, Many2many).

:::{caution}

Un `field`  no és només “una columna SQL”; és la definició completa del comportament d’eixa dada dins d’Odoo.

Un field en Odoo equival a una entrada de metadades

:::

Quan escrius:
```python
from odoo import models, fields

class Alumne(models.Model):
    _name = 'centre.alumne'
    _description = 'Alumne del centre'

    name = fields.Char(string="Nom", required=True, help="Nom complet de l'alumne")
    edat = fields.Integer(string="Edat", default=0)
    curs = fields.Selection(
        [('1eso','1r ESO'), ('2eso','2n ESO')],
        string="Curs"
    )
    tutor_id = fields.Many2one('res.partner', string="Tutor/a")
```

Odoo:
- Crea/actualitza les columnes a la BD (`centre_alumne.name`, `centre_alumne.edat`, …).
- Enllaça `tutor_id` amb `res.partner` i aplica integritat relacional.


**🧭 I què és això de `res.partner`?**

`res.partner` és el model central d’Odoo per a persones i empreses. És “l’entitat universal”: contactes, clients, proveïdors, alumnes, tutors, pares, empreses, professors… tot són partners.  
Així Odoo reutilitza adreces, telèfons, correus, NIF, imatges, etiquetes i tot el sistema de comunicació.

Per tant, quan poses un camp Many2one cap a `res.partner`, estàs enllaçant el teu registre amb un contacte existent i aprofitant tota la seua informació.

Camps clau de `res.partner`:
- `name`, `company_type` (person/company), `is_company`
- `parent_id` (empresa pare), `child_ids` (contactes fill)
- `email`, `phone`, `mobile`
- `vat` (NIF), `category_id` (etiquetes), `image_1920` (foto)
- `active` (arxiu lògic)

Exemple bàsic d’ús en el teu model:
```python
from odoo import models, fields

class Alumne(models.Model):
    _name = 'centre.alumne'
    _description = 'Alumne del centre'

    # Tutor legal: només persones actives
    tutor_id = fields.Many2many(
        'res.partner', string="Tutor/a",
        domain="[('company_type','=','person'), ('active','=',True)]",
        ondelete='set null',
        help="Persona de contacte (pare/mare/tutor legal)"
    )

    # Empresa per a FCT/Dual: només empreses
    empresa_id = fields.Many2one(
        'res.partner', string="Empresa (FCT/Dual)",
        domain="[('is_company','=',True)]",
        ondelete='set null'
    )
```

Filtrat per jerarquia pare-fill (contacte que pertany a una empresa):
```python
    contacte_empresa_id = fields.Many2one(
        'res.partner', string="Contacte a l’empresa",
        domain="[('company_type','=','person'), ('parent_id','=',empresa_id)]"
    )
```

Estendre `res.partner` des del teu mòdul (afegir camps nous al partner):
```python
from odoo import models, fields

class ResPartner(models.Model):
    _inherit = 'res.partner'

    is_student = fields.Boolean(string="És alumne/a")
    expedient = fields.Char(string="Codi d’expedient")
```


:::{caution} 
**Mantín `ondelete='set null'` en Many2one si no vols bloquejar l’esborrat de partners.**
`ondelete='restrict' `→ bloqueja l’esborrat del partner si hi ha alumnes que el fan servir.
(I et quedaràs sense poder esborrar Fulanito que està duplicat tres voltes.)

`ondelete='cascade'` → si esborres el partner, s’esborren els alumnes també.
(Açò és una desgràcia gorda, evitem-ho sempre.)

`ondelete='set null'` → si esborres el partner, el camp tutor_id queda buit.
Això és el que volem en el 99 % dels casos.
:::


::: {admonition} 🧠 Abans de continuar: herència de models en Odoo
:class: tip

En l’exemple hem utilitzat una classe que hereta de `models.Model` i també hem vist com ampliar `res.partner` amb `_inherit`.

Açò és perquè, en Odoo, no solem “tocar” directament un model existent. En lloc d’això:
- si volem crear un model nou, usem `_name`
- si volem ampliar un model ja existent, usem `_inherit`

No ens pararem ara, la herència és important i la treballarem amb calma més endavant, però queda’t amb la idea:
👉 quan Odoo veu `_inherit`, sap que estem afegint coses a un model que ja existix, no creant-lo de zero.

De moment, confia en aquesta mecànica: Odoo fa la màgia interna i tu no trencaràs cap model del sistema (que sempre és d’agrair).

:::

### Per què els models en Odoo es diuen `prefix.nom`?

Quan creem un model en Odoo, una de les primeres coses que definim és el seu nom intern, mitjançant l’atribut `_name`. Aquest nom no és un simple identificador, sinó que és el nom global i únic amb què Odoo reconeix el model dins de tot el sistema.

#### ❗ Per què no podem posar simplement `_name = "alumne"`?
Perquè Odoo:
1. Carrega TOTS els mòduls que té en l’`addons_path`, encara que no estiguen instal·lats.
2. Cada model ha de tindre un nom únic en tot el sistema.
3. Si dos mòduls tenen un model amb el mateix nom, es produïx un conflicte:
   - Odoo no sap quin model és quin.
   - La instal·lació pot fallar.
   - O, pitjor, es poden sobreescriure dades o comportaments.

És com si en una classe hi hagueren dos xiquets amb el mateix nom i DNI: conflicte assegurat.

#### 🎯 Solució recomanada per Odoo
Utilitzar sempre el format: `<prefix>.<nom_del_model>`

On:
- `prefix` identifica el teu mòdul o àrea funcional.
- `nom_del_model` és el nom real del model.

Aquest prefix actua com a espai de noms i evita col·lisions.

#### 💡 Exemples dins d’Odoo
| Mòdul     | Model            |
|-----------|------------------|
| Vendes    | `sale.order`     |
| Stock     | `stock.picking`  |
| RRHH      | `hr.employee`    |
| Projectes | `project.task`   |

Tots seguixen `prefix.nom`.

#### 🧩 I en el nostre cas?
Si el nostre mòdul es diu `gestio_centre`, el prefix triat és `centre`. Per tant, els models serien:
- `centre.alumne`
- `centre.classe`
- `centre.event`

Això garantix:
- Absència de xocs amb altres mòduls.
- Identificació clara dels models.
- Codi més net i coherent.

#### ✔ Resum per a recordar
- En Odoo, els models han de tindre un nom únic global.
- Per això utilitzem sempre `prefix.nom`.
- El prefix identifica el teu mòdul i evita col·lisions.
- Exemple correcte: `centre.alumne`. Incorrecte: `alumne`.
- El prefix no ha de ser el nom complet del mòdul; n’hi ha prou amb un nom curt i distintiu.




## Crear les vistes
Les vistes són fitxers XML que defineixen com es mostra la informació a l’usuari. Sense vistes, Odoo no sap com presentar els formularis ni els llistats dels teus models.


### Què fa Odoo quan no té vistes?

Quan instal·les un mòdul amb un model nou (p. ex. `centre.alumne`) i no has creat cap vista XML, Odoo:
- Detecta que el model és nou.
- Mira quins camps té (p. ex. name, edat, curs…).
- Genera vistes automàtiques perquè pugues treballar amb el model encara que no hages escrit ni una línia d’XML.

Odoo crea tres elements bàsics:
- Vista tree (llistat) amb tots els camps visibles.
- Vista form minimalista amb els camps alineats de dalt a baix.
- Una acció interna per poder veure dades des de Tècnic → Models → centre.alumne → Veure dades.
- No crea cap menú ni accés directe, per això no podem veure aquestes vistes des del menú principal, però sí que existeixen i es poden utilitzar.

:::{caution}  
**Quan no tens vistes declarades**

Quan Odoo detecta que un model no té vistes definides, crea automàticament unes vistes bàsiques per a eixe model. Aquestes vistes automàtiques són molt senzilles i serveixen per a que pugues començar a treballar amb el model sense haver de definir res en XML. Això és especialment útil durant el desenvolupament, ja que et permet provar els models ràpidament. No obstant això, sense menús, no podem accedir a aquestes vistes per tant, caldrà esperar al proper capítol per a veure el resultat.
:::


### 🧼 Com són aquestes vistes automàtiques?
Senzilles i “menjables”, però no per a producció:
- Camps en línia, sense groups ni pestanyes.
- Sense disseny ni validacions visuals.
- Sense menú propi, tret que el crees manualment (o via XML).

Per a començar són perfectes perquè pots comprovar que:
- El model carrega,
- Els camps funcionen,
- La taula s’ha creat,
- I tot està al seu lloc.

Així evitem anar a cegues mentre definim models.

### 📌 Què són exactament les vistes?
Les vistes són fitxers XML que definixen:
- Com es mostra el formulari (form),
- Com es mostra el llistat (tree),
- Quins camps van junts en un group,
- Quines pestanyes hi ha,
- Què és editable i què no,
- I tota la part visual declarativa (sense CSS).

És el “frontend” d’Odoo, però al seu estil: estructurat, declaratiu i en XML.  
Com que tenen molta molla (tree, form, search, kanban, calendar, pivot, graph, activity…), les treballarem amb calma. Per ara, farem un exemple bàsic per al model `centre.alumne`.

Fitxer: `views/alumne_view.xml`

```xml
<odoo>
    <record id="centre_alumne_form" model="ir.ui.view">
        <field name="name">centre.alumne.form</field>
        <field name="model">centre.alumne</field>
        <field name="arch" type="xml">
            <form string="Alumne">
                <sheet>
                    <group>
                        <field name="name"/>
                        <field name="edat"/>
                        <field name="curs"/>
                    </group>
                </sheet>
            </form>
        </field>
    </record>

    <record id="centre_alumne_tree" model="ir.ui.view">
        <field name="name">centre.alumne.tree</field>
        <field name="model">centre.alumne</field>
        <field name="arch" type="xml">
            <tree>
                <field name="name"/>
                <field name="edat"/>
                <field name="curs"/>
            </tree>
        </field>
    </record>

    <record id="centre_alumne_action" model="ir.actions.act_window">
        <field name="name">Alumnes</field>
        <field name="res_model">centre.alumne</field>
        <field name="view_mode">tree,form</field>
    </record>

    <menuitem id="centre_menu_root" name="Centre"/>
    <menuitem id="centre_menu_alumnes" parent="centre_menu_root"
              action="centre_alumne_action" name="Alumnes"/>
</odoo>
```


## Permisos: `ir.model.access.csv`
Odoo té un sistema de seguretat molt estricte.  Fins i tot si has creat un model i les vistes corresponents, **els usuaris no podran accedir fins que no definisques permisos d’accés**. 

Perquè els usuaris puguen llegir, crear, editar o esborrar registres del model `centre.alumne`, cal definir permisos d’accés en el fitxer `security/ir.model.access.csv`.

### Crear la carpeta i el fitxer
Estructura mínima amb seguretat:
```bash
gestio_alumnes/
├── __init__.py
├── __manifest__.py
├── models/
│   ├── __init__.py
│   └── alumne.py
├── security/
│   └── ir.model.access.csv
└
```

### Estructura del fitxer `ir.model.access.csv`
Capçalera obligatòria (no la modifiques):
```
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
```
Significat:
- id: identificador únic del registre de permís.
- name: nom descriptiu.
- model_id:id: xml_id del model (Odoo genera `model_<model_name>`), ex: `model_centre_alumne`.
- group_id:id: xml_id del grup (o buit per a tots els usuaris interns).
- perm_read / perm_write / perm_create / perm_unlink: 1 (sí) o 0 (no).

### Exemple complet per al model `centre.alumne`
Si recordes, el model `centre.alumne` està definit així:models/alumne.py    
```python
from odoo import models, fields

class Alumne(models.Model):
    _name = 'centre.alumne'
    _description = 'Alumne del centre'
```
Al fitxer `security/ir.model.access.csv`, afegim la línia següent per donar permisos complets als usuaris interns (`base.group_user`) dotant-los de permisos de lectura, escriptura, creació i esborrat:
Fitxer `security/ir.model.access.csv`:
```text
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_centre_alumne_user,access_centre_alumne_user,model_centre_alumne,base.group_user,1,1,1,1
```

Si vols només lectura, canvia els permisos:
```text
access_centre_alumne_read,access_centre_alumne_read,model_centre_alumne,base.group_user,1,0,0,0
```

Afegir diverses línies permet diferenciar grups (ex: professorat vs alumnat) definint prèviament els grups en `security/security.xml`.

> Recorda: inclou `security/ir.model.access.csv` en la secció `data` del manifest perquè es carregue en instal·lar el mòdul. Primer els permisos, després les vistes!

Exemple en `__manifest__.py`:
```python
'data': [
    'security/ir.model.access.csv',
    'views/alumne_view.xml',
],
```


### També podem restringir elements en les vistes (botons, camps, etc.)

Els permisos del CSV controlen l’accés global al model. Si vols afinar la UI (mostrar/ocultar un botó, un camp o un menú per a determinats rols), usa grups en les vistes. Açò no substitueix la seguretat del servidor: és només visibilitat a la interfície.

Flux típic en dos passos:
1) Definir els grups (security/security.xml)
2) Aplicar-los a elements de vista amb l’atribut `groups`

Fitxer: `security/security.xml`
```xml
<odoo>
  <record id="group_professorat" model="res.groups">
    <field name="name">Professorat</field>
    <field name="category_id" ref="base.module_category_tools"/>
  </record>

  <record id="group_alumnat" model="res.groups">
    <field name="name">Alumnat</field>
    <field name="category_id" ref="base.module_category_tools"/>
  </record>
</odoo>
```

Inclou el fitxer al manifest:
```python
'data': [
    'security/ir.model.access.csv',
    'security/security.xml',
    'views/alumne_view.xml',
],
```

Aplicació en vistes (exemples habituals):
```{code-block} xml
<odoo>
  <!-- Formulari: botó només per a Professorat -->
  <record id="centre_alumne_form" model="ir.ui.view">
    <field name="name">centre.alumne.form</field>
    <field name="model">centre.alumne</field>
    <field name="arch" type="xml">
      <form string="Alumne">
        <sheet>
          <group>
            <field name="name"/>
            <field name="edat"/>
            <field name="curs"/>
            <!-- Camp visible només per Professorat -->
            <field name="expedient" groups="gestio_alumnes.group_professorat"/>
          </group>
          <!-- Botó d’acció reservat a Professorat -->
          <footer>
            <button name="action_calcular_nota" type="object" string="Calcular nota"
                    class="oe_highlight"
                    groups="gestio_alumnes.group_professorat"/>
          </footer>
        </sheet>
      </form>
    </field>
  </record>

  <!-- Menú visible només per a Professorat -->
  <menuitem id="centre_menu_root" name="Centre"/>
  <menuitem id="centre_menu_alumnes" parent="centre_menu_root"
            action="centre_alumne_action" name="Alumnes"
            groups="gestio_alumnes.group_professorat"/>
</odoo>

```

Notes ràpides:
- `groups` accepta una llista d’xml_id separats per comes.
- Açò controla visibilitat; la seguretat real s’aplica amb `ir.model.access.csv` i (si cal) regles de registre (`ir.rule`) per restringir dades al servidor.



## Reiniciar, instal·lar i actualitzar un mòdul
Durant el desenvolupament d’un mòdul faràs canvis en Python, XML o el manifest. Odoo no tracta tots els canvis igual. Hi ha tres accions diferenciades:

- Reiniciar el servidor
- Instal·lar el mòdul
- Actualitzar el mòdul

Cada acció té efectes diferents.

### Reiniciar el servidor Odoo
Recarrega ÚNICAMENT el codi Python (models, controladors, hooks, imports en `__init__.py`).  
No torna a carregar vistes XML ni permisos CSV ni dades declaratives.

Servidor (systemd):
```bash
sudo systemctl restart odoo
```
Docker:
```bash
docker compose restart
```

Fes-ho quan: afegixes/edites mètodes, canvies logic Python, afegixes fitxers `.py`.

### Instal·lar un mòdul
Processament inicial (primera vegada en la BD):
- Crea taules del model
- Carrega tots els XML del `__manifest__.py`
- Crea menús, accions i vistes
- Processa permisos (`ir.model.access.csv`)
- Executa `pre_init_hook` i `post_init_hook` si existeixen

CLI:
```bash
./odoo-bin -i nom_modul -d nom_bd
```
(-i = install)

### Actualitzar un mòdul
S’utilitza quan el mòdul ja està instal·lat i has modificat:
- Vistes XML, menús, accions
- Permisos o fitxers `security/*.xml` / `ir.model.access.csv`
- Manifest (depends, data…)
- Has afegit/eliminat camps en models
- Dades declaratives (XML/CSV)

L’actualització:
- Recarrega vistes i menús
- Aplica canvis del manifest
- Reprocesa permisos
- Ajusta l’esquema (nous camps)
- Pot cridar hooks específics (si programats via migracions)

CLI:
```bash
./odoo-bin -u nom_modul -d nom_bd
```
(-u = update)

Important: Reiniciar NO actualitza vistes ni permisos.

### Quan usar cada acció?

| Acció              | Quan?                                      | Què recarrega?                          |
|--------------------|---------------------------------------------|-----------------------------------------|
| Reiniciar servidor | Canvis en codi Python                      | Classes, models, controladors           |
| Instal·lar          | Primera vegada en la BD                    | Tot: models, vistes, menús, permisos    |
| Actualitzar        | Canvis en XML, manifest, permisos, camps   | Vistes, permisos, dades, esquema        |

Regla ràpida:
- Afegixes un camp nou → update (-u)
- Canvies lògica Python d’un mètode → reinici
- Afegixes una vista nova al manifest → update
- Primera vegada que poses el mòdul → install

