## Introducció

Als capítols anteriors ja deixàrem Odoo ben instal·lat, configurat i amb accés a la base de dades. Ara toca fer el pas que tothom espera: **crear els nostres propis mòduls**. Ací és on Odoo passa de ser “un programa” a ser “una plataforma programable”. Anirem poc a poc, que açò té faena, però avançarem amb una prespectiva de disseny per entendre no només el “com” sinó també el “per què” de la creació de mòduls. 

::: {admonition} Objectius d’aprenentatge
:class: important

Quan acabes este tema, hauràs de ser capaç de:

- Identificar l’estructura mínima d’un mòdul i per a què serveix cada carpeta.
- Escriure un `__manifest__.py` funcional (dependències, dades XML, opcions bàsiques).
- Entendre què significa “instal·lar” vs “actualitzar” un mòdul.
- Saber quan té sentit utilitzar hooks (`pre_init_hook`, `post_init_hook`, etc.) i quines limitacions tenen.
- Crear un model senzill en Python i entendre com es tradueix a la base de dades.
- Tenir un model mental clar de com Odoo interpreta els mòduls i els models, i com es relacionen amb la base de dades.
:::

Aquest tema és la base de tot el que farem després, així que convé entendre’l bé. No es tracta només de seguir passos, sinó de comprendre com funciona Odoo per dins. Si tens dubtes, rellegix els apartats que no tingues clars i prova de crear mòduls senzills per veure’n el funcionament real. Per visualitzar el que passa, accedix a PostgreSQL i revisa les taules que es creen, les dades que s’hi inserixen, etc. Així veuràs la connexió directa entre el codi Python, els models d’Odoo i la base de dades, ja siga amb pgAdmin o amb la línia d’ordres (`psql`). També hi ha una altra manera de comprovar-ho abans d’estudiar vistes i menús: activar el mode depurador (“Developer mode”) i consultar la vista de models, que mostra tots els models carregats al sistema i les seues taules associades.

::: {admonition} Requisits previs (check ràpid)
:class: note

Abans de continuar, comprova que:

- Pots entrar a Odoo amb un usuari administrador.
- Saps on està el teu `addons_path` (i tens una carpeta per als teus mòduls).
:::

## Mapa del capítol (itinerari recomanat)

1. **Què és un mòdul i quina estructura té** (carpetes clàssiques i per a què serveixen).
2. **El manifest**: què és imprescindible i què és opcional.
3. **Dades `data` vs `demo`**: quan es carreguen i quan NO.
4. **Hooks**: en quin moment s’executen i què pots fer en cadascun.
5. **El fitxer `__init__.py`**: què importa Odoo i per què és clau.
6. **De l’ER al model Odoo**: com es tradueix una entitat en un model Python i després en una taula SQL.
7. **Vistes i permisos**: XML bàsic i `ir.model.access.csv`.
8. **Cicle de desenvolupament**: reiniciar, instal·lar i actualitzar mòduls.

:::{tip}
Si estàs aprenent, no intentes “fer-ho tot” el primer dia: crea primer un mòdul mínim que s’instal·le bé, i després vas afegint peces (models → seguretat → vistes → menús). De l'ER al model Odoo conté molts conceptes i definicions de base de dades que poden resultar confusos al principi, així que és millor anar pas a pas i veure com es tradueix cada element a la pràctica. Realitza l'exercici pràctic 6 abans de continuar amb el tema de creació de vistes.
:::

## Què és un mòdul en Odoo?

Un mòdul d’Odoo és, bàsicament, una carpeta amb una estructura concreta que Odoo sap interpretar per afegir funcionalitats noves. Un mòdul és com una mini-aplicació dins d’Odoo: pot afegir models, vistes, menús, informes, permisos etc. Tot el que vulgues fer, està dins d’un **mòdul**.

Un mòdul és simplement una **carpeta** que conté:

- un fitxer `__manifest__.py` → el *DNI* del mòdul
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


::: {admonition} 🧨 Punt clau: “descobrir” mòduls vs “carregar” mòduls
:class: tip

Quan arranques Odoo (o reinicies el servidor) passen dues coses diferents que convé no confondre:

1. **Descobriment (scan)**: Odoo recorre el `addons_path` i llig el `__manifest__.py` dels mòduls (instal·lats o no) per construir la llista d’aplicacions disponibles.
2. **Càrrega real (load/import)**: Odoo **importa i executa el codi Python** sobretot dels mòduls **instal·lats** (i les seues dependències), i també quan instal·les/actualitzes un mòdul.

Conseqüència pràctica: un mòdul que “està en la carpeta” pot aparéixer en Apps, però **no farà res** fins que el **instal·les**; i alguns errors de Python poden no eixir fins al moment d’instal·lar/actualitzar.

💡 És com mirar l’índex de tots els llibres d’una biblioteca (descobrir), però només llegir de veritat els que has triat (carregar).
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
- `registry`: és el registre d’Odoo que conté informació sobre tots els models i dades carregades en el sistema. Només està disponible després que els models ja han sigut creats, per això sols apareix en `post_init_hook` i `uninstall_hook`.

```{caution} Resum dels hooks i els seus paràmetres

- **`pre_init_hook(cr)`**: sempre rep un únic paràmetre (el cursor SQL `cr`).
- **`post_init_hook(cr, registry)`**: rep dos paràmetres (SQL + models carregats).
- **`uninstall_hook(cr, registry)`**: rep dos paràmetres.
- **`post_load()`**: no rep cap paràmetre.
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
from odoo import api, SUPERUSER_ID

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

Gràcies a `registry`, Odoo pot crear l’objecte `env`, que és el que sí que utilitzarem per treballar amb l’ORM (Object-Relational Mapping):  
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
Quan creem un mòdul en Odoo, realment estem creant una carpeta organitzada de forma molt concreta. Odoo només pot reconéixer el nostre mòdul si té l’estructura mínima i els fitxers necessaris.

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
- El mòdul apareix en Apps (Aplicacions), però no fa absolutament res.
- Només serveix com a punt de partida.

### Estructura completa típica
En un mòdul real, la carpeta conté diverses subcarpetes:

```text
nom_modul/
 ├── __init__.py                 ← indica què ha de carregar el Python
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

Ací:
- `web` = nom del servei d’Odoo en el `docker-compose.yml` (Docker resol aquest servei al contenidor en execució, p. ex. `odoo_server-web-1`).
- `-u root` = executar la comanda com a usuari `root` dins del contenidor.

Després, dins del contenidor, canvia els permisos amb:

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
Si treballes amb docker, experimentaràs un problema de permisos. Per poder crear amb el comand scaffold has de ser usuari root dins del contenidor, però els fitxers creats així pertanyen a root i després Odoo no pot llegir-los i cal canviar els permisos manualment. Tampoc podràs editar-los des de fora del contenidor ja que el teu usuari no tindrà permisos. Una solució poc elegant és canviar els permisos després de crear el mòdul amb scaffold:
```bash
chown -R odoo:odoo /mnt/extra-addons/nom_modul
``` 
o donar permisos d’escriptura a tot el món:
```bash
chmod -R 777 /mnt/extra-addons/nom_modul
```

Però canviar el propietari seria per a no tocar més el mòdul fora del contenidor. L'altra, donar-li permisos a tot l’usuari (777), no és gens recomanable.

La solució passa per modificar el usuari al `docker-compose.yml` i posar el mateix usuari que tens a l’ordinador (normalment el teu UID és 1000). Així els fitxers creats dins del contenidor pertanyen al teu usuari i pots editar-los des de fora sense problemes. Pots obtenir el teu UID i GID amb el comand `id` a la terminal.
:::{tip} 
**Solució recomanada per a permisos en Docker**

En el `docker-compose.yml`, afegir la línia `user: "${UID}:${GID}"` al servei de Odoo:
```yaml 
services:
  web:
    image: odoo:19.0
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
        [('1eso','1r ESO'), ('2eso','2n ESO')],
        string="Curs"
    )
```
Importem també el model en `models/__init__.py`:

```python
from . import alumne
``` 

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
| --- | --- |
| Vendes    | `sale.order`     |
| Stock     | `stock.picking`  |
| RRHH      | `hr.employee`    |
| Projectes | `project.task`   |

Tots seguixen `prefix.nom`.

:::{caution} 
**Del model a la taula SQL**

És important entendre que el valor de `_name` (Python/Odoo) **no és exactament** el mateix nom que veuràs en PostgreSQL:

- En Odoo/Python: usem punts per jerarquitzar, p. ex. `_name = 'centre.assignacio.docent'`.
- En SQL (PostgreSQL): Odoo crea la taula canviant els punts per guions baixos.

Resultat pràctic: en base de dades la taula serà `centre_assignacio_docent`.

Per això, si fas consultes SQL manuals, has de buscar el nom amb guions baixos.
:::

#### 🧩 I en el nostre cas?
Si el nostre mòdul es diu `gestio_alumnes`, el prefix triat és `centre`. Per tant, els models serien:
- `centre.alumne`
- `centre.classe`
- `centre.event`

Això garantix, absència de xocs amb altres mòduls, identificació clara dels models i codi més net i coherent.

#### ✔ Resum per a recordar
- En Odoo, els models han de tindre un nom únic global.
- Per això utilitzem sempre `prefix.nom`.
- El prefix identifica el teu mòdul i evita col·lisions.
- Exemple correcte: `centre.alumne`. Incorrecte: `alumne`.
- El prefix no ha de ser el nom complet del mòdul; n’hi ha prou amb un nom curt i distintiu.

## Com es tradueix un model en la base de dades?

Al fixer models/alumne.py hem definit un model anomenat `centre.alumne` amb tres camps: `name`, `edat` i `curs`. Aquest model es traduirà en una taula a la base de dades amb les columnes corresponents. Cada camp és una instància d’una classe de `fields` que defineix el tipus de dada i les característiques del camp (per exemple, `required=True` indica que el camp és obligatori). A més, el camp `curs` és un camp de selecció que només pot prendre els valors definits en la llista de tuples. Si partim del diagrama ER, aquest model es representaria com una entitat `ALUMNE` amb els atributs `name`, `edat` i `curs`, on `name` és un atribut requerit.

:::{image} /_static/assets/img/Tema5/curs-alumne2.png
:alt: Model centre.alumne
:width: 200px
:align: center
:::

**Què és exactament un field en Odoo?**

En Odoo, cada camp (`fields.*`) és com una entrada del **diccionari de dades** del model. Cada vegada que declares un camp, li estàs dient a Odoo:
- Com es diu la columna(l'atribut) a la base de dades.
- Quin tipus de dada guarda.
- Quines condicions ha de complir (required, domain, selection, constraints).
- Com s’ha de mostrar a la interfície (string, help).
- I com es relaciona amb altres taules (Many2one, One2many, Many2many).

:::{caution}

Un `field`  no és només “una columna SQL”; és la definició completa del comportament d’eixa dada dins d’Odoo.

Un field en Odoo equival a una entrada de metadades

:::


Una vegada creat el model, Odoo s’encarrega de crear la taula a la base de dades i gestionar totes les operacions relacionades amb aquest model (crear, llegir, actualitzar, eliminar) a través de l’ORM (Object-Relational Mapping). Així, quan creem un registre d’alumne, Odoo tradueix aquesta acció en una consulta SQL que inserta les dades a la taula corresponent. 

Podriem discutir quins camps li calen a l'entitat ALUMNE, però això ja és una qüestió de disseny de la base de dades i del model de negoci que volem implementar. El més important és entendre com es defineix un model en Odoo i com es relaciona amb la base de dades. En el cas d'un alumne, el camp `name` s'ha considerat obligatori perquè volem assegurar que cada alumne té un nom associat. El camp `edat` és un enter que pot ser opcional, i el camp `curs` és una selecció que limita les opcions disponibles per a aquest camp. A més, podríem afegir més camps com `nia` (Número d’Identificació de l’Alumne), `tutor_id` (relació amb el tutor), etc., depenent de les necessitats del nostre model de dades. No obstat, caldrà tenir en compte les regles d’Odoo respecte a les claus primàries i les restriccions de camp, que veurem a continuació.

::: {admonition} 🔑 Regla d'or d'Odoo amb les claus primàries
:class: tip

En disseny teòric, podríem pensar que un atribut com el `nia` hauria de ser la clau primària perquè identifica unívocament l'alumne. Però en Odoo això **no es pot passar a taules així**.

Odoo imposa que totes les taules tinguen una PK tècnica anomenada `id` (entera i autonumèrica), i totes les relacions (`Many2one`, `One2many`, `Many2many`) treballen sobre eixe `id` intern.

Per tant, la pràctica recomanada és:
- Mantindre `id` com a clau subrogada (interna i transparent per a nosaltres).
- Tractar `nia` com a **clau natural** de negoci.

Perquè `nia` es comporte “com una PK” de cara al negoci, aplica sempre les dues regles:

1. `required=True` (equivalent a NOT NULL)
2. `_sql_constraints` amb `UNIQUE` (no repetits)

Exemple:

```python
from odoo import models, fields

class Alumne(models.Model):
    _name = 'centre.alumne'
    _description = 'Alumne del centre'

    nia = fields.Char(string="NIA", required=True)
    name = fields.Char(string="Nom", required=True)
    ...

    _sql_constraints = [
        ('nia_unique', 'unique(nia)', "El NIA ja existeix. Ha de ser únic."),
    ]
```

Així, la base de dades rebutjarà alumnes sense NIA o amb NIA duplicat.
:::


La manera que té Odoo de saber que volem crear un model propi dins del framework és que en Python la classe `Alumne` herete de `models.Model`. A la base de dades, Odoo crearà automàticament una taula anomenada `centre_alumne` amb les columnes `nia`, `name`, `edat` i `curs`. 



Quan afiges al model un camp de tipus `Many2one`, com `tutor_id`, Odoo crea una columna `tutor_id` que és una clau forana que apunta a la taula `res_partner` (que és on es guarden els contactes, inclosos els tutors). Així, Odoo s’encarrega de gestionar les relacions entre taules i garantir la integritat referencial.:
```python
from odoo import models, fields

class Alumne(models.Model):
    _name = 'centre.alumne'
    _description = 'Alumne del centre'

    nia = fields.Char(string="NIA", required=True)
    name = fields.Char(string="Nom", required=True, help="Nom complet de l'alumne")
    edat = fields.Integer(string="Edat", default=0)
    curs = fields.Selection(
        [('1eso','1r ESO'), ('2eso','2n ESO')],
        string="Curs"
    )
    _sql_constraints = [
        ('nia_unique', 'unique(nia)', "El NIA ja existeix. Ha de ser únic."),
    ]

    tutor_id = fields.Many2one('res.partner', string="Tutor/a")
    
```

Odoo:
- Crea/actualitza les columnes a la BD (`centre_alumne.name`, `centre_alumne.edat`, …).
- Enllaça `tutor_id` amb `res.partner` i aplica integritat relacional.

```{tikz}
\usetikzlibrary{shapes.geometric,positioning,calc}

\begin{tikzpicture}[
    font=\sffamily,
    % Estil per a les entitats (Rectangles)
    entity/.style={
        draw, thick, fill=white,
        minimum width=3.2cm, minimum height=1.1cm,
        align=center, font=\bfseries
    },
    % Estil per als atributs (Ovals)
    attribute/.style={
        draw, ellipse, fill=white,
        minimum width=2.2cm, minimum height=0.8cm,
        font=\small\itshape
    },
    % Estil per als triangles del rombe bicolor
    t_white/.style={
        draw, thick, fill=white,
        isosceles triangle, isosceles triangle apex angle=60,
        inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm
    },
    t_black/.style={
        draw, thick, fill=black,
        isosceles triangle, isosceles triangle apex angle=60,
        inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm
    }
]

%  1. ENTITATS 
\node[entity] (Alumne) {ALUMNE};
\node[entity, right=3.5cm of Alumne] (Tutor) {RES.PARTNER};

%  2. ATRIBUTS D'ALUMNE (Disposició en ventall) 
\node[attribute, above left=1.4cm and 2.8cm of Alumne.north] (nia) {\underline{nia}};
\node[attribute, above left=2.0cm and 0.8cm of Alumne.north] (edat) {edat};
\node[attribute, above=2.2cm of Alumne] (name) {name};
\node[attribute, above right=1.8cm and 1.2cm of Alumne.north] (curs) {curs};

%  3. ATRIBUT DE TUTOR 
\node[attribute, above=1.5cm of Tutor] (tutorid) {\underline{tutor\_id}};

%  4. CONNEXIONS OBLIQÜES DES DE PUNTS DIFERENTS 
% Nia ix de l'extrem esquerre de la cara superior (clau natural, subratllat)
\draw[thick] ([xshift=-1.3cm]Alumne.north) -- (nia.south);

% Edat ix de l'esquerra de la cara superior
\draw[thick] ([xshift=-0.8cm]Alumne.north) -- (edat.south);

% Curs ix de la dreta de la cara superior
\draw[thick] ([xshift=1cm]Alumne.north) -- (curs.south);

% Tutor_id vertical sobre Tutor
\draw[thick] (Tutor.north) -- (tutorid.south);

% Name ix del centre amb el cercle de 'required' pegat a l'oval
\draw[thick] (Alumne.north) -- (name.south) 
    node[pos=0.95, circle, draw, fill=white, inner sep=2pt] {};

%  5. RELACIÓ AMB ROMBE BICOLOR 
\path (Alumne.east) -- (Tutor.west) coordinate[midway] (midrel);

% Triangle Negre (apunta a Alumne - molts)
\node[t_black, rotate=-180, anchor=lower side] at (midrel) (tr_black) {};
% Triangle Blanc (apunta a Tutor - u)
\node[t_white, rotate=0, anchor=lower side] at (midrel) (tr_white) {};

% Unim les entitats amb els triangles
\draw[thick] (Alumne.east) -- (tr_black.apex);
\draw[thick] (Tutor.west) -- (tr_white.apex);

%  6. CARDINALITATS 
\node[above right=0.1cm of Alumne.east, font=\scriptsize\bfseries] {n};
\node[above left=0.1cm of Tutor.west, font=\scriptsize\bfseries] {1};

\end{tikzpicture}
```


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

Exemple bàsic d’ús en el model:
```python
from odoo import models, fields

class Alumne(models.Model):
    _name = 'centre.alumne'
    _description = 'Alumne del centre'

    # Tutor legal: només persones actives
    tutor_id = fields.Many2one(
        'res.partner', string="Tutor/a",
        domain="[('company_type','=','person'), ('active','=',True)]",
        ondelete='set null',
        help="Persona de contacte (pare/mare/tutor legal)"
    )

    # Empresa per a FEE/Dual: només empreses
    empresa_id = fields.Many2one(
        'res.partner', string="Empresa (FEE/Dual)",
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

El lector apreciarà que si el tutor és un partner, també ho pot ser un alumne, client, proveïdor, professor, etc. Això és la màgia de `res.partner`: una sola entitat per a tot tipus de contactes. A més, Odoo permet crear subtipus de partner mitjançant camps booleanos o etiquetes, per exemple `is_student` per marcar els partners que són alumnes. Així, pots tenir un partner que és al mateix temps client, tutor i alumne, i Odoo gestionarà tota la informació de manera integrada. Alehores, el diagrama ER serà recursiu, amb `res.partner` com a entitat central i relacions cap a ella mateixa per representar les jerarquies i els rols dels contactes.

### Traducció formal del model recursiu

Per a que el sistema siga capaç de gestionar la jerarquia dins de la mateixa taula, la traducció del diagrama anterior al model relacional segueix estes fórmules:

**1. Esquema de la relació (Taula):**

L'entitat `ALUMNE` es tradueix en una taula SQL que inclou els seus atributs i la clau forana per a la relació recursiva:

```{tikz}
\usetikzlibrary{shapes.geometric,positioning,calc}

\begin{tikzpicture}[
    font=\sffamily,
    % Estil per a l'entitat (Rectangle)
    entity/.style={
        draw, thick, fill=white,
        minimum width=2.5cm, minimum height=1cm,
        align=center, font=\bfseries
    },
    % Estil per als atributs (Ovals)
    attribute/.style={
        draw, ellipse, fill=white,
        minimum width=1.2cm, minimum height=0.6cm,
        font=\small\itshape
    },
    % Estil per als triangles del rombe bicolor
    t_white/.style={
        draw, thick, fill=white,
        isosceles triangle, isosceles triangle apex angle=60,
        inner sep=0pt, minimum width=3mm, minimum height=4.5mm
    },
    t_black/.style={
        draw, thick, fill=black,
        isosceles triangle, isosceles triangle apex angle=60,
        inner sep=0pt, minimum width=3mm, minimum height=4.5mm
    }
]

% 1. L'ENTITAT A
\node[entity] (A) {A};

% 2. ELS ATRIBUTS D'A (Com al dibuix)
\node[attribute, left=0.8cm of A] (a0) {\underline{a0}};
\node[attribute, below left=0.5cm and 0.1cm of A] (a1) {a1};

\draw[thick] (A.west) -- (a0.east);
\draw[thick] (A.south west) -- (a1.north east);

% 3. EL LLAÇ RECURSIU (RELACIÓ R)
% Camí del llaç: ix per dalt, va a la dreta i baixa
\draw[thick] (A.north) -- ++(0,1cm) coordinate (top) -- ++(2.5cm,0) coordinate (corner) -- (A.east -| corner) -- (A.east);

% 4. EL ROMBE BICOLOR (Al lateral, com al dibuix a mà)
\coordinate (midR) at ($(corner)!0.5!(A.east -| corner)$);

% Segons la teua imatge: Triangle negre (N) a la banda de l'entitat, blanc (1) a la banda del bucle
\node[t_black, rotate=90, anchor=lower side] at (midR) (tr_black) {};
\node[t_white, rotate=-90, anchor=lower side] at (midR) (tr_white) {};



% 5. CARDINALITATS (Intercanviades segons la imatge a mà: N a l'entitat, 1 al bucle)
\node[right=0.1cm of A.east, yshift=0.2cm, font=\small\bfseries] {n};
\node[above=0.1cm of A.north, xshift=-0.2cm, font=\small\bfseries] {1};

% 6. ATRIBUT DE RELACIÓ r (minúscula, depenent del rombe)
\node[attribute, above left=0.7cm and -1.8cm of tr_black] (r_attr) {r};
\draw[thick] (tr_black.lower side) -- (r_attr.south west);

\end{tikzpicture}
```

L'entitat $A$ (que en el nostre cas pràctic serà `res.partner`) absorbeix la relació $R$ de la següent manera:

```{math}
A = (\underline{a_0}, a_1, a_0', r)
```

**2. Definició dels components:**
* **$a_0$ (Clau Primària - PK):** Identificador únic del partner (el camp `id` en Odoo).
* **$a_1$ (Atributs):** Dades pròpies de l'entitat (nom, edat, curs, etc.).
* **$a_0'$ (Clau Aliena - FK):** El camp `tutor_id` que apunta a un $a_0$ de la mateixa taula.
* **$r$ (Atribut de relació):** Dada extra que només té sentit si existeix el vincle (per exemple, la data d'assignació del tutor).

**3. Restriccions d'Integritat (RI):**
* **Integritat Referencial:** La clau aliena ha d'apuntar necessàriament a un registre existent o ser nula per a evitar orfes: 

    ```{math}
    a_0' \rightarrow A(a_0)
    ```
* **Restricció d'existència de l'atribut $r$:** Com s'ha indicat en el disseny, si no hi ha una relació establerta, l'atribut associat ha de ser nul:

```{math}
\mathrm{si}\;\mathrm{nul}(a_0') \rightarrow \mathrm{nul}(r)
```

Esta traducció formal és la que Odoo aplica internament. En els pròxims apartats voreu que eixa clau aliena ($a_0'$) es programa en Python mitjançant un camp de tipus `Many2one` que apunta al mateix model, i que la restricció d'integritat ($RI$) la controlarem més avant amb la lògica de negoci del mòdul.

De moment, el que ens interessa és vore com podem posar en pràctica este disseny utilitzant l'herència, per a no haver de recrear de zero tota la infraestructura de contactes que Odoo ja ens ofereix.

### Herència de models en Odoo


En l’exemple anterior hem creat un model nou heretant de `models.Model`. Ara bé, com ja hem vist en molts casos no cal crear un model des de zero, sinó **ampliar un model existent** d’Odoo. El cas més habitual és estendre `res.partner` des del teu mòdul, utilitzant `_inherit`.

Per afegir camps nous a `res.partner` (per exemple, per marcar si un partner és un alumne i guardar el seu expedient), només cal fer:
```python
from odoo import models, fields

class ResPartner(models.Model):
    _inherit = 'res.partner'

    is_student = fields.Boolean(string="És alumne/a")
    expedient = fields.Char(string="Codi d’expedient")
```
Aquest codi no crea un model nou, sinó que **modifica el model `res.partner`** afegint dos camps nous. Així, tots els partners del sistema (clients, proveïdors, alumnes, tutors…) tindran aquests camps disponibles. Això possiblement no és el millor disseny per a un cas real, però serveix per entendre com funciona l’herència en Odoo.

En Odoo tenim dos mecanismes principals per heretar models, i la diferència clau és esta:

- `_inherit` (extensió del model): **modifiques un model existent** (p. ex. `res.partner`) afegint camps o mètodes. No crees “un altre model paral·lel”; estàs ampliant el mateix.
- `_inherits` (delegació): **crees un model nou** (p. ex. `centre.professor`) que es connecta a un model existent amb un `Many2one` obligatori. Hi ha taules separades i Odoo et deixa accedir als camps del model pare com si foren del fill. Seria l'especialització real d'un model.

Traduït a base de dades:

- Amb `_inherit` (sense `_name`), continues treballant sobre la taula del model original (`res_partner`).
- Amb `_inherits`, tens dues taules (per exemple `centre_professor` + `res_partner`) enllaçades per una FK.

Exemple mental ràpid:

- `_inherit`: “estic ampliant Contactes”.
- `_inherits`: “estic creant Professors, però reutilitze Contactes per al nom/adreça/email”.

#### Resum operatiu: `_inherit` vs `_inherits`

En Odoo, no solem “tocar” directament un model existent modificant el seu codi original. En lloc d’això, usem herència:

- **`_inherit`** (extensió simple): afegim camps i mètodes a un model existent sense crear-ne un de nou.
  ```python
  class ResPartner(models.Model):
      _inherit = 'res.partner'
      is_student = fields.Boolean(string="És alumne/a")
  ```
  Resultat: una sola taula (`res_partner`) amb camps originals + nous.

- **`_inherits`** (delegació): creem un model nou recolzat en un model base, amb taules separades enllaçades per clau forana.
  ```python
  class Alumne(models.Model):
      _name = 'centre.alumne'
      _inherits = {'res.partner': 'partner_id'}
      partner_id = fields.Many2one('res.partner', ondelete='restrict', required=True)
  ```
  Resultat: dues taules (`centre_alumne` + `res_partner`) relacionades.

**Avantatge pràctic**: amb `_inherit`, amplies el model existent sense trencar compatibilitat funcional.

:::{caution}
**Nota important: en un cas real, l’Alumne sovint hauria de derivar de `res.partner`**

Per coherència funcional, l’alumnat sol reutilitzar la infraestructura de contactes (`name`, adreça, telèfon, email, NIF, etc.).

En eixos casos, és habitual usar `_inherits`:

```python
from odoo import models, fields

class Alumne(models.Model):
    _name = 'centre.alumne'
    _description = 'Alumne del centre'
    _inherits = {'res.partner': 'partner_id'}

    partner_id = fields.Many2one('res.partner', ondelete='restrict', required=True)
    nia = fields.Char(string="NIA", required=True)
    curs = fields.Selection(
        [('1eso','1r ESO'), ('2eso','2n ESO')],
        string="Curs"
    )

    _sql_constraints = [
        ('nia_unique', 'unique(nia)', "El NIA ja existeix. Ha de ser únic."),
    ]
```

Així, cada alumne tindria un registre a `res_partner` (dades generals) i un registre a `centre_alumne` (dades acadèmiques) vinculats.
:::

::: {admonition} Com resol Odoo l’agregació i l’especialització
:class: note

En termes de modelatge:

- **Especialització** (relació “és-un”): en Odoo la fem amb **herència**.
    - Si vols ampliar un model existent sense crear-ne un de nou, usa `_inherit`.
    - Si vols un model nou amb identitat pròpia però reutilitzant un model base, usa `_inherits`.

- **Agregació** (relació “té-un / té-molts”): en Odoo normalment **no** es resol amb herència, sinó amb **camps relacionals**:
    - `Many2one` (té-un)
    - `One2many` (té-molts)
    - `Many2many` (molts-a-molts)

En teoria ER, l’especialització també porta **restriccions**. En Odoo es tradueixen així:

- **Disjunta vs solapada**
    - **Disjunta**: una instància només pot pertànyer a un subtipus.
        En Odoo, ho controles amb un camp discriminador (`Selection`) + constriccions (`@api.constrains` o `_sql_constraints`). Per exemple, si un `res.partner` pot ser “alumne” o “professor”, però no els dos alhora. Això ho controlaríem amb un camp `role` i una restricció que no permet guardar un partner amb rol “alumne/professor” si ja té un altre rol.

    - **Solapada**: una instància pot pertànyer a diversos subtipus.
        En Odoo, sol modelar-se amb diversos booleans/etiquetes/relacions, i validacions de coherència quan calga. Per exemple, si un `res.partner` pot ser “alumne” i “tutor” al mateix temps, i això no és un problema.

- **Total vs parcial**
    - **Total**: tota instància del supertipus ha d’estar especialitzada.
        En Odoo, es força amb camps requerits, dominis i validacions de negoci (per exemple, no permetre guardar un `res.partner` “alumne/professor” sense rol).
    - **Parcial**: només algunes instàncies del supertipus tenen subtipus.
        En Odoo és el cas habitual: `res.partner` pot tindre molts usos i només una part ser alumnat, professorat, proveïdors, etc. Per això, normalment no es força que tots els partners siguen alumnes o professors.

Sobre agregació en sentit estricte (ER):

- En model relacional/Odoo, normalment la “agregació” es materialitza com una **entitat associativa** (un model propi) + relacions.
- Exemple típic: una matrícula no és “herència” d’alumne ni de mòdul; és una entitat `centre.matricula` amb `Many2one` a alumne i `Many2one` a mòdul, i amb atributs propis (data, estat, nota, convocatòria).

Regla pràctica ràpida:
- Si el nou concepte és una “variant” d’un altre → herència (`_inherit` / `_inherits`).
- Si el nou concepte només “es relaciona” amb un altre → relacions (`Many2one`, `One2many`, `Many2many`).

Resum mental:
- **“és-un”** → especialització/herència.
- **“té-un / participa-en”** → relació/agregació (camps relacionals).
:::

**I el model relacional, en què queda?**


Quan passem d’ER a relacional en Odoo, la idea és directa:

- **Entitat** ER → **taula** (model Odoo, `_name`).
- **Atribut** → **camp** (`fields.Char`, `fields.Date`, `fields.Float`, etc.).
- **Identificador** → `id` (PK interna d’Odoo) i, si cal, clau funcional amb `_sql_constraints` (per exemple, NIA únic).
- **Relacions**:
    - 1:N → `Many2one` al costat N (+ `One2many` invers)
    - N:M → `Many2many` o model intermedi si la relació té atributs propis
    - 1:1 → `Many2one` amb restricció `unique` (si realment vols unicitat estricta)
    - **Ternària** (3 entitats) → model associatiu propi amb **tres `Many2one`** (una FK a cada entitat). Si la combinació ha de ser única, afegim `_sql_constraints`.

Exemple típic: **Professor imparteix Mòdul a Grup**.

```{tikz}
\usetikzlibrary{shapes.geometric, positioning, calc}

\begin{tikzpicture}[
    font=\sffamily,
    % Estil per a les entitats (Rectangles)
    entity/.style={
        draw, thick, fill=white,
        minimum width=3.2cm, minimum height=1.1cm,
        align=center, font=\bfseries
    },
    % Estil per als atributs (Ovals)
    attribute/.style={
        draw, ellipse, fill=white,
        minimum width=2.2cm, minimum height=0.8cm,
        font=\small\itshape
    }
]

%  1. ENTITATS (Posició per a relació ternària) 
\coordinate (Rel) at (0,0);

\node[entity] (Professor) at (-4.0,1.6) {PROFESSOR};
\node[entity] (Grup) at (4.0,1.6) {GRUP};
\node[entity] (Modul) at (0,-2.5) {MÒDUL};

%  2. RELACIÓ TERNÀRIA EN TRIANGLES (estil E-R clàssic) 
% Quatre triangles congruents: 3 negres + 1 blanc central
% (el triangle blanc té el mateix tamany que els negres)
\filldraw[fill=black, draw=black, thick]
    (-1.20,0.90) -- (0,0.90) -- (-0.60,-0.15) -- cycle;    % esquerra
\filldraw[fill=black, draw=black, thick]
    (1.20,0.90) -- (0,0.90) -- (0.60,-0.15) -- cycle;      % dreta
\filldraw[fill=black, draw=black, thick]
    (0,-1.20) -- (-0.60,-0.15) -- (0.60,-0.15) -- cycle;   % inferior
\filldraw[fill=white, draw=black, thick]
    (0,0.90) -- (-0.60,-0.15) -- (0.60,-0.15) -- cycle;    % central

\node[font=\small] at (2.25,0.10) {impartir};

%  3. ATRIBUTS DE LA RELACIÓ 
\node[attribute] (id) at (0.65,2.20) {\underline{id} (Odoo PK)};
\draw[dashed] (Rel) -- (id);

%  4. CONNEXIONS (Relació ternària) 
% Les unions ixen de cada punta del símbol ternari
\draw[thick] (Professor.east) -- (-1.20,0.90) node[pos=0.74, above] {n};
\draw[thick] (Grup.west) -- (1.20,0.90) node[pos=0.74, above] {n};
\draw[thick] (Modul.north) -- (0,-1.20) node[pos=0.74, right] {n};

%  5. EXPLICACIÓ DE LA RESTRICCIÓ 
\node[draw, dashed, fill=white, font=\scriptsize, align=left] (Const) at (3.35,-2.25) {
    sql\_constraints:\\
    unique(professor, modul, grup)
};
\draw[->, bend left=18, gray] (Const) to (0,-0.20);

\end{tikzpicture}
```


```python
class AssignacioDocent(models.Model):
    _name = 'centre.assignacio.docent'
    _description = 'Assignació docent (professor-mòdul-grup)'

    professor_id = fields.Many2one('hr.employee', required=True, ondelete='restrict')
    modul_id = fields.Many2one('centre.modul', required=True, ondelete='restrict')
    grup_id = fields.Many2one('centre.grup', required=True, ondelete='restrict')

    _sql_constraints = [
        (
            'uniq_assignacio',
            'unique(professor_id, modul_id, grup_id)',
            'Esta assignació ja existeix.'
        ),
    ]
```

**Traducció formal de la relació ternària**

En este cas, la relació **Professor imparteix Mòdul a Grup** es materialitza en Odoo com una taula associativa pròpia:

```{math}
centre\_assignacio\_docent = (\underline{id}, professor\_id, modul\_id, grup\_id)
```

**Components de l'esquema:**

- **$id$ (PK):** clau primària tècnica que Odoo crea automàticament.
- **$professor\_id$ (FK):** referència a `hr.employee(id)`.
- **$modul\_id$ (FK):** referència a `centre.modul(id)`.
- **$grup\_id$ (FK):** referència a `centre.grup(id)`.

**Restriccions d'integritat:**

- Integritat referencial:

    ```{math}
    professor\_id \rightarrow hr\_employee(id)
    ```

    ```{math}
    modul\_id \rightarrow centre\_modul(id)
    ```

    ```{math}
    grup\_id \rightarrow centre\_grup(id)
    ```

- Unicitat de la relació:

```{math}
\operatorname{unique}(professor\_id, modul\_id, grup\_id)
```

És a dir, la mateixa combinació de professor, mòdul i grup no pot aparéixer dues vegades en la taula.

L’estructura d’una `_sql_constraints` és una llista de tuples amb tres elements:
`(nom, definicio_sql, missatge_error)`.

- `uniq_assignacio`: nom intern de la restricció en la BD. Ha de ser únic.
- `unique(...)`: clau única composta. Ací diem a PostgreSQL que no permeta dos registres amb la mateixa combinació de professor, mòdul i grup.
- Missatge d’error: text que Odoo mostra a l’usuari si intenta duplicar una assignació.

Per què és important en esta relació associativa?

- Sense el `unique`, podries crear la mateixa assignació moltes vegades per error.

Exemple:
- Professor A + FOL + Grup 1 → vàlid (únic).
- Professor A + FOL + Grup 1 (repetit) → error de restricció.

Nota: una relació n-ària **no** és equivalent, en general, a diverses relacions binàries separades; per això en Odoo la representem amb un model intermedi explícit.

### 🗝️ Claus alienes i integritat relacional

En Odoo, cada vegada que definim un camp `Many2one`, el framework crea automàticament una **clau aliena** (*Foreign Key*) a PostgreSQL.

Esta clau és la que garanteix que no hi haja **registres orfes**: per exemple, que un alumne no puga estar assignat a un curs que no existeix.

#### L’atribut `ondelete`

És el mecanisme que defineix què passa amb els registres “fills” (p. ex., alumnes) quan s’esborra el registre “pare” (p. ex., un curs o un tutor).

Tenim tres opcions principals:

- `ondelete='set null'` (**opció per defecte**):
    - Si esborres el pare, el camp del fill es queda buit (`NULL`).
    - Exemple: si esborres un tutor, l’alumne continua existint, però `tutor_id` queda buit.

- `ondelete='restrict'` (**màxima seguretat**):
    - Impedix esborrar el registre pare si hi ha fills que el fan servir.
    - Exemple: si intentes esborrar un curs amb alumnes matriculats, Odoo llança error i no ho permet.

- `ondelete='cascade'` (**molt perillós**):
    - Si esborres el pare, s’esborren automàticament tots els fills relacionats.
    - Exemple: si esborres un curs, podries esborrar tot l’alumnat relacionat. Usa-ho amb molta cura.

**Exemple de codi amb claus alienes**

```python
class Alumne(models.Model):
    _name = 'centre.alumne'

    # Restrict: no podem esborrar un curs si hi ha alumnes matriculats
    curs_id = fields.Many2one('centre.curs', string="Curs", ondelete='restrict')

    # Set null: si el tutor marxa, l'alumne continua existint
    tutor_id = fields.Many2one('res.partner', string="Tutor/a", ondelete='set null')
```

**Resum de claus alienes en Odoo**
En la taula de relacions, les claus alienes són el mecanisme que garanteix la integritat referencial. En Odoo, es gestionen automàticament amb els camps `Many2one`, i el comportament en cas d’esborrat del registre pare es controla amb l’atribut `ondelete`. És fonamental triar l’opció correcta (`set null`, `restrict` o `cascade`) segons la lògica de negoci i el risc associat a cada cas. En la taula següent es resumeixen les opcions i les seues implicacions:
| Concepte | Descripció |
| --- | --- |
| FK (Clau aliena) | Implementada per un camp `Many2one`. |
| Integritat | Garantida per PostgreSQL i gestionada per Odoo. |
| `restrict` | Bloqueja l’esborrat del pare si hi ha fills. |
| `set null` | Neteja el vincle si s’esborra el pare (cas habitual). |
| `cascade` | Esborra els fills en esborrar el pare (risc alt). |


:::{admonition} Nota sobre `ondelete` quan relaciones amb `res.partner`
:class: tip

No totes les relacions cap a `res.partner` s'han de tractar igual:

- **Relacions funcionals** com `tutor_id`, `contacte_empresa_id` o similars: normalment convé `ondelete='set null'`, perquè si s'esborra el contacte, el registre principal pot continuar existint.
- **Relacions estructurals** com `partner_id` en un model amb `_inherits = {'res.partner': 'partner_id'}`: ací és habitual usar `ondelete='restrict'`, perquè eixe `partner_id` forma part de la identitat del registre.

Per tant, la regla pràctica és:

- `set null` per a enllaços opcionals de negoci
- `restrict` per a enllaços estructurals o obligatoris
- `cascade` només en casos molt justificats
:::



### 🛡️ Comprovació de dades: `@api.constrains` vs `_sql_constraints`

Ja hem vist les `_sql_constraints` (úniques o comprovacions SQL simples), però quan la regla és més complexa (per exemple, validar que l’edat siga positiva), usem constraints en Python:

```python
from odoo import models, fields, api
from odoo.exceptions import ValidationError

class Alumne(models.Model):
    _name = 'centre.alumne'
    edat = fields.Integer(string="Edat")

    @api.constrains('edat')
    def _check_edat_positiva(self):
        for record in self:
            if record.edat < 0:
                raise ValidationError("L'edat no pot ser negativa!")
```



En resum: el **model relacional** és la implementació física; ER és la vista conceptual, i Odoo ho materialitza amb models + camps + claus/validacions.



## Guia de traducció: De l'ER a taules d'Odoo

Abans de començar a programar, és fonamental saber com traduir les estructures del diagrama conceptual (ER) a models d'Odoo. Basant-nos en la simbologia de triangles (blancs per a cardinalitat 1, negres per a molts), seguirem aquestes regles:

### Atributs multivalents (El cas del telèfon)

Quan una entitat té un atribut que pot contindre múltiples valors per a un mateix registre (atribut multivalent), la traducció al model relacional genera dues taules per a evitar grups repetitius i complir amb la Primera Forma Normal (1FN).

```{tikz}
\usetikzlibrary{shapes.geometric,positioning,calc}

\begin{tikzpicture}[
    font=\sffamily,
    entity/.style={draw, thick, fill=white, minimum width=2.5cm, minimum height=1cm, align=center, font=\bfseries},
    attribute/.style={draw, ellipse, fill=white, minimum width=1.5cm, minimum height=0.7cm, font=\small\itshape},
    % Estil per a atributs multivalents (doble oval)
    multi_attribute/.style={draw, ellipse, double, fill=white, minimum width=1.5cm, minimum height=0.7cm, font=\small\itshape}
]

% 1. L'ENTITAT A
\node[entity] (A) {A};

% 2. ATRIBUT CLAU a0
\node[attribute, above left=1cm and 0.5cm of A] (a0) {\underline{a0}};
\draw[thick] (A.north west) -- (a0.south east);

% 3. ATRIBUT MULTIVALENT a1 (Amb la "n" del teu dibuix)
\node[attribute, below left=1cm and 0.5cm of A] (a1) {a1};
\draw[thick] (A.south west) -- (a1.north east) node[midway, left, font=\scriptsize] {n};

% 4. ALTRES ATRIBUTS (...)
\node[attribute, right=1cm of A] (punts) {...};
\draw[thick] (A.east) -- (punts.west);

\end{tikzpicture}
```

**1. Esquema de l'entitat principal (A):**
L'entitat manté els seus atributs atòmics, però l'atribut multivalent "desapareix" d'esta taula:

```{math}
A = (\underline{a_0}, \dots)
```

**2. Esquema de la nova taula per a l'atribut multivalent (B):**
Es crea una taula específica (B) on la clau és composta, formada per la clau de l'entitat pare i el propi atribut:

```{math}
B = (\underline{a_0, a_1})
```

**3. Restriccions d'Integritat (RI):**
* **Clau Aliena (CA):** El camp $a_0$ de la taula B referencia a la taula principal per a mantindre el lligam:

    ```{math}
    C.Aliena: a_0 \rightarrow A(a_0)
    ```

    > **Nota:** **Sempre que la relació siga 1:M** (un registre de A pot tindre molts de B, però cada B pertany a un únic A), la taula B "es lleva la clau" simple per a convertir-la en una clau composta $(\underline{a_0 + a_1})$. Això garanteix que no es repetisca el mateix valor multivalent per al mateix registre.

    > **Exemple:** Si `A` és `CLIENT` i `a_1` és `TELÈFON`, i la relació és **1:M** (un client pot tindre molts telèfons, però cada telèfon pertany a un únic client):
    > - Taula `A` (CLIENTS): $(\underline{id\_client}, nom, ...)$
    > - Taula `B` (TELÈFONS): $(\underline{id\_client, telèfon})$ ← clau composta

    > **En canvi**, si la relació fora **M:M** (molts clients poden compartir telèfons o molts telèfons poden assignar-se a molts clients), caldria una **tercera taula associativa** amb dues claus alienes, no una clau multivalent.

    > En Odoo: el cas 1:M se soluciona amb `One2many` + `Many2one` en el model fill (`telèfon_id = Many2one('client')`), no amb un camp text repetit. El cas M:M es modela amb `Many2many` o amb un model intermedi explícit si la relació té atributs propis.


Aplicat al nostre exemple de la pràctica 6, amb el model de **Music** (atribut multivalent *telèfon*), la traducció queda exactament igual que el patró anterior:

- **Entitat principal (A):** `agrupaciomusical.music` (guarda les dades atòmiques de cada music de la colla).
- **Taula/Model del multivalent (B):** `agrupaciomusical.music.phone` (una fila per cada telèfon).
- **Lligam 1:M:** cada telèfon pertany a un únic music (`Many2one`) i cada music pot tindre molts telèfons (`One2many`).

Per això, **no** usem camps `phone1`, `phone2`, etc.; usem un model fill relacionat:

```python
class Music(models.Model):
    _name = 'agrupaciomusical.music'

    name = fields.Char(string="Nom", required=True)
    phone_ids = fields.One2many(
        'agrupaciomusical.music.phone',
        'music_id',
        string="Telèfons"
    )


class MusicPhone(models.Model):
    _name = 'agrupaciomusical.music.phone'

    music_id = fields.Many2one(
        'agrupaciomusical.music',
        string="Músic",
        required=True,
        ondelete='cascade'
    )
    phone = fields.Char(string="Telèfon", required=True)

    _sql_constraints = [
        (
            'uniq_music_phone',
            'unique(music_id, phone)',
            'Este telèfon ja està registrat per a este músic.'
        )
    ]
```

### Traducció d'atributs multivalents compostos

Quan un atribut és alhora multivalent (té $n$ valors) i compost (es divideix en sub-atributs), la traducció al model relacional segueix el patró de creació d'una taula associada per a mantindre l'atomicitat.


```{tikz}
\usetikzlibrary{shapes.geometric,positioning,calc}

\begin{tikzpicture}[
    font=\sffamily,
    entity/.style={draw, thick, fill=white, minimum width=2.5cm, minimum height=1cm, align=center, font=\bfseries},
    attribute/.style={draw, ellipse, fill=white, minimum width=1.5cm, minimum height=0.7cm, font=\small\itshape}
]

% 1. L'ENTITAT A
\node[entity] (A) {A};

% 2. ATRIBUT CLAU a0
\node[attribute, above left=1.2cm and 0.5cm of A] (a0) {\underline{a0}};
\draw[thick] (A.north west) -- (a0.south east);

% 3. L'ATRIBUT COMPOST RAMIFICAT
% Punt de ramificació
\coordinate (ramificacio) at ($(A.east) + (1.5cm, 0)$);

% Atributs fulla
\node[attribute, above right=0.8cm and 0.5cm of ramificacio] (a1) {a1};
\node[attribute, right=0.5cm of ramificacio] (a2) {a2};
\node[attribute, below right=0.8cm and 0.5cm of ramificacio] (a3) {a3};

% Connexions
\draw[thick] (A.east) -- (ramificacio) 
    node[midway, above, font=\small] {a}
    node[midway, below, font=\small] {n};
\draw[thick] (ramificacio) -- (a1.west);
\draw[thick] (ramificacio) -- (a2.west);
\draw[thick] (ramificacio) -- (a3.west);

\end{tikzpicture}
```


**1. Esquema de l'entitat principal (A):**
L'atribut compost multivalent desapareix de la taula principal per a evitar grups repetitius:

```{math}
A = (\underline{a_0}, \dots)
```

**2. Esquema de la taula de l'atribut (B):**
Es crea una taula que conté la clau de l'entitat principal i tots els sub-atributs que formaven el compost. La clau primària serà la combinació de tots ells (o una part, depenent de la unicitat):

```{math}
B = (\underline{a_0, a_1, a_2, a_3})
```

**3. Restriccions d'Integritat (RI):**
* **Clau Aliena (CA):** El camp $a_0$ de la taula B referencia necessàriament a la taula principal:

```{math}
C.Aliena: a_0 \rightarrow A(a_0)
```

> **Exemple d'Odoo (Adreces de músics):**  Imaginem que un músic pot tindre diverses adreces (multivalent) i que cada adreça es compon de carrer, número i població (compost). En Odoo, no podem crear una llista de camps dins de la mateixa classe; hem de crear un model per a l'entitat principal i un altre per a l'atribut multivalent compost.


```{tikz}
\usetikzlibrary{shapes.geometric,positioning,calc}
\begin{tikzpicture}[
    font=\sffamily,
    % Estil per a les entitats (Rectangles)
    entity/.style={
        draw, thick, fill=white,
        minimum width=3.2cm, minimum height=1.1cm,
        align=center, font=\bfseries
    },
    % Entitat multivalent (doble contorn)
    multientity/.style={entity, double, double distance=1pt},
    % Estil per als atributs (Ovals)
    attribute/.style={
        draw, ellipse, fill=white,
        minimum width=2.2cm, minimum height=0.8cm,
        font=\small\itshape
    },
    % Estil per als triangles del rombe bicolor
    t_white/.style={
        draw, thick, fill=white,
        isosceles triangle, isosceles triangle apex angle=60,
        inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm
    },
    t_black/.style={
        draw, thick, fill=black,
        isosceles triangle, isosceles triangle apex angle=60,
        inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm
    }
]
%  1. ENTITATS 
\node[entity] (P) {MÚSIC};
\node[multientity, right=3cm of P] (A) {ADREÇA};

%  2. ATRIBUTS COMPOSTOS D'ADREÇA 
\node[attribute, above=1.4cm of A.east] (c) {carrer};
\node[attribute, right=1cm of A] (ci) {número};
\node[attribute, below right=1.1cm and 0.10cm of A.east] (cp) {població};

\draw[thick] (A.north) -- (c.south west);
\draw[thick] (A.east) -- (ci.west);
\draw[thick] (A.south) -- (cp.north west);

%  3. RELACIÓ 1:N AMB ROMBE BICOLOR 
\path (P.east) -- (A.west) coordinate[midway] (midrel);

% Triangle blanc cap a MÚSIC (costat 1)
\node[t_white, rotate=-180, anchor=lower side] at (midrel) (tr_white) {};
% Triangle negre cap a ADREÇA (costat n)
\node[t_black, rotate=0, anchor=lower side] at (midrel) (tr_black) {};

\draw[thick] (P.east) -- (tr_white.apex);
\draw[thick] (A.west) -- (tr_black.apex);

%  4. CARDINALITATS I ETIQUETA DE RELACIÓ 
\node[above right=0.08cm of P.east, font=\scriptsize\bfseries] {1};
\node[above left=0.08cm of A.west, font=\scriptsize\bfseries] {n};
\node[font=\scriptsize\itshape, below=0.3cm of midrel] {té};
\end{tikzpicture}
```

#### Implementació en Python (Odoo)



En aquest cas, `ADREÇA` és una **entitat dèbil** perquè:
1. La seua existència depèn completament de `MÚSIC` (no pot haver-hi adreça sense músic).
2. La seua identificació és **composta**: una adreça es distingeix pels seus atributs (carrer, número, població) **dins del context d'un músic**.

Per tant, la taula `agrupaciomusical_music_adreca` ha de reflectir esta dependència en la base de dades.

```python
from odoo import models, fields

class Music(models.Model):
    _name = 'agrupaciomusical.music'
    _description = 'Músic de l''agrupació'

    name = fields.Char(string="Nom", required=True)
    # Relació One2many per a llistar totes les seues adreces
    adreca_ids = fields.One2many(
        'agrupaciomusical.music.adreca', 
        'music_id', 
        string="Adreces"
    )


class MusicAdreca(models.Model):
    _name = 'agrupaciomusical.music.adreca'
    _description = 'Adreça del músic (entitat dèbil)'

    # Clau Aliena cap al músic (participació total obligatòria)
    # ondelete='cascade' garanteix que si s'esborra el músic, s'esborren totes les adreces
    music_id = fields.Many2one(
        'agrupaciomusical.music', 
        string="Músic", 
        required=True,
        ondelete='cascade'
    )
    
    # Sub-atributs del compost: identifiquen de manera única l'adreça dins del músic
    carrer = fields.Char(string="Carrer", required=True)
    numero = fields.Integer(string="Número", required=True)
    poblacio = fields.Char(string="Població", default="Tavernes de la Valldigna", required=True)

    # Restricció de clau composta: la combinació (music_id, carrer, numero, poblacio)
    # ha de ser única per evitar duplicar la mateixa adreça per a un mateix músic
    _sql_constraints = [
        (
            'uniq_music_adreca',
            'unique(music_id, carrer, numero, poblacio)',
            "Esta adreça ja està registrada per a este músic."
        )
    ]
```

**Explicació dels elements clau:**

1. **`required=True` en `music_id`:** Implementa la **participació total** (doble ratlla en ER): una adreça no pot existir sense un músic associat. Odoo rebutjarà qualsevol intent de crear una adreça sense músic.

2. **`ondelete='cascade'`:** Implementa la **dependència existencial** (característica de les entitats dèbils): si s'esborra un músic, Odoo **automàticament esborrarà** totes les seues adreces. No quedaran adreces orfes.

3. **`_sql_constraints` amb clau composta:** Implementa la **identificació relativa** de l'entitat dèbil. La taula base de dades tindrà una restricció `UNIQUE` que garanteix que:
   - No es pot repetir la mateixa combinació de `(music_id, carrer, numero, poblacio)`.
   - Això significa que un músic pot tindre múltiples adreces, però cadascuna ha de ser única (no pot haver-hi dues adreces idèntiques per al mateix músic).

**Traducció formal al model relacional:**

L'esquema de la taula `agrupaciomusical_music_adreca` queda així:

```{math}
agrupaciomusical\_music\_adreca = (\underline{music\_id, carrer, numero, poblacio})
```

On la clau primària és la combinació dels quatre camps. La clau aliena `music_id` referencia `agrupaciomusical_music(id)` i es força en cascada per garantir que no hi ha adreces sense músic.


### Cardinalitat en relacions ternàries
En Odoo, les ternàries s'implementen sempre amb un **model associatiu** (com `agrupaciomusical.convocatoria`). El que defineix la lògica de negoci és la restricció d'unicitat (`_sql_constraints`):

| Tipus de Ternària | Triangles Blancs | On posar el `unique(...)`? | Lògica Odoo |
| --- | --- | --- | --- |
| **M:N:P** | 0 | `(A, B, C)` | Qualsevol combinació és vàlida (cap element "mana"). |
| **1:M:N** | 1 (a C) | `(A, B)` | La parella A i B ja determina un únic C. |
| **1:1:M** | 2 (a B i C) | `(A, C)` o `(A, B)` | Amb dos elements identifiquem la resta. |
| **1:1:1** | 3 | `(A)`, `(B)`, `(C)` | Cada element és únic en tota la taula (exclusivitat absoluta). |

:::{tip}
**El triangle blanc "mana":** L'entitat que té el triangle blanc queda **fora** del `unique(...)` compost. Això força que la combinació de les altres dues siga la que identifique el registre de manera única.
:::


##### Implementació de les restriccions segons el cas:

1. **Cas Estàndard (M:N:P):** Unicitat de la tripleta completa.

```{tikz}
\usetikzlibrary{shapes.geometric, positioning, calc}

\begin{tikzpicture}[
    font=\sffamily,
    % Estil per a les entitats (Rectangles)
    entity/.style={
        draw, thick, fill=white,
        minimum width=3.2cm, minimum height=1.1cm,
        align=center, font=\bfseries
    },
    % Estil per als atributs (Ovals)
    attribute/.style={
        draw, ellipse, fill=white,
        minimum width=2.2cm, minimum height=0.8cm,
        font=\small\itshape
    }
]

%  1. ENTITATS (Posició original per a relació ternària M:N:P) 
\coordinate (Rel) at (0,0);

\node[entity] (A) at (-4.0,1.6) {A};
\node[entity] (B) at (4.0,1.6) {B};
\node[entity] (C) at (0,-2.5) {C};

%  2. ATRIBUTS CLAU DE CADA ENTITAT 
\node[attribute, above right=0.6cm and 0.2cm of A] (a0) {\underline{a0}};
\node[attribute, above left=0.6cm and 0.2cm of B] (b0) {\underline{b0}};
\node[attribute, above left=0.6cm and 0.2cm of C] (c0) {\underline{c0}};

%  3. CONNEXIONS DELS ATRIBUTS A LES ENTITATS 
\draw[thick] (A.north) -- (a0.south west);
\draw[thick] (B.north) -- (b0.south east);
\draw[thick] (C.west) -- (c0.south);

%  4. RELACIÓ TERNÀRIA M:N:P EN TRIANGLES CORRECTA
% Per a M:N:P, el triangle cap a C (p) és NEGRE.
% Els altres dos (cap a A i B, ambdós molts) també són NEGRES.

% Triangle Esquerra (cap a A) - NEGRE
\filldraw[fill=black, draw=black, thick]
    (-1.20,0.90) -- (0,0.90) -- (-0.60,-0.15) -- cycle;    

% Triangle Dreta (cap a B) - NEGRE
\filldraw[fill=black, draw=black, thick]
    (1.20,0.90) -- (0,0.90) -- (0.60,-0.15) -- cycle;      

% Triangle Inferior (cap a C) - NEGRE (cardinalitat p)
\filldraw[fill=black, draw=black, thick]
    (0,-1.20) -- (-0.60,-0.15) -- (0.60,-0.15) -- cycle;   

% Triangle central (fons blanc per a tancar la figura)
\filldraw[fill=white, draw=black, thick]
    (0,0.90) -- (-0.60,-0.15) -- (0.60,-0.15) -- cycle;    

% Etiqueta de la relació
\node[font=\small] at (2.25,0.10) {R};

%  5. ATRIBUT DE LA RELACIÓ 
\node[attribute] (id) at (0.65,2.20) {\underline{id}};
\draw[dashed] (Rel) -- (id);

%  6. CONNEXIONS (Relació ternària M:N:P) 
% Costat A (cardinalitat n)
\draw[thick] (A.east) -- (-1.20,0.90) node[pos=0.74, above] {n};
% Costat B (cardinalitat m)
\draw[thick] (B.west) -- (1.20,0.90) node[pos=0.74, above] {m};
% Costat C (cardinalitat p)
\draw[thick] (C.north) -- (0,-1.20) node[pos=0.74, right] {p};

%  7. EXPLICACIÓ DE LA RESTRICCIÓ M:N:P
\node[draw, dashed, fill=white, font=\scriptsize, align=left] (Const) at (3.35,-2.25) {
    sql\_constraints:\\
    unique(a\_id, b\_id, c\_id)
};
\draw[->, bend left=18, gray] (Const) to (0,-0.20);

\end{tikzpicture}
```
**Traducció formal (M:N:P):**
L'esquema de la taula associativa ($R$) conté les tres claus alienes com a part de la seua clau primària:

```{math}
R = (\underline{a_0, b_0, c_0}, r)
```

**Restriccions d'Integritat (RI):**
* **Integritat Referencial:** Les tres claus han d'existir en les seues respectives taules:
    ```{math}
    a_0 \rightarrow A(a_0), \quad b_0 \rightarrow B(b_0), \quad c_0 \rightarrow C(c_0)
    ```


**Implementació en Python (Odoo):**
```python
...
_sql_constraints = [
    ('uniq_abc', 'unique(a_id, b_id, c_id)', 'Registre duplicat')
]
```

2. **Cas Restrictiu (1:M:N):** La combinació de dues entitats "bloqueja" la tercera (la del triangle blanc).
```{tikz}
\usetikzlibrary{shapes.geometric, positioning, calc}

\begin{tikzpicture}[
    font=\sffamily,
    % Estil per a les entitats (Rectangles)
    entity/.style={
        draw, thick, fill=white,
        minimum width=3.2cm, minimum height=1.1cm,
        align=center, font=\bfseries
    },
    % Estil per als atributs (Ovals)
    attribute/.style={
        draw, ellipse, fill=white,
        minimum width=2.2cm, minimum height=0.8cm,
        font=\small\itshape
    }
]

%  1. ENTITATS (Posició original per a relació ternària 1:M:N) 
\coordinate (Rel) at (0,0);

\node[entity] (A) at (-4.0,1.6) {A};
\node[entity] (B) at (4.0,1.6) {B};
\node[entity] (C) at (0,-2.5) {C};

%  2. ATRIBUTS CLAU DE CADA ENTITAT 
\node[attribute, above right=0.6cm and 0.2cm of A] (a0) {\underline{a0}};
\node[attribute, above left=0.6cm and 0.2cm of B] (b0) {\underline{b0}};
\node[attribute, above left=0.6cm and 0.2cm of C] (c0) {\underline{c0}};

%  3. CONNEXIONS DELS ATRIBUTS A LES ENTITATS 
\draw[thick] (A.north) -- (a0.south west);
\draw[thick] (B.north) -- (b0.south east);
\draw[thick] (C.west) -- (c0.south);

%  4. RELACIÓ TERNÀRIA 1:M:N EN TRIANGLES CORRECTA
% Per a 1:M:N, el triangle cap a C (1) és BLANC.
% Els altres dos (cap a A i B, ambdós molts) són NEGRES.

% Triangle Esquerra (cap a A) - NEGRE
\filldraw[fill=black, draw=black, thick]
    (-1.20,0.90) -- (0,0.90) -- (-0.60,-0.15) -- cycle;    

% Triangle Dreta (cap a B) - NEGRE
\filldraw[fill=black, draw=black, thick]
    (1.20,0.90) -- (0,0.90) -- (0.60,-0.15) -- cycle;      

% Triangle Inferior (cap a C) - BLANC (cardinalitat 1)
\filldraw[fill=white, draw=black, thick]
    (0,-1.20) -- (-0.60,-0.15) -- (0.60,-0.15) -- cycle;   

% Triangle central (fons blanc per a tancar la figura)
\filldraw[fill=white, draw=black, thick]
    (0,0.90) -- (-0.60,-0.15) -- (0.60,-0.15) -- cycle;    

% Etiqueta de la relació
\node[font=\small] at (2.25,0.10) {R};

%  5. ATRIBUT DE LA RELACIÓ 
\node[attribute] (id) at (0.65,2.20) {\underline{id}};
\draw[dashed] (Rel) -- (id);

%  6. CONNEXIONS (Relació ternària 1:M:N) 
% Costat A (cardinalitat 1)
\draw[thick] (A.east) -- (-1.20,0.90) node[pos=0.74, above] {1};
% Costat B (cardinalitat m)
\draw[thick] (B.west) -- (1.20,0.90) node[pos=0.74, above] {m};
% Costat C (cardinalitat n)
\draw[thick] (C.north) -- (0,-1.20) node[pos=0.74, right] {n};

%  7. EXPLICACIÓ DE LA RESTRICCIÓ 1:M:N
\node[draw, dashed, fill=white, font=\scriptsize, align=left] (Const) at (3.35,-2.25) {
    sql\_constraints:\\
    unique(a\_id, b\_id)
};
\draw[->, bend left=18, gray] (Const) to (0,-0.20);

\end{tikzpicture}
```
**Traducció formal (1:M:N):**
La combinació d'A i B "bloqueja" a C, per tant, la clau primària només inclou $a_0$ i $b_0$:

```{math}
R = (\underline{a_0, b_0}, c_0, r)
```

**Restriccions d'Integritat (RI):**
* **Clau Aliena del Blanc:** El camp $c_0$ és una clau aliena cap a C, però no forma part de la PK de la relació:
    ```{math}
    c_0 \rightarrow C(c_0)
    ```
* **Valor No Nul (VNN):** Si la participació de C és total, el camp no pot ser buit:
    ```{math}
    \operatorname{VNN}: c_0
    ```



**Implementació en Python (Odoo):**
```python
class RelacioR(models.Model):
    _name = 'nom_modul.relacio_r'
    _description = 'Model associatiu per a la relació ternària R'

    # Claus alienes (FK) cap a les entitats A, B i C
    a_id = fields.Many2one('nom_modul.entitat_a', string="Entitat A", required=True)
    b_id = fields.Many2one('nom_modul.entitat_b', string="Entitat B", required=True)
    
    # c_id és el costat del triangle blanc. 
    # Posem required=True per a implementar el VNN (Participació Total)
    c_id = fields.Many2one('nom_modul.entitat_c', string="Entitat C", required=True)

    _sql_constraints = [
        (
            'uniq_ab', 
            'unique(a_id, b_id)', 
            'Error: La combinació d’A i B ja té un C assignat (Restricció 1:M:N).'
        )
    ]
```

:::{tip}
**Penseu en les claus de la relació com en els ingredients d'un arròs al forn.** Les entitats amb triangle negre ($a_0$, $b_0$) són l'arròs i el caldo: sense elles no hi ha plat, per això formen part de la clau primària i van amb `required=True`.

L'entitat amb triangle blanc ($c_0$) és com la cassola:

- **Si l'ER diu que hi ha VNN**, la cassola és obligatòria (`required=True`). No pots cuinar l'arròs en l'aire. Açò és **Participació Total**.
- **Si l'ER no té VNN**, la cassola és opcional (`required=False`). Pots tindre els ingredients preparats ($a_0$, $b_0$), però encara no haver triat on posar-los; per tant, $c_0$ pot ser nul. Açò és **Participació Parcial**.
:::
###### Aplicació al nostre exercici:
En el nostre cas, la **Convocatòria** té un triangle **blanc** (cardinalitat 1). Això significa que per a un **Músic** i un **Acte** concrets, només pot haver-hi **una convocatòria** realitzada.

A nivell de base de dades, la restricció d'unicitat més estricta per a aquest esquema seria:
```python
_sql_constraints = [
    ('uniq_convocatoria', 'unique(membre_id, acte_id)', 
     'Aquest músic ja està inscrit en aquesta convocatòria!')
]
```

*(Nota: Si usem la tripleta `unique(membre_id, convocatoria_id, acte_id)`, estem sent més permissius, permetent que un músic siga convocat en el mateix cate  amb dos convocatòries diferents, la qual cosa seria una relació M:N:P).* 

3. **Cas d'Exclusivitat Total (1:1:1):** Cada element només pot aparéixer una vegada en tota la taula.
```{tikz}
\usetikzlibrary{shapes.geometric, positioning, calc}

\begin{tikzpicture}[
    font=\sffamily,
    % Estil per a les entitats (Rectangles)
    entity/.style={
        draw, thick, fill=white,
        minimum width=3.2cm, minimum height=1.1cm,
        align=center, font=\bfseries
    },
    % Estil per als atributs (Ovals)
    attribute/.style={
        draw, ellipse, fill=white,
        minimum width=2.2cm, minimum height=0.8cm,
        font=\small\itshape
    }
]

%  1. ENTITATS (Posició original per a relació ternària 1:1:1) 
\coordinate (Rel) at (0,0);

\node[entity] (A) at (-4.0,1.6) {A};
\node[entity] (B) at (4.0,1.6) {B};
\node[entity] (C) at (0,-2.5) {C};

%  2. ATRIBUTS CLAU DE CADA ENTITAT 
\node[attribute, above right=0.6cm and 0.2cm of A] (a0) {\underline{a0}};
\node[attribute, above left=0.6cm and 0.2cm of B] (b0) {\underline{b0}};
\node[attribute, above left=0.6cm and 0.2cm of C] (c0) {\underline{c0}};

%  3. CONNEXIONS DELS ATRIBUTS A LES ENTITATS 
\draw[thick] (A.north) -- (a0.south west);
\draw[thick] (B.north) -- (b0.south east);
\draw[thick] (C.west) -- (c0.south);

%  4. RELACIÓ TERNÀRIA 1:1:1 EN TRIANGLES CORRECTA
% Per a 1:1:1, els TRES triangles són BLANCS (cardinalitat 1 per a cadascun)

% Triangle Esquerra (cap a A) - BLANC
\filldraw[fill=white, draw=black, thick]
    (-1.20,0.90) -- (0,0.90) -- (-0.60,-0.15) -- cycle;    

% Triangle Dreta (cap a B) - BLANC
\filldraw[fill=white, draw=black, thick]
    (1.20,0.90) -- (0,0.90) -- (0.60,-0.15) -- cycle;      

% Triangle Inferior (cap a C) - BLANC (cardinalitat 1)
\filldraw[fill=white, draw=black, thick]
    (0,-1.20) -- (-0.60,-0.15) -- (0.60,-0.15) -- cycle;   

% Triangle central (fons blanc )
\filldraw[fill=white, draw=black, thick]
    (0,0.90) -- (-0.60,-0.15) -- (0.60,-0.15) -- cycle;    

% Etiqueta de la relació
\node[font=\small] at (2.25,0.10) {R};

%  5. ATRIBUT DE LA RELACIÓ 
\node[attribute] (id) at (0.65,2.20) {\underline{id}};
\draw[dashed] (Rel) -- (id);

%  6. CONNEXIONS (Relació ternària 1:1:1) 
% Costat A (cardinalitat 1)
\draw[thick] (A.east) -- (-1.20,0.90) node[pos=0.74, above] {1};
% Costat B (cardinalitat 1)
\draw[thick] (B.west) -- (1.20,0.90) node[pos=0.74, above] {1};
% Costat C (cardinalitat 1)
\draw[thick] (C.north) -- (0,-1.20) node[pos=0.74, right] {1};

%  7. EXPLICACIÓ DE LA RESTRICCIÓ 1:1:1
\node[draw, dashed, fill=white, font=\scriptsize, align=left] (Const) at (3.35,-2.25) {
    sql\_constraints:\\
    unique(a\_id)\\
    unique(b\_id)\\
    unique(c\_id)
};
\draw[->, bend left=18, gray] (Const) to (0,-0.20);

\end{tikzpicture}
```

**Traducció formal (1:1:1):**
Triem una entitat com a clau primària i les altres funcionen com a claus candidates (atributs únics):

```{math}
R = (\underline{a_0}, b_0, c_0, r)
```

**Restriccions d'Integritat (RI):**
* **Unicitat absoluta:** Cada element només pot participar en un registre de la taula:
    ```{math}
    \operatorname{UK}: b_0, \quad \operatorname{UK}: c_0
    ```
* **Integritat Referencial:**
    ```{math}
    a_0 \rightarrow A(a_0), \quad b_0 \rightarrow B(b_0), \quad c_0 \rightarrow C(c_0)
    ```


**Implementació en Python (Odoo):**
```python
...
_sql_constraints = [
    ('uniq_a', 'unique(a_id)', 'L’element A ja està ocupat en una altra relació'),
    ('uniq_b', 'unique(b_id)', 'L’element B ja està ocupat'),
    ('uniq_c', 'unique(c_id)', 'L’element C ja està ocupat')
]
```


#### Resum de traducció: Cardinalitat ternària a Odoo

En totes les relacions ternàries, la solució física en Odoo és la mateixa: crear un **model associatiu intermedi** amb tres camps `Many2one`. El que canvia segons el diagrama conceptual (triangles blancs o negres) és la força de la restricció d’unicitat en `_sql_constraints`.

| Tipus de Ternària | Triangles | On posar el `unique(...)`? | Lògica de negoci (Exemple) |
| --- | --- | --- | --- |
| **M:N:P** | 0 blancs | `(A, B, C)` | **Professor-Mòdul-Grup**: Qualsevol combinació és vàlida mentre no es repetisca la fila exacta. |
| **1:M:N** | 1 blanc (a C) | `(A, B)` | **Metge-Pacient-Consultori**: La parella Metge i Pacient ja determina un únic Consultori. No poden estar en dos alhora. |
| **1:1:M** | 2 blancs (a B i C) | `(A, C)` o `(A, B)` | **Alumne-Ordinador-Aula**: Un alumne en una aula concreta només pot tindre un ordinador assignat. |
| **1:1:1** | 3 blancs | `(A)`, `(B)`, `(C)` (per separat) | **Casament**: Cada cònjuge i cada jutge només poden participar en un registre únic de la taula. |


:::{tip}
**Com saber quina restricció aplicar?**
Mira el diagrama: si una entitat té un **triangle blanc**, significa que la combinació de les **altres entitats** ha de ser única per a ella. Si el triangle és **negre**, eixa entitat pot repetir-se en moltes combinacions diferents (forma part de la clau).
:::



<!-- ## Patrons avançats de traducció ER a Odoo

Per a completar la traducció de qualsevol disseny de base de dades a Odoo, hem d'abordar els casos especials que defineixen l'estructura jeràrquica i la dependència d'existència. -->

### Relacions Binàries 1:1
Són relacions on cada registre d'una entitat només pot estar vinculat, com a màxim, a un únic registre de l'altra entitat. En Odoo no existeix un camp específic per a 1:1 `One2one`, però es pot modelar amb un `Many2one` i una restricció d'unicitat.
- **En Odoo:** es modelen amb `Many2one` i una restricció `UNIQUE` sobre el camp de relació.


**Traducció formal (1:1):**
Triem una entitat com a principal ($A$) i l'altra absorbeix la clau de la seua parella com a atribut únic:

$$A = (\underline{a\_0}, a\_1, \dots, b\_0)$$

**Restriccions d'Integritat (RI):**
* **Integritat Referencial:** La clau aliena ha d'existir en la taula original:

$$b\_0 \rightarrow B(b\_0)$$

* **Unicitat ($UK$):** El camp no es pot repetir per a garantir l'exclusivitat 1 a 1:

$$UK: b\_0$$


```{tikz}
\usetikzlibrary{shapes.geometric, positioning, calc}
\begin{tikzpicture}[
    font=\sffamily,
    entity/.style={draw, thick, fill=white, minimum width=2.5cm, minimum height=1cm, align=center, font=\bfseries},
    t_white/.style={draw, thick, fill=white, isosceles triangle, isosceles triangle apex angle=60, inner sep=0pt, minimum width=3mm, minimum height=4.5mm}
]
    \node[entity] (E) {EMPLEAT};
    \node[entity, right=3.5cm of E] (O) {ORDINADOR};
    
    \path (E.east) -- (O.west) coordinate[midway] (mid);
    \node[t_white, rotate=-180, anchor=lower side] at (mid) (tw1) {};
    \node[t_white, rotate=0, anchor=lower side] at (mid) (tw2) {};
    
    \draw[thick] (E.east) -- (tw1.apex);
    \draw[thick] (O.west) -- (tw2.apex);
    \node[above=0.3cm of mid, font=\scriptsize\itshape] {té};
\end{tikzpicture}
```
**Implementació en Python (Odoo):**
```python
class Ordinador(models.Model):
    _name = 'centre.ordinador'

    empleat_id = fields.Many2one('centre.empleat', string="Usuari")

    _sql_constraints = [
        (
            'uniq_empleat',
            'unique(empleat_id)',
            "Aquest empleat ja té un ordinador assignat!"
        )
    ]
```



### Relacions Unàries o Recursives 
Són relacions on una entitat es relaciona amb si mateixa. El cas més típic és l'arbre jeràrquic (un empleat té un cap, que també és un empleat).
- **En Odoo:** Creem un camp `Many2one` que apunta al propi model (`_name`).

**Traducció formal:**
L'entitat absorbeix la seua pròpia clau primària com a clau aliena ($a\_0'$):

$$A = (\underline{a\_0}, a\_1, \dots, a\_0')$$

**Restriccions d'Integritat (RI):**
* **Integritat Referencial:** El camp apunta a la mateixa taula o és nul (per al node arrel):

$$a\_0' \rightarrow A(a\_0)$$



```{tikz}
\usetikzlibrary{shapes.geometric, positioning, calc}
\begin{tikzpicture}[
    font=\sffamily,
    entity/.style={draw, thick, fill=white, minimum width=3.2cm, minimum height=1.1cm, align=center, font=\bfseries},
    t_white/.style={draw, thick, fill=white, isosceles triangle, isosceles triangle apex angle=60, inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm},
    t_black/.style={draw, thick, fill=black, isosceles triangle, isosceles triangle apex angle=60, inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm}
]
    %  1. ENTITAT 
    \node[entity] (E) {EMPLEAT};

    %  2. ROMBE DE RELACIÓ (Sota l'entitat) 
    \coordinate (mid) at (0,-2.2);
    
    % Triangles de cardinalitat (Rombe bicolor)
    \node[t_white, rotate=-180, anchor=lower side] at ($(mid)+(-0.001,0)$) (tw) {};
    \node[t_black, rotate=0, anchor=lower side] at ($(mid)+(0.001,0)$) (tb) {};

    %  3. COORDENADES DE LES CANTONADES 
    \coordinate (TL) at ($(E.west)+(-1,0)$);   % cantonada sup-esquerra
    \coordinate (BL) at ($(TL)+(0,-2.2)$);     % cantonada inf-esquerra
    \coordinate (TR) at ($(E.east)+(1,0)$);    % cantonada sup-dreta
    \coordinate (BR) at ($(TR)+(0,-2.2)$);     % cantonada inf-dreta

    %  4. CONNEXIONS (sense etiquetes en el path) 
    \draw[thick] (E.west) -- (TL) -- (BL) -- (tw.apex);
    \draw[thick] (E.east) -- (TR) -- (BR) -- (tb.apex);

    %  5. ETIQUETES (nodes independents, ben separats de la línia) 
    \node[above, xshift=-4pt] at ($(E.west)!0.5!(TL)$) {1};
    \node[left=6pt] at ($(TL)!0.5!(BL)$) {cap};
    \node[above, xshift=4pt] at ($(E.east)!0.5!(TR)$) {n};
    \node[right=6pt] at ($(TR)!0.5!(BR)$) {subordinat};

    % Text de la relació
    \node[font=\scriptsize\itshape, below=0.22cm of mid] {responsable de};
\end{tikzpicture}
```

```python
class Empleat(models.Model):
    _name = 'centre.empleat'
    name = fields.Char(string="Nom")
    # Recursivitat: el camp apunta al mateix model
    parent_id = fields.Many2one('centre.empleat', string="Responsable")
    # Opcional: llista de subordinats
    child_ids = fields.One2many('centre.empleat', 'parent_id', string="Subordinats")
```

:::{tip}
**I en Odoo real? millor reutilitzar `hr.employee`**

Si tens instal·lat el mòdul de Recursos Humans, Odoo ja incorpora el model `hr.employee`, que **ja contempla la jerarquia** amb camps com `parent_id` (responsable) i `child_ids` (subordinats).

Per tant, en un cas real, sovint no cal crear `centre.empleat` des de zero: és més net **heretar** `hr.employee` i afegir només els camps específics del teu projecte.

Exemple:

```python
from odoo import fields, models

class HrEmployee(models.Model):
    _inherit = 'hr.employee'

    # Camp propi del centre
    codi_docent = fields.Char(string="Codi docent")
```

I recorda afegir la dependència en el manifest:

```python
'depends': ['base', 'hr'],
```
:::

#### Com es resol cada tipus de relació unària en Odoo?

No, **no totes les relacions unàries s'implementen igual**. El patró depén de la cardinalitat de la relació:

| Cardinalitat | Cas típic | Solució en Odoo |
| --- | --- | --- |
| **1:M** | Jerarquia (cap → subordinats) | `Many2one` al mateix model + `One2many` invers |
| **M:M** | Col·legues, equips (molts↔molts) | `Many2many` auto-referencial amb `_relation` explícit |
| **1:1** | Parella assignada, soci únic | `Many2one` + restricció `unique` en `_sql_constraints` |

**Relació unària 1:M**
Aquest és el cas anterior de l'empleat amb el seu responsable. Cada empleat té un únic responsable, però un responsable pot tenir molts subordinats.
```{tikz}
\usetikzlibrary{shapes.geometric, positioning, calc}
\begin{tikzpicture}[
    font=\sffamily,
    entity/.style={draw, thick, fill=white, minimum width=3.2cm, minimum height=1.1cm, align=center, font=\bfseries},
    t_white/.style={draw, thick, fill=white, isosceles triangle, isosceles triangle apex angle=60, inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm},
    t_black/.style={draw, thick, fill=black, isosceles triangle, isosceles triangle apex angle=60, inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm}
]
    % ENTITAT
    \node[entity] (E) {EMPLEAT};

    % POSICIÓ RELACIÓ
    \coordinate (mid) at (0,-2.2);
    
    % TRIANGLES (1:n → blanc + negre)
    \node[t_white, rotate=-180, anchor=lower side] at ($(mid)+(-0.001,0)$) (tw) {};
    \node[t_black, rotate=0, anchor=lower side] at ($(mid)+(0.001,0)$) (tb) {};

    % COORDENADES AUXILIARS
    \coordinate (TL) at ($(E.west)+(-1,0)$);
    \coordinate (BL) at ($(TL)+(0,-2.2)$);
    \coordinate (TR) at ($(E.east)+(1,0)$);
    \coordinate (BR) at ($(TR)+(0,-2.2)$);

    % CONNEXIONS
    \draw[thick] (E.west) -- (TL) -- (BL) -- (tw.apex);
    \draw[thick] (E.east) -- (TR) -- (BR) -- (tb.apex);

    % ETIQUETES
    \node[above, xshift=-4pt] at ($(E.west)!0.5!(TL)$) {1};
    \node[left=6pt] at ($(TL)!0.5!(BL)$) {cap};
    \node[above, xshift=4pt] at ($(E.east)!0.5!(TR)$) {n};
    \node[right=6pt] at ($(TR)!0.5!(BR)$) {subordinat};

    % TEXT
    \node[font=\scriptsize\itshape, below=0.22cm of mid] {responsable de};
\end{tikzpicture}
```


```python
parent_id = fields.Many2one('centre.empleat', string="Responsable")
child_ids = fields.One2many('centre.empleat', 'parent_id', string="Subordinats")
```

**Relació unària M:M** 
Aquest cas necessita una taula de relació pròpia perquè un registre pot estar relacionat amb molts altres del mateix model (per exemple, col·legues que col·laboren entre ells).
```{tikz}
\usetikzlibrary{shapes.geometric, positioning, calc}
\begin{tikzpicture}[
    font=\sffamily,
    entity/.style={draw, thick, fill=white, minimum width=3.2cm, minimum height=1.1cm, align=center, font=\bfseries},
    t_white/.style={draw, thick, fill=white, isosceles triangle, isosceles triangle apex angle=60, inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm},
    t_black/.style={draw, thick, fill=black, isosceles triangle, isosceles triangle apex angle=60, inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm}
]
    % ENTITAT
    \node[entity] (E) {EMPLEAT};

    % POSICIÓ RELACIÓ
    \coordinate (mid) at (0,-2.2);
    
    % TRIANGLES (els dos negres conceptualment = n:n)
    \node[t_black, rotate=-180, anchor=lower side] at ($(mid)+(-0.001,0)$) (t1) {};
    \node[t_black, rotate=0, anchor=lower side] at ($(mid)+(0.001,0)$) (t2) {};

    % COORDENADES AUXILIARS
    \coordinate (TL) at ($(E.west)+(-1,0)$);
    \coordinate (BL) at ($(TL)+(0,-2.2)$);
    \coordinate (TR) at ($(E.east)+(1,0)$);
    \coordinate (BR) at ($(TR)+(0,-2.2)$);

    % CONNEXIONS
    \draw[thick] (E.west) -- (TL) -- (BL) -- (t1.apex);
    \draw[thick] (E.east) -- (TR) -- (BR) -- (t2.apex);

    % ETIQUETES
    \node[above, xshift=-4pt] at ($(E.west)!0.5!(TL)$) {n};
    \node[left=6pt] at ($(TL)!0.5!(BL)$) {empleat};
    \node[above, xshift=4pt] at ($(E.east)!0.5!(TR)$) {n};
    \node[right=6pt] at ($(TR)!0.5!(BR)$) {col·lega};

    % TEXT
    \node[font=\scriptsize\itshape, below=0.22cm of mid] {col·labora amb};
\end{tikzpicture}

```


```python
col_lega_ids = fields.Many2many(
    'centre.empleat',
    relation='empleat_col_lega_rel',  # nom explícit OBLIGATORI
    column1='empleat_id',
    column2='col_lega_id',
    string="Col·legues",
)
```
:::{caution}
**`Many2many` auto-referencial: especifica sempre els noms de columna**

Quan el camp `Many2many` apunta al **mateix model**, Odoo no pot generar automàticament un nom de taula vàlid (causaria un conflicte amb ell mateix). Cal indicar **sempre** `relation`, `column1` i `column2` de forma explícita, o Odoo llançarà un error en instal·lar el mòdul. On `column1` i `column2` són els noms dels camps que apuntaran als registres relacionats (poden ser qualsevol nom, però han de ser diferents entre si) i `relation` és el nom de la taula intermèdia que s'utilitzarà a la base de dades (ha de ser únic en tota la base de dades).
:::


**Relació unària 1:1**
Aquest cas cada registre només pot estar relacionat amb un únic altre del mateix model. Es modela amb un `Many2one` i una restricció d'unicitat per garantir que no hi haja duplicats.
```{tikz}
\usetikzlibrary{shapes.geometric, positioning, calc}
\begin{tikzpicture}[
    font=\sffamily,
    entity/.style={draw, thick, fill=white, minimum width=3.2cm, minimum height=1.1cm, align=center, font=\bfseries},
    t_white/.style={draw, thick, fill=white, isosceles triangle, isosceles triangle apex angle=60, inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm},
    t_black/.style={draw, thick, fill=black, isosceles triangle, isosceles triangle apex angle=60, inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm}
]
    % ENTITAT
    \node[entity] (E) {EMPLEAT};

    % POSICIÓ RELACIÓ
    \coordinate (mid) at (0,-2.2);
    
    % TRIANGLES (els dos blancs = 1:1)
    \node[t_white, rotate=-180, anchor=lower side] at ($(mid)+(-0.001,0)$) (t1) {};
    \node[t_white, rotate=0, anchor=lower side] at ($(mid)+(0.001,0)$) (t2) {};

    % COORDENADES AUXILIARS
    \coordinate (TL) at ($(E.west)+(-1,0)$);
    \coordinate (BL) at ($(TL)+(0,-2.2)$);
    \coordinate (TR) at ($(E.east)+(1,0)$);
    \coordinate (BR) at ($(TR)+(0,-2.2)$);

    % CONNEXIONS
    \draw[thick] (E.west) -- (TL) -- (BL) -- (t1.apex);
    \draw[thick] (E.east) -- (TR) -- (BR) -- (t2.apex);

    % ETIQUETES
    \node[above, xshift=-4pt] at ($(E.west)!0.5!(TL)$) {1};
    \node[left=6pt] at ($(TL)!0.5!(BL)$) {empleat};
    \node[above, xshift=4pt] at ($(E.east)!0.5!(TR)$) {1};
    \node[right=6pt] at ($(TR)!0.5!(BR)$) {soci};

    % TEXT
    \node[font=\scriptsize\itshape, below=0.22cm of mid] {soci de};
\end{tikzpicture}
```




```python
soci_id = fields.Many2one('centre.empleat', string="Soci assignat")

_sql_constraints = [
    ('soci_unique', 'unique(soci_id)',
     'Cada empleat només pot tindre un soci assignat!'),
]
```

Este patró modela una **assignació exclusiva 1:1** dins del mateix model. Si, a més, vols que la relació siga **perfectament simètrica** (és a dir, si `A` està relacionat amb `B`, llavors `B` també ho estiga amb `A`), cal afegir lògica extra en `create`, `write` o constriccions de negoci.



### Entitats Dèbils i Restriccions d'Identificació 
Una entitat és dèbil quan la seua existència depén d'una entitat "pare" (per exemple, les línies d'una factura no tenen sentit sense la factura).
```{tikz}
\usetikzlibrary{shapes.geometric, positioning, calc}
\begin{tikzpicture}[
    font=\sffamily,
    entity/.style={draw, thick, fill=white, minimum width=3.2cm, minimum height=1.1cm, align=center, font=\bfseries},
    weak/.style={draw, thick, double, fill=white, minimum width=3.2cm, minimum height=1.1cm, align=center, font=\bfseries},
    attribute/.style={draw, ellipse, fill=white, minimum width=1.8cm, minimum height=0.7cm, font=\small\itshape},
    t_white/.style={draw, thick, fill=white, isosceles triangle, isosceles triangle apex angle=60, inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm},
    t_black/.style={draw, thick, fill=black, isosceles triangle, isosceles triangle apex angle=60, inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm}
]
    % Entities
    \node[entity] (A) {A};
    \node[weak, right=3cm of A] (B) {B};

    % Attributes of A
    \node[attribute, above left=0.8cm and 0.3cm of A] (a0) {\underline{a\_0}};
    \draw[thick] (A.north west) -- (a0.south east);

    % Attributes of B
    \node[attribute, above left=0.8cm and 0.3cm of B] (b0) {\underline{b\_0}};
    \node[attribute, above right=0.8cm and 0.3cm of B] (b1) {b\_1};
    \draw[thick] (B.north west) -- (b0.south east);
    \draw[thick] (B.north east) -- (b1.south west);

    % Relationship
    \path (A.east) -- (B.west) coordinate[midway] (mid);
    \node[t_white, rotate=-180, anchor=lower side] at ($(mid)+(-0.001,0)$) (tw) {};
    \node[t_black, rotate=0, anchor=lower side] at ($(mid)+(0.001,0)$) (tb) {};

    \draw[thick] (A.east) -- (tw.apex);
    \draw[thick] (B.west) -- (tb.apex);
    \node[above=0.3cm of mid, font=\scriptsize\itshape] {té};
\end{tikzpicture}
```

**Traducció formal:**
La taula filla ($B$) necessita la clau del pare ($a\_0$) per a formar la seua pròpia identitat i PK composta:

$$A = (\underline{a\_0}, \dots)$$
$$B = (\underline{a\_0, b\_0}, b\_1, \dots)$$

**Restriccions d'Integritat (RI):**
* **Participació Total ($VNN$):** El registre fill no té sentit ni existència sense el pare:

$$VNN: a\_0$$

* **Esborrat en Cascada:** Si s'elimina el pare, Odoo neteja automàticament els fills:

<!--
This section discusses the SQL constraint "ON DELETE CASCADE". 
When applied to a foreign key relationship, it ensures that if a record 
in the parent table (in this case, the record identified by a_0) is deleted, 
all corresponding records in the child table (e.g., records related to b_0) 
will also be automatically deleted. This helps maintain referential integrity 
by preventing orphaned records in the child table.
-->
$$ON \text{ DELETE CASCADE}: a\_0$$

**En Odoo:** Usem el patró **Capçalera-Línies** amb un esborrat en cascada.
**Exemple:** 

```{tikz}
\usetikzlibrary{shapes.geometric, positioning, calc}
\begin{tikzpicture}[
    font=\sffamily,
    entity/.style={draw, thick, fill=white, minimum width=2.5cm, minimum height=1cm, align=center, font=\bfseries},
    weak/.style={draw, thick, double, fill=white, minimum width=2.5cm, minimum height=1cm, align=center, font=\bfseries},
    relweak/.style={draw, diamond, aspect=2, fill=white, double, inner sep=1.5pt},
    t_white/.style={draw, thick, fill=white, isosceles triangle, isosceles triangle apex angle=60, inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm},
    t_black/.style={draw, thick, fill=black, isosceles triangle, isosceles triangle apex angle=60, inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm}
]
    \node[entity] (F) {FACTURA};
    \node[weak, right=3cm of F] (L) {LÍNIA};
    \coordinate (mid) at ($(F.east)!0.5!(L.west)$);
    \node[t_white, rotate=-180, anchor=lower side] at ($(mid)+(-0.001,0)$) (tw) {};
    \node[t_black, rotate=0, anchor=lower side] at ($(mid)+(0.001,0)$) (tb) {};

    \draw[thick] (F.east) -- (tw.apex);
    \draw[thick, double] (L.west) -- (tb.apex);

    \node[above, xshift=-3pt] at ($(F.east)!0.55!(tw.apex)$) {1};
    \node[above, xshift=3pt] at ($(tb.apex)!0.55!(L.west)$) {n};
    \node[font=\scriptsize\itshape, below=0.22cm of mid] {té};
\end{tikzpicture}
```

```python
class Factura(models.Model):
    _name = 'centre.factura'
    line_ids = fields.One2many('centre.factura.line', 'factura_id')

class FacturaLine(models.Model):
    _name = 'centre.factura.line'
    # ondelete='cascade' garanteix que si s'esborra la factura, s'esborren les línies
    factura_id = fields.Many2one('centre.factura', ondelete='cascade', required=True)
    producte = fields.Char(string="Producte")
```
El camp `factura_id` és obligatori (`required=True`) perquè una línia no pot existir sense una factura associada, i `ondelete='cascade'` assegura que si es borra la factura, totes les línies relacionades també s'esborren automàticament. Camps com `producte` són atributs de la línia, no de la factura, perquè cada línia pot tindre un producte diferent.

Este patró és molt comú en Odoo per a modelar elements dependents d'una altra entitat, com passa en `sale.order` / `sale.order.line` o en `account.move` / `account.move.line`.

Ara bé, convé no confondre dues idees:

- **participació total**: la línia ha d'estar relacionada obligatòriament amb una factura;
- **entitat dèbil**: a més de dependre existencialment de la factura, la seua identificació conceptual depén del context de l'entitat pare.

En la pràctica d'Odoo, sovint expliquem els dos conceptes junts perquè el patró capçalera-línies s'hi assembla molt, encara que el model relacional real no sempre reproduïsca tota la teoria ER al peu de la lletra.

:::{note}
**Què significa la doble ratlla, exactament?**

La **doble ratlla** indica **participació total** en la relació: tota instància d'eixa entitat **ha d'aparéixer obligatòriament** en la relació.

En este diagrama:

- `LÍNIA` porta doble ratlla perquè **no pot existir sense** una `FACTURA`.
- `FACTURA` porta ratlla simple perquè, conceptualment, una factura **podria existir** encara que no estiguérem imposant en el diagrama que haja de tindre almenys una línia.

**Açò té relació amb 1:N vs 0:N?** Sí, però **no és exactament el mateix**:

- La **cardinalitat** (`1`, `n`) diu **quants** registres poden relacionar-se.
- La **doble ratlla** diu si la participació és **obligatòria** (**total**) o **opcional** (**parcial**).

Per tant, una relació pot ser `1:N` i, a més:

- tindre **participació total** d'un costat (doble ratlla), o
- tindre **participació parcial** (`0:N`) si eixe costat fora opcional.

En Odoo, esta idea sol traduir-se així:

- **participació total** → `Many2one(..., required=True)`
- **participació parcial** → `Many2one(..., required=False)` o sense `required`
:::

:::{tip}
**Estem barrejant notacions? Un poc sí, però de manera conscient**

En estos apunts estem fent una **notació híbrida** per motius didàctics:

- els **triangles blanc/negre** ens serveixen per visualitzar ràpidament la **cardinalitat màxima** (`1` o `n`),
- la **ratlla simple o doble** ens serveix per indicar la **participació mínima** (`0` o `1`).

Dit d'una altra manera:

- **triangle blanc** → màxim `1`
- **triangle negre** → màxim `n`
- **línia simple** → mínim `0` (participació opcional)
- **línia doble** → mínim `1` (participació obligatòria)

Per això no és una contradicció, sinó una manera compacta d'expressar intervals com:

- blanc + simple → `0..1`
- blanc + doble → `1..1`
- negre + simple → `0..n`
- negre + doble → `1..n`

La notació ER clàssica i la notació de DIA no sempre dibuixen això exactament igual, però el significat conceptual és el mateix: una part del símbol indica **quants** i l'altra indica si la participació és **obligatòria o no**.
:::

###  Restriccions d'Existència (Participació 1:N vs 0:N) 
Les restriccions d'existència defineixen si és obligatori que un registre estiga relacionat amb un altre. Normalment apareixen dues formes d'expressar-ho, i en Odoo es tradueixen així:

#### Cas A) L'existència es pot expressar en la mateixa taula (VNN)
És el cas típic en què la relació i l'entitat dependent queden en la mateixa taula (ex.: professor ha de tindre departament).

- **En ER:** VNN (valor no nul). Es representa amb una doble ratlla en el costat de l'entitat obligada.
- **En Odoo:** Implementem la participació total amb l'atribut `Many2one(..., required=True)`

```{tikz}
\usetikzlibrary{shapes.geometric, positioning, calc}
\begin{tikzpicture}[
    font=\sffamily,
    entity/.style={draw, thick, fill=white, minimum width=2.5cm, minimum height=1cm, align=center, font=\bfseries},
    t_white/.style={draw, thick, fill=white, isosceles triangle, isosceles triangle apex angle=60, inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm},
    t_black/.style={draw, thick, fill=black, isosceles triangle, isosceles triangle apex angle=60, inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm}
]
    \node[entity] (P) {PROFESSOR};
    \node[entity, right=3.5cm of P] (D) {DEPARTAMENT};
    \coordinate (mid) at ($(P.east)!0.5!(D.west)$);
    \node[t_black, rotate=-180, anchor=lower side] at ($(mid)+(-0.001,0)$) (tb) {};
    \node[t_white, rotate=0, anchor=lower side] at ($(mid)+(0.001,0)$) (tw) {};

    \draw[thick, double] (P.east) -- (tb.apex);
    \draw[thick] (D.west) -- (tw.apex);

    \node[above, xshift=-3pt] at ($(P.east)!0.55!(tb.apex)$) {n};
    \node[above, xshift=3pt] at ($(tw.apex)!0.55!(D.west)$) {1};
    \node[font=\scriptsize\itshape, below=0.22cm of mid] {pertany};
\end{tikzpicture}
```

**Implementació en Odoo:**
```python
class Professor(models.Model):
    _name = 'centre.professor'

    name = fields.Char(string="Nom", required=True)
    departament_id = fields.Many2one('centre.departament', required=True, ondelete='restrict')

class Departament(models.Model):
    _name = 'centre.departament'
    name = fields.Char(string="Nom", required=True)
    professor_ids = fields.One2many('centre.professor', 'departament_id', string="Professors")  
```
Recordeu: La doble ratlla indica obligatorietat per a l'entitat que la té a prop. En este cas, el Professor té l'obligació de tindre un departament (`required=True`), però el Departament pot estar buit (ratlla simple), i `ondelete='restrict'` perquè no volem que s'esborre un departament si encara hi ha professors associats. 

#### Cas B) L'existència queda repartida entre taules diferents (R.I. tipus C)
És el cas on volem una cobertura del tipus: "tot registre de A ha d'aparéixer almenys una vegada en B".
Exemple didàctic: "tot equip ha de tindre almenys un jugador".

- **En ER:** R.I. tipus C (inclusió/cobertura)
- **En Odoo:** no es resol només amb una FK estàndard; cal una validació de negoci addicional.

```{tikz}
\usetikzlibrary{shapes.geometric, positioning, calc}
\begin{tikzpicture}[
    font=\sffamily,
    entity/.style={draw, thick, fill=white, minimum width=2.5cm, minimum height=1cm, align=center, font=\bfseries},
    t_white/.style={draw, thick, fill=white, isosceles triangle, isosceles triangle apex angle=60, inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm},
    t_black/.style={draw, thick, fill=black, isosceles triangle, isosceles triangle apex angle=60, inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm}
]
    \node[entity] (E) {EQUIP};
    \node[entity, right=3.5cm of E] (J) {JUGADOR};
    \coordinate (mid) at ($(E.east)!0.5!(J.west)$);
    \node[t_white, rotate=-180, anchor=lower side] at ($(mid)+(-0.001,0)$) (tw) {};
    \node[t_black, rotate=0, anchor=lower side] at ($(mid)+(0.001,0)$) (tb) {};

    \draw[thick, double] (E.east) -- (tw.apex);
    \draw[thick, double] (J.west) -- (tb.apex);

    \node[above, xshift=-3pt] at ($(E.east)!0.55!(tw.apex)$) {1};
    \node[above, xshift=3pt] at ($(tb.apex)!0.55!(J.west)$) {n};
    \node[font=\scriptsize\itshape, below=0.22cm of mid] {compost per};
\end{tikzpicture}
```

Exemple pràctic amb validació en Python:

```python
from odoo import api, fields, models
from odoo.exceptions import ValidationError

class Equip(models.Model):
    _name = 'centre.equip'

    name = fields.Char(required=True)
    jugador_ids = fields.One2many('centre.jugador', 'equip_id', string="Jugadors")

    @api.constrains('jugador_ids')
    def _check_minim_un_jugador(self):
        for record in self:
            if not record.jugador_ids:
                raise ValidationError("Cada equip ha de tindre almenys un jugador.")

class Jugador(models.Model):
    _name = 'centre.jugador'

    name = fields.Char(required=True)
    equip_id = fields.Many2one('centre.equip', required=True, ondelete='restrict')
```

Ací hi ha dues regles diferents i és important separar-les:

- `equip_id = fields.Many2one(..., required=True)` garanteix que **tot jugador pertany a un equip**.
- La restricció `_check_minim_un_jugador` garanteix el sentit contrari: que **tot equip tinga almenys un jugador**.

Resum ràpid:
- **Participació opcional (0:N):** no posem `required=True`.
- **Participació total simple (1:N, mateixa taula):** `required=True`.
- **Cobertura entre taules (R.I. tipus C):** validació extra (`@api.constrains`, `create/write/unlink` o lògica SQL avançada).

### Agregacions 
L'agregació **no és una idea nova** respecte del que ja hem comentat abans: és el cas en què una **relació** passa a tractar-se com si fora una **unitat amb identitat pròpia** perquè una tercera entitat necessita relacionar-se amb ella.

Dit d'una manera més simple:

- Una **relació normal** només diu que dues entitats estan connectades.
- Una **agregació** diu que eixa connexió és tan important que la tractem com un objecte sobre el qual poden passar més coses.

En el món relacional i en Odoo, això quasi sempre es tradueix en una **entitat associativa** o **model intermedi**.

Per això, en Odoo, l'agregació en sentit estricte no es resol "apuntant a una relació" (perquè una relació `Many2many` no és un model reutilitzable com a tal), sinó **materialitzant-la com un model propi**.

- Si només vols dir que `A` es relaciona amb `B`, un `Many2many` pot ser suficient.
- Si la relació té **atributs propis**, **restriccions pròpies** o una tercera entitat ha d'apuntar a eixa relació, llavors ja no n'hi ha prou amb un `Many2many`: cal un model intermedi.

**Exemple conceptual:** una `Matrícula` no és simplement que un `ALUMNE` estiga relacionat amb un `MÒDUL`; és una unitat amb significat propi. Pot tindre data, estat, convocatòria, nota, etc.

**Exemple d'agregació estricta:** si d'eixa `Matrícula` naix una `NOTA`, una `INCIDÈNCIA` o un `JUSTIFICANT`, estos elements no haurien d'apuntar directament ni a `ALUMNE` ni a `MÒDUL`, sinó a la `Matrícula` com a unitat.

En Odoo, això equival a tindre un model com `centre.matricula` o `agrupaciomusical.convocatoria`, i fer que la tercera entitat apunte a eixe model amb un `Many2one`.

:::{note}
**Idea clau**

Quan en ER una relació "puja de nivell" i passa a comportar-se com un objecte del domini, en Odoo solem deixar de pensar en una `Many2many` simple i passem a crear un **model intermedi amb identitat pròpia**.
:::

```{tikz}
\usetikzlibrary{shapes.geometric, positioning, calc}
\begin{tikzpicture}[
    font=\sffamily,
    entity/.style={draw, thick, fill=white, minimum width=2.6cm, minimum height=0.95cm, align=center, font=\bfseries},
    t_white/.style={draw, thick, fill=white, isosceles triangle, isosceles triangle apex angle=60, inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm},
    t_black/.style={draw, thick, fill=black, isosceles triangle, isosceles triangle apex angle=60, inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm}
]

%  ENTITATS SUPERIORS 
\node[entity] (A) at (-3.1,0) {ALUMNE};
\node[entity] (M) at (3.1,0) {MÒDUL};

%  RELACIÓ M:N 
\coordinate (midTop) at (0,0);
\node[t_black, rotate=-180, anchor=lower side] at ($(midTop)+(-0.001,0)$) (tL) {};
\node[t_black, rotate=0, anchor=lower side] at ($(midTop)+(0.001,0)$) (tR) {};

\draw[thick] (A.east) -- (tL.apex);
\draw[thick] (M.west) -- (tR.apex);

\node[above, xshift=-8pt] at ($(A.east)!0.5!(tL.apex)$) {n};
\node[above, xshift=8pt] at ($(tR.apex)!0.5!(M.west)$) {m};
\node[font=\scriptsize\itshape, below=0.22cm of midTop] {matrícula};

%  MARC D'AGREGACIÓ 
\draw[dashed, thick] ($(A.north west)+(-0.35,0.35)$) rectangle ($(M.south east)+(0.35,-0.9)$);

%  EIX CENTRAL 
\coordinate (AggTop) at (0,-0.9);
\coordinate (AggMid) at (0,-2.0);
\draw[thick] (AggTop) -- (AggMid);

%  RELACIÓ INFERIOR (ROMBE VERTICAL PERFECTE) 
\coordinate (R2) at (0,-2.8);

\coordinate (top) at ($(R2)+(0,0.40)$);
\coordinate (bot) at ($(R2)+(0,-0.40)$);
\coordinate (left) at ($(R2)+(-0.40,0)$);
\coordinate (right) at ($(R2)+(0.40,0)$);

% Blanc amunt
\filldraw[fill=white, draw=black, thick] (top) -- (left) -- (right) -- cycle;

% Negre avall
\filldraw[fill=black, draw=black, thick] (bot) -- (left) -- (right) -- cycle;

%  ENTITAT NOTA (ARA CENTRADA BAIX) 
\node[entity] (N) at (0,-4.8) {NOTA};

%  CONNEXIONS NETES 
\draw[thick] (AggMid) -- (top);
\draw[thick] (bot) -- (N.north);

%  CARDINALITATS 
\node[left=7pt] at ($(AggMid)!0.55!(top)$) {1};
\node[left=7pt] at ($(bot)!0.62!(N.north)$) {n};

%  TEXT RELACIÓ 
\node[font=\scriptsize\itshape] at ($(R2)+(1,0)$) {genera};

\end{tikzpicture}
```

En este dibuix, la idea important no és tant la `NOTA` en si, sinó que **la relació `Matrícula` entre `ALUMNE` i `MÒDUL` es tracta com una unitat**. Això és justament el que justifica parlar d'agregació.

Si ho portem a Odoo, la lectura pràctica seria esta:

- `centre.alumne` i `centre.modul` són entitats normals;
- `centre.matricula` és el model intermedi que materialitza la relació;
- `centre.nota` apuntaria a `centre.matricula`, no directament a `centre.alumne` o `centre.modul`.

:::{note}
Per coherència conceptual: el diagrama d'agregació està **simplificat** i no dibuixa tots els atributs.

- `data_matricula` és un atribut propi de `centre.matricula`.
- `valor` és un atribut propi de `centre.nota`.

Es poden afegir com a ovals al diagrama; ací s'han omés per prioritzar la lectura de l'estructura de la relació.
:::

```python   
class Matricula(models.Model):
    _name = 'centre.matricula'

    alumne_id = fields.Many2one('centre.alumne', required=True, ondelete='cascade')
    modul_id = fields.Many2one('centre.modul', required=True, ondelete='cascade')
    data_matricula = fields.Date(string="Data de matrícula")

class Nota(models.Model):
    _name = 'centre.nota'

    matricula_id = fields.Many2one('centre.matricula', required=True, ondelete='cascade')
    valor = fields.Float(string="Valor de la nota")
```


### Generalització i especialització

Les relacions de tipus **"és-un"** es poden llegir en dos sentits complementaris:

- **Generalització**: des de subtipus cap a supertipus (pujar/agrupar).
- **Especialització**: des de supertipus cap a subtipus (baixar/dividir).

```{tikz}
\usetikzlibrary{shapes.geometric, positioning}
\begin{tikzpicture}[
    font=\sffamily,
    entity/.style={draw, thick, fill=white, minimum width=2.5cm, minimum height=1cm, align=center, font=\bfseries}
]
    \node[entity] (P) {PERSONA};
    \node[entity, below left=1.5cm and 0.5cm of P] (A) {ALUMNE};
    \node[entity, below right=1.5cm and 0.5cm of P] (Pr) {PROFESSOR};
    
    \draw[thick] (P) -- (0,-0.8) -- (-2,-0.8) -- (A.north);
    \draw[thick] (0,-0.8) -- (2,-0.8) -- (Pr.north);
    \node[draw, circle, thick, fill=white, inner sep=2pt] at (0,-0.8) {\scriptsize d}; 
\end{tikzpicture}
```

#### Tipus d'especialització i la seua implementació

En Odoo, per a gestionar aquestes regles, utilitzarem normalment camps booleans o de selecció en el supertipus (`res.partner`) i validacions Python (`@api.constrains`).

##### 1) Disjunta vs Solapada

- **Disjunta (XOR):** Una persona és o bé alumne o bé professor, però mai les dues coses.
- **Solapada (OR):** Una persona pot ser alumne i, al mateix temps, tutor o professor.

**Com implementar la Disjunció en Odoo:**

```python
class ResPartner(models.Model):
    _inherit = 'res.partner'

    tipo_entidad = fields.Selection([
        ('alumne', 'Alumne'),
        ('professor', 'Professor')
    ], string="Tipus de Persona")

    @api.constrains('tipo_entidad')
    def _check_disjuncion(self):
        # En usar un Selection, Odoo ja força per defecte que només triem un.
        # Si usàrem booleans (is_student, is_teacher), faríem:
        for record in self:
            if record.is_student and record.is_teacher:
                raise ValidationError("No es pot ser alumne i professor alhora.")
```

##### 2) Total vs Parcial

- **Total:** Tota `PERSONA` registrada ha de ser obligatòriament o alumne o professor.
- **Parcial:** Podem tindre una `PERSONA` (com un contacte de manteniment) que no siga ni alumne ni professor.

**Com implementar l'Especialització Total:**

```python
class ResPartner(models.Model):
    _inherit = 'res.partner'

    # Forcem que el camp siga obligatori
    tipo_entidad = fields.Selection([
        ('alumne', 'Alumne'),
        ('professor', 'Professor')
    ], required=True, string="Rol Obligatori")
```

#### Pas a model relacional (L'estratègia Odoo)

El patró que Odoo segueix amb `_inherits` (delegació) correspon a l'estratègia de **taules separades per a cada entitat**:

- `res_partner`: Taula pare (atributs comuns: nom, DNI, email).
- `centre_alumne`: Taula filla (atributs específics: matrícula, grup).

**Exemple d'especialització delegada:**

```python
class Alumne(models.Model):
    _name = 'centre.alumne'
    _inherits = {'res.partner': 'partner_id'}

    # PK de l'especialització que és FK cap al pare (Persona)
    partner_id = fields.Many2one('res.partner', required=True, ondelete='restrict')
    matricula = fields.Char(string="Número de Matrícula")
```

#### Resum de restriccions

| Restricció | Mecanisme Odoo Recomanat |
| --- | --- |
| **Especialització Total** | `required=True` en el camp discriminador del Pare. |
| **Especialització Parcial** | Camp opcional (sense `required`). |
| **Especialització Disjunta** | Camp `Selection` (només una opció) o `@api.constrains` sobre booleans. |
| **Especialització Solapada** | Diversos camps `Boolean` independents. |

::: {tip}
Recorda que si uses `_inherits` (delegació), Odoo crea automàticament els registres en el pare quan crees un fill, però has de decidir si el rol del pare es bloqueja per a altres usos mitjançant la teua lògica de negoci.
:::



### Atributs Calculats (Computed Fields)

Un **atribut calculat** (representat sovint amb una **"o"** o línies discontínues en el diagrama ER) és aquell el valor del qual no es guarda directament a la base de dades (per defecte), sinó que s'obté a partir d'altres dades del model.

Exemple: L'edat d'una persona es calcula a partir de la seua data de naixement.

```{tikz}
\usetikzlibrary{shapes.geometric, positioning}
\begin{tikzpicture}[
    font=\sffamily,
    entity/.style={draw, thick, fill=white, minimum width=2.5cm, minimum height=1cm, align=center, font=\bfseries},
    attribute/.style={draw, ellipse, fill=white, minimum width=2cm, minimum height=0.7cm, font=\scriptsize\itshape},
    computed/.style={draw, ellipse, fill=gray!10, dashed, minimum width=2cm, minimum height=0.7cm, font=\scriptsize\itshape}
]
    \node[entity] (P) {PERSONA};
    \node[attribute, above left=0.5cm and 0.2cm of P] (data) {data\_naixement};
    \node[computed, above right=0.5cm and 0.2cm of P] (edat) {edat (o)};
    
    \draw[thick] (P) -- (data);
    \draw[thick] (P) -- (edat);
\end{tikzpicture}
```

**Com implementar-ho en Odoo:**

En Odoo, fem servir l'atribut `compute` apuntant al nom d'una funció. És obligatori utilitzar el decorador `@api.depends` per indicar quins camps, si canvien, han de fer que el valor es torne a calcular.

```python
from odoo import models, fields, api
from datetime import date

class Persona(models.Model):
    _name = 'centre.persona'

    data_naixement = fields.Date(string="Data de Naixement")
    
    # El camp calculat
    edat = fields.Integer(string="Edat", compute="_compute_edat")

    @api.depends('data_naixement')
    def _compute_edat(self):
        for record in self:
            if record.data_naixement:
                today = date.today()
                record.edat = today.year - record.data_naixement.year
            else:
                record.edat = 0
```

#### Característiques clau dels Computed Fields:

1.  **No s'emmagatzemen (per defecte):** El valor es calcula al vol cada vegada que es demana. Això estalvia espai però impedeix fer cerques directes per eixe camp a la base de dades.
2.  **Paràmetre `store=True`:** Si volem poder cercar o filtrar per eixe camp, hem d'afegir `store=True`. Odoo el calcularà i guardarà el resultat en una columna física, actualitzant-lo només quan canvien les seues dependències.
    ```python
    edat = fields.Integer(string="Edat", compute="_compute_edat", store=True)
    ```
3.  **Read-only:** Per defecte, un camp calculat no es pot editar manualment en el formulari, ja que el seu valor depén de la funció.

::: {admonition} Diferència ER vs Odoo
:class: tip
Mentre que en un disseny relacional pur sovint evitem guardar dades derivades per evitar redundància, en Odoo l'ús de camps calculats amb `store=True` és una pràctica molt comuna per a millorar el rendiment en llistats i informes.
:::







## Disseny de Qualitat: Odoo i la Normalització

La **Normalització** és el procés d'organitzar les dades per evitar la redundància i protegir la integritat. El framework d'Odoo, pel seu propi disseny, ens "obliga" a seguir les millors pràctiques de les **Formes Normals (FN)** de manera quasi automàtica si seguim les seues convencions.

### Correspondència entre Teoria i Pràctica

| Problema de disseny | Teoria de BD (Normalització) | Solució en Odoo |
| --- | --- | --- |
| Camps repetitius (Telèfon1, Telèfon2) | Viola la **1FN** | Crear model nou + `One2many` |
| Dades barrejades en relacions complexes | Viola la **2FN** | Crear **model associatiu** intermedi |
| Redundància de dades comunes | Viola la **3FN** | Usar **Herència/Delegació** (`_inherits`) |
| Determinants no clau quan hi ha claus candidates múltiples | Viola la **FNBC** | Declarar totes les claus amb `_sql_constraints` + separar models |
| Atributs multivalents independents combinats en un sol model | Viola la **4FN** | Crear models `One2many` separats per a cada fet independent |



### Implementació de les Formes Normals en Odoo

#### 1. Odoo i la Primera Forma Normal (1FN)
La 1FN prohibeix els atributs multivalents i els grups repetitius. Tots els valors han de ser atòmics.
* **Com ho força Odoo:** En Odoo no podem guardar una llista de telèfons en un camp de text separat per comes si volem gestionar-los bé. Odoo ens obliga a crear un model independent i relacionar-lo amb un `One2many`.
* **Resultat:** En crear models per a atributs multivalents, garantim que les dades siguen atòmiques i filtrables.

#### 2. Odoo i la Segona Forma Normal (2FN)
La 2FN diu que tots els atributs han de dependre de tota la clau primària, no només d'una part (evita dependències parcials).
* **Com ho força Odoo:** Les relacions ternàries (M:N:P) es resolen sempre amb un **model associatiu intermedi**. En definir eixe model (com `agrupaciomusical.convocatoria`), Odoo ens obliga a identificar clarament quines dades depenen de la combinació de les tres entitats.
* **Resultat:** Evitem dependències parcials en materialitzar les relacions n-àries com a models propis amb la seua pròpia PK composta funcional (`_sql_constraints`).

#### 3. Odoo i la Tercera Forma Normal (3FN)
La 3FN prohibeix les dependències transitives (atributs que depenen d'altres atributs que no són la clau).
* **Com ho força Odoo:** Mitjançant la **Delegació (`_inherits`)**. En lloc de repetir camps com `nom`, `adreça` o `email` en cada taula (`Alumne`, `Professor`), Odoo ens empeny a delegar en `res.partner`.
* **Resultat:** Les dades personals viuen en un sol lloc. Si una adreça canvia, es reflecteix en tots els rols vinculats, eliminant redundàncies transitives.

#### 4. Odoo i la Forma Normal de Boyce-Codd (FNBC)
La FNBC és una versió més estricta de la 3FN. Exigeix que **tots els determinants d'una dependència funcional siguen superclaus** (clau candidata o superconjunt d'una). En la pràctica, els problemes apareixen quan un model té **dues claus candidates que se solapen**.

* **Situació problemàtica:** imagina un model `centre.horari` amb camps `professor_id`, `assignatura_id` i `aula_id`, on:
  - Cada professor sempre imparteix la mateixa assignatura: `professor_id → assignatura_id`
  - Però `professor_id` sol no és la clau del model (la clau real és `(professor_id, aula_id)`).
  - Com que `professor_id` determina `assignatura_id` però no és superclau, **es viola la FNBC**.

* **Com ho resol Odoo:** separant la dependència en un model propi. La relació *"quin professor imparteix quina assignatura"* passa a un model `centre.docencia`, i `centre.horari` només conté el que depèn plenament de la seua clau:

```python
class Docencia(models.Model):
    _name = 'centre.docencia'

    professor_id = fields.Many2one('centre.professor', required=True)
    assignatura_id = fields.Many2one('centre.assignatura', required=True)

    _sql_constraints = [
        ('uk_professor_assignatura',
         'UNIQUE(professor_id, assignatura_id)',
         'Un professor no pot tindre assignada la mateixa assignatura dues vegades.'),
    ]

class Horari(models.Model):
    _name = 'centre.horari'

    docencia_id = fields.Many2one('centre.docencia', required=True)
    aula_id = fields.Many2one('centre.aula', required=True)
    dia = fields.Selection([('dl', 'Dilluns'), ('dm', 'Dimarts'),
                            ('dc', 'Dimecres'), ('dj', 'Dijous'),
                            ('dv', 'Divendres')], required=True)
    hora_inici = fields.Float(required=True)
```

* **Resultat:** cada taula té una única clau candidata declarada, totes les dependències funcionals parteixen d'una superclau i s'eliminen les anomalies d'actualització.

:::{tip}
Declara **sempre** amb `_sql_constraints` totes les combinacions de camps que han de ser úniques en el model. Açò no sols compleix la FNBC sinó que documenta explícitament quines són les claus candidates del teu disseny.
:::

#### 5. Odoo i la Quarta Forma Normal (4FN)
La 4FN elimina les **dependències multivaluades independents**. La regla és senzilla: si una entitat té dos atributs multivalents que *no depenen l'un de l'altre*, no han d'estar en el mateix model.

* **Situació problemàtica:** un professor pot impartir diverses assignatures **i** pot estar assignat a diverses aules, però ambdós fets són independents entre si. Si els guardem en una sola taula `centre.professor_assignatura_aula`, obtenim un producte cartesià fals: hauríem de repetir cada assignatura per a cada aula i viceversa.

```
# ❌ Mal disseny (viola 4FN)
professor_id | assignatura_id | aula_id
--  | -- | -
Prof. Garcia |  Matemàtiques  | Aula 1
Prof. Garcia |  Matemàtiques  | Aula 2   ← redundància
Prof. Garcia |  Física        | Aula 1   ← redundància
Prof. Garcia |  Física        | Aula 2   ← redundància
```

* **Com ho resol Odoo:** creant dos models `One2many` totalment independents, un per a cada fet multivalent:

```python
# ✅ Bon disseny (compleix 4FN + 3FN amb herència)
class Professor(models.Model):
    _name = 'centre.professor'
    _inherits = {'res.partner': 'partner_id'} # Herència delegada per evitar repetir dades de persona

    partner_id = fields.Many2one('res.partner', required=True, ondelete='restrict') # FK al pare (Persona)

    # Fet 1: quines assignatures imparteix (independent del fet 2)
    docencia_ids = fields.One2many(
        'centre.docencia', 'professor_id', string="Assignatures")

    # Fet 2: quines aules utilitza (independent del fet 1)
    aula_ids = fields.One2many(
        'centre.assignacio.aula', 'professor_id', string="Aules assignades")

# Classe intermedi per a cada fet multivalent, evitant el producte cartesià i la redundància. Docencia i AssignacióAula són totalment independents entre si i només depenen de Professor.
class Docencia(models.Model):
    _name = 'centre.docencia'
    professor_id = fields.Many2one('centre.professor', required=True, ondelete='cascade')
    assignatura_id = fields.Many2one('centre.assignatura', required=True)

class AssignacioAula(models.Model):
    _name = 'centre.assignacio.aula'
    professor_id = fields.Many2one('centre.professor', required=True, ondelete='cascade')
    aula_id = fields.Many2one('centre.aula', required=True)
```

```{tikz}
\usetikzlibrary{shapes.geometric, positioning, calc}
\begin{tikzpicture}[
    font=\sffamily,
    entity/.style={draw, thick, fill=white, minimum width=3.2cm, minimum height=1.1cm, align=center, font=\bfseries},
    t_white/.style={draw, thick, fill=white, isosceles triangle, isosceles triangle apex angle=60, inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm},
    t_black/.style={draw, thick, fill=black, isosceles triangle, isosceles triangle apex angle=60, inner sep=0pt, minimum width=3.5mm, minimum height=5.5mm}
]
    % NIVELL 1: Herència
    \node[entity] (PERSONA) {PERSONA\\(res.partner)};
    \node[entity, below=1.5cm of PERSONA] (PROF) {PROFESSOR};
    
    % Herència: línia recta amb símbol de disjunció
    \draw[thick] (PERSONA) -- (PROF);
    \node[draw, circle, thick, fill=white, inner sep=1.5pt] at ($(PERSONA)!0.5!(PROF)$) {\scriptsize d};

    % NIVELL 2: Entitats associatives
    \node[entity, below left=2.5cm and 1.5cm of PROF] (DOC) {DOCÈNCIA\\(associativa)};
    \node[entity, below right=2.5cm and 1.5cm of PROF] (ASSAULA) {ASSIGNACIÓ AULA\\(associativa)};
    
    % RELACIÓ 1: PROFESSOR -> DOCÈNCIA (1:n)
    \coordinate (mid1L) at ($(PROF.south west)!0.5!(DOC.north)$);
    \node[t_white, rotate=45, anchor=lower side] at ($(mid1L)+(-0.001,0)$) (tw1) {};
    \node[t_black, rotate=225, anchor=lower side] at ($(mid1L)+(0.001,0)$) (tb1) {};
    
    \draw[thick] (PROF.south west) -- (tw1.apex);
    \draw[thick] (DOC.north) -- (tb1.apex);
    
    \node[above, xshift=-4pt] at ($(PROF.south west)!0.33!(tw1.apex)$) {1};
    \node[below, xshift=4pt] at ($(tw1.apex)!0.66!(DOC.north)$) {n};
    
    % RELACIÓ 2: PROFESSOR -> ASSIGNACIÓ AULA (1:n)
    \coordinate (mid2R) at ($(PROF.south east)!0.5!(ASSAULA.north)$);
    \node[t_white, rotate=135, anchor=lower side] at ($(mid2R)+(-0.001,0)$) (tw2) {};
    \node[t_black, rotate=-45, anchor=lower side] at ($(mid2R)+(0.001,0)$) (tb2) {};
    
    \draw[thick] (PROF.south east) -- (tw2.apex);
    \draw[thick] (ASSAULA.north) -- (tb2.apex);
    
    \node[above, xshift=4pt] at ($(PROF.south east)!0.33!(tw2.apex)$) {1};
    \node[below, xshift=-4pt] at ($(tw2.apex)!0.66!(ASSAULA.north)$) {n};

    % NIVELL 3: Entitats de resultat
    \node[entity, below=2cm of DOC] (ASSIG) {ASSIGNATURA};
    \node[entity, below=2cm of ASSAULA] (AULA) {AULA};

    % RELACIÓ 3: DOCÈNCIA -> ASSIGNATURA (n:1)
    \coordinate (mid3) at ($(DOC.south)!0.5!(ASSIG.north)$);
    \node[t_black, rotate=90, anchor=lower side] at ($(mid3)+(-0.001,0)$) (tb3) {};
    \node[t_white, rotate=-90, anchor=lower side] at ($(mid3)+(0.001,0)$) (tw3) {};
    
    \draw[thick] (DOC.south) -- (tb3.apex);
    \draw[thick] (ASSIG.north) -- (tw3.apex);
    
    \node[left=6pt] at ($(DOC.south)!0.33!(tb3.apex)$) {n};
    \node[right=6pt] at ($(tw3.apex)!0.66!(ASSIG.north)$) {1};

    % RELACIÓ 4: ASSIGNACIÓ AULA -> AULA (n:1)
    \coordinate (mid4) at ($(ASSAULA.south)!0.5!(AULA.north)$);
    \node[t_black, rotate=90, anchor=lower side] at ($(mid4)+(-0.001,0)$) (tb4) {};
    \node[t_white, rotate=-90, anchor=lower side] at ($(mid4)+(0.001,0)$) (tw4) {};
    
    \draw[thick] (ASSAULA.south) -- (tb4.apex);
    \draw[thick] (AULA.north) -- (tw4.apex);
    
    \node[left=6pt] at ($(ASSAULA.south)!0.33!(tb4.apex)$) {n};
    \node[right=6pt] at ($(tw4.apex)!0.66!(AULA.north)$) {1};

\end{tikzpicture}
```

* **Resultat:** cada model representa un únic fet independent, s'eliminen les files redundants, s'aplica herència per no repetir dades de persona en cada especialització, i el model és coherent amb la realitat i les formes normals.

::: {admonition} Conclusió de Disseny
:class: important
Dissenyar correctament en Odoo utilitzant **models relacionats + herència** en lloc de camps de text gegants o redundants és, a la pràctica, l'aplicació física del procés de normalització que demana la teoria relacional.
:::

Aquesta secció ha sigut una introducció al disseny de models en Odoo, centrada en com les bones pràctiques de normalització es reflecteixen en la manera com Odoo ens obliga a estructurar les dades. No s'ha de prendre com una guia exhaustiva de totes les tècniques de disseny, sinó com un punt de partida per a entendre per què Odoo funciona com funciona i com aprofitar-ho per a crear models robustos i ben estructurats. 

Abans de realitzar l'exercici pràctic 6, anem a veure com es creen les vistes i els permisos d'accés, que són els següents passos després de definir els models.

## Crear les vistes
Les vistes són fitxers XML que defineixen com es mostra la informació a l’usuari. Sense vistes, Odoo no sap com presentar els formularis ni els llistats dels teus models.


### Què fa Odoo quan no té vistes?

Quan instal·les un mòdul amb un model nou (p. ex. `centre.alumne`) i no has creat cap vista XML, Odoo:
- Detecta que el model és nou.
- Mira quins camps té (p. ex. name, edat, curs…).
- Genera vistes automàtiques perquè pugues treballar amb el model encara que no hages escrit ni una línia d’XML.

Odoo crea tres elements bàsics:
- Vista en forma de llistat amb tots els camps visibles.
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
- Com es mostra el llistat,
- Quins camps van junts en un group,
- Quines pestanyes hi ha,
- Què és editable i què no,
- I tota la part visual declarativa (sense CSS).

És el “frontend” d’Odoo, però al seu estil: estructurat, declaratiu i en XML.  
Com que tenen molta molla (list, form, search, kanban, calendar, pivot, graph, activity…), treballarem les més importants amb calma. Per ara, farem un exemple bàsic per al model `centre.alumne`.

### Exemple bàsic de vistes per a `centre.alumne`
Aquest archiu XML defineix les interfícies d'usuari (vistes) i la navegació per gestionar alumnes dins del sistema Odoo. Utilitza tres tipus de registres: una vista de formulari, una vista de llista i una acció que les vincula.

L'usuari fa clic en "Alumnes" → es carrega la **vista de llista** → pot fer clic en una fila per accedir a la **vista de formulari** de l'alumne seleccionat.


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

    <record id="centre_alumne_list" model="ir.ui.view">
        <field name="name">centre.alumne.list</field>
        <field name="model">centre.alumne</field>
        <field name="arch" type="xml">
            <list>
                <field name="name"/>
                <field name="edat"/>
                <field name="curs"/>
            </list>
        </field>
    </record>

    <record id="centre_alumne_action" model="ir.actions.act_window">
        <field name="name">Alumnes</field>
        <field name="res_model">centre.alumne</field>
        <field name="view_mode">list,form</field>
    </record>

    <menuitem id="centre_menu_root" name="Centre"/>
    <menuitem id="centre_menu_alumnes" parent="centre_menu_root"
              action="centre_alumne_action" name="Alumnes"/>
</odoo>
```

### Components Principals

#### **Vista de Formulari** (`centre_alumne_form`)
- **Funció**: Permet visualitzar i editar els detalls d'un alumne individual
- **Estructura**:
    - `<form>`: Contenidor principal del formulari
    - `<sheet>`: Zona editable del formulari
    - `<group>`: Agrupa els camps de forma visual
    - `<field>`: Cada camp representa una propietat de l'alumne (nom, edat, curs)

#### **Vista de Llista** (`centre_alumne_list`)
- **Funció**: Mostra una llista de tots els alumnes en format taula
- **Estructura**:
    - `<list>`: Defineix la llista
    - `<field>`: Cada camp es converteix en una columna de la taula

#### **Acció de Finestra** (`centre_alumne_action`)
- **Funció**: Vincula les vistes anteriors i defineix el comportament quan s'accedeix
- **Propietats clau**:
    - `view_mode`: Especifica l'ordre de visualització (`list` primer, després `form`)
    - `res_model`: Indica el model que es gestiona

#### **Elements de Menú**
- `centre_menu_root`: Menú arrel "Centre"
- `centre_menu_alumnes`: Submenu que enllaça l'acció, mostrant "Alumnes"


Ara que tenim una visió general del que fa aquest XML i tot i que encara no coneixem els detalls, anem a veure els permisos d'accés, que són el següent pas després de crear els model y les vistes. Després d'aixo serà el moment de realitzar l'exercici pràctic, on posarem en pràctica tot el que hem vist fins ara sobre la creació de models. Les vistes les abordarem en el proper capítol, on veurem com personalitzar-les i fer-les més amigables per a l'usuari.

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
  </record>

  <record id="group_alumnat" model="res.groups">
    <field name="name">Alumnat</field>    
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


## Aplicació de permisos en vistes amb l'atribut `groups`

Els permisos que definim en `ir.model.access.csv` controlen l'accés global al model (si pots crear, editar, llegir o esborrar). Però si vols **amagar camps, botons o menús específics** per a certs usuaris sense denegar accés total al model, pots usar l'atribut `groups` directament en els elements XML de les vistes.

### Concepte bàsic de `groups`

L'atribut `groups` acepta una llista de xml_id de grups d'usuaris (separats per comes) i fa que l'element **només sigui visible** per a els usuaris que pertanyen a eixos grups.

**Important:** `groups` és només **control visual**; la seguretat real s'aplica al servidor amb `ir.model.access.csv` i regles de registre (`ir.rule`).

### Definir grups propis

Primer, cal crear els grups en un fitxer de seguretat. Per exemple, si vols separar "Professorat" i "Alumnat":

Fitxer: `security/security.xml`

```xml
<odoo>
    <!-- Grup per al professorat -->
    <record id="group_professorat" model="res.groups">
        <field name="name">Professorat</field>
    </record>

    <!-- Grup per a l'alumnat -->
    <record id="group_alumnat" model="res.groups">
        <field name="name">Alumnat</field>
    </record>
</odoo>
```

Cada grup té un `id` (ací: `group_professorat`, `group_alumnat`) que después usem en l'atribut `groups` de les vistes.

### Exemple complet amb `groups` en vistes

Fitxer: `views/alumne_view.xml`

```xml
<odoo>
    <!-- Vista de formulari amb camps i botons restringits -->
    <record id="centre_alumne_form" model="ir.ui.view">
        <field name="name">centre.alumne.form</field>
        <field name="model">centre.alumne</field>
        <field name="arch" type="xml">
            <form string="Alumne">
                <sheet>
                    <group>
                        <!-- Camps visibles per a tothom (sense groups) -->
                        <field name="name"/>
                        <field name="edat"/>
                        <field name="curs"/>
                        
                        <!-- Camp "expedient" visible NOMÉS per a Professorat -->
                        <field name="expedient" groups="gestio_alumnes.group_professorat"/>
                    </group>
                    
                    <!-- Secció de botons (footer) -->
                    <footer>
                        <!-- Botó d'acció reservat NOMÉS a Professorat -->
                        <button 
                            name="action_calcular_nota" 
                            type="object" 
                            string="Calcular nota"
                            class="oe_highlight"
                            groups="gestio_alumnes.group_professorat"/>
                        
                        <!-- Botó visible per a Alumnat -->
                        <button 
                            name="action_solicitar_tutoria" 
                            type="object" 
                            string="Solicitar tutoría"
                            groups="gestio_alumnes.group_alumnat"/>
                    </footer>
                </sheet>
            </form>
        </field>
    </record>

    <!-- Vista de llista amb columnes restringides -->
    <record id="centre_alumne_list" model="ir.ui.view">
        <field name="name">centre.alumne.list</field>
        <field name="model">centre.alumne</field>
        <field name="arch" type="xml">
            <list>
                <field name="name"/>
                <field name="edat"/>
                <field name="curs"/>
                <!-- Columna de notes visible només per Professorat -->
                <field name="nota" groups="gestio_alumnes.group_professorat"/>
            </list>
        </field>
    </record>

    <!-- Menú visible només per a Professorat -->
    <menuitem id="centre_menu_root" name="Centre"/>
    <menuitem id="centre_menu_alumnes" 
        parent="centre_menu_root"
        action="centre_alumne_action" name="Alumnes"
        groups="gestio_alumnes.group_professorat"/>
    
    <!-- Menú alt per a Alumnat (accés a data pública) -->
    <menuitem id="centre_menu_alumnes_alumnat" 
        parent="centre_menu_root"
        action="centre_alumne_action_alumnat" 
        name="Els meus dades"
        groups="gestio_alumnes.group_alumnat"/>
</odoo>
```

### Explicació dels exemples

| Exemple | Explicació |
| --- | --- |
| `<field name="expedient" groups="gestio_alumnes.group_professorat"/>` | El camp "expedient" només apareix en el formulari si l'usuari pertany al grup `group_professorat`. Els altres usuaris no el veuen. |
| `<button ... groups="gestio_alumnes.group_professorat"/>` | El botó "Calcular nota" només es mostra per a Professorat. Els altres grups no veuran eixe botó en el footer. |
| `<field name="nota" groups="gestio_alumnes.group_alumnat"/>` | La columna "nota" a la taula (list) apareix només si l'usuari pertany a `group_alumnat`. |
| `<menuitem ... groups="gestio_alumnes.group_professorat"/>` | El menú "Alumnes" es mostra només als usuaris del grup Professorat. Els altres no el veuran en el menú principal. |

### Múltiples grups (OR lògic)

Si vols que un element sigua visible per a **múltiples grups** (lògica OR), separa els xml_id amb comes:

```xml
<!-- Visible per a Professorat O Administrador -->
<field name="qualificacio" groups="gestio_alumnes.group_professorat,gestio_alumnes.group_admin"/>

<!-- Visible per a qualsevol dels grups indicats -->
<button name="action_validate" type="object" 
                groups="gestio_alumnes.group_coordinador,gestio_alumnes.group_director"/>
```

### Inclusió dels fitxers en el manifest

Recorda que ambdós fitxers (security i vistes) han d'estar referenciats en el manifest per a que es carreguin correctament:

Fitxer: `__manifest__.py`

```python
{
        'name': "Gestió d'Alumnes",
        'version': '19.0.1.0.0',
        'depends': ['base'],
        'data': [
                # Seguretat (permisos i grups): s'ha de carregar PRIMER
                'security/security.xml',
                'security/ir.model.access.csv',
                
                # Vistes: es carreguen DESPRÉS
                'views/alumne_view.xml',
        ],
        'installable': True,
        'application': True,
}
```

### Ordre d'importació és crítica

**Molt important:** Els fitxers de seguretat (`security/`) han de carregar-se **SEMPRE PRIMER** que els de vistes i dades, ja que les vistes fan referència als grups definits en els fitxers de seguretat. Si invertixes l'ordre, Odoo llançarà un error perquè buscarà grups que no existeixen.

### Resum del patró

1. **Definir grups** en `security/security.xml` amb un `id` únic (`group_professorat`, etc.).
2. **Assignar usuaris** als grups (en la interfície d'Odoo: Configuració → Usuaris i Grups).
3. **Aplicar `groups`** en els elements de vista que vulgues restringir.
4. **Carregar en ordre**: primer seguretat, després vistes.

### Advertència sobre seguretat

L'atribut `groups` **no és una barrera de seguretat real**. Un usuari malintencionat que accedisca directament a l'API o a la base de dades podria eludir estos controls. La seguretat real s'implementa amb:

- **`ir.model.access.csv`**: Controla permisos globals al model (lectura, escriptura, creació, esborrat).
- **`ir.rule`**: Permet filtrar quins registres pot veure/editar cada usuari (seguretat a nivell de registres).

L'atribut `groups` és només per a fer la interfície d'usuari més neta i intuïtiva, ocultant elements que no necessita veure.



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

En paraules simples: **instal·lar = donar d’alta el mòdul en eixa base de dades per primera vegada**.

Flux mental ràpid (pas a pas):
1. Odoo llig el manifest.
2. Crea estructura de dades (taules/camps).
3. Carrega seguretat, vistes, menús i dades declaratives.
4. Deixa el mòdul disponible en la interfície.

Mini checklist abans d’instal·lar:
- El mòdul apareix en Apps.
- `__manifest__.py` té `depends` i `data` correctes.
- Els fitxers XML/CSV existeixen i estan ben referenciats.

CLI:
```bash
./odoo-bin -i nom_modul -d nom_bd
```
(-i = install)

:::{tip}
**Quan usar `-i`?**

Només quan el mòdul **encara no està instal·lat** en eixa BD.
Si ja està instal·lat, el que toca normalment és `-u`.
:::

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

En paraules simples: **actualitzar = reaplicar el mòdul ja instal·lat amb els canvis nous**.

Flux mental ràpid (pas a pas):
1. Odoo detecta el mòdul ja instal·lat.
2. Recarrega la part declarativa (XML/CSV/manifest).
3. Aplica canvis d’esquema (si hi ha camps nous o eliminats).
4. Manté les dades de negoci existents (excepte scripts/operacions que ho modifiquen).

Mini checklist abans d’actualitzar:
- Has guardat tots els fitxers.
- Has revisat errors de sintaxi en XML/Python.
- Saps si també necessites reinici per canvis Python.

CLI:
```bash
./odoo-bin -u nom_modul -d nom_bd
```
(-u = update)

:::{caution}
**Error típic de novell**

Fer només reinici després de tocar vistes/permisos i esperar canvis en pantalla.
Per a XML/CSV/manifest, el que aplica canvis és **`-u`**.
:::

Important: Reiniciar NO actualitza vistes ni permisos.

### Si treballes amb Docker: què fer en cada cas

En entorn Docker, el patró pràctic és este:

1. Si només has tocat **XML/CSV/manifest** → fes **update** del mòdul.
2. Si has tocat **Python** → fes **reinici** del servei Odoo.
3. Si has tocat **Python + XML/CSV/manifest** → fes **update i reinici**.

Comanda típica d’update en Docker (sense deixar un segon servidor corrent):

```bash
docker compose exec -u odoo web odoo -d nom_bd -u nom_modul --stop-after-init
```

:::{tip}
**Com llegir esta comanda (Docker)**

- `docker compose exec` entra a un contenidor ja arrancat.
- `-u odoo` indica l’usuari Linux `odoo` *dins del contenidor* (no és l’usuari del teu host).
- `web` és el servei (normalment el contenidor d’Odoo).
- el segon `odoo` és l’executable d’Odoo dins del contenidor.

**Què vol dir “executable d’Odoo”?**
- És el programa que arranca Odoo des de terminal.
- En instal·lacions des de codi font sol aparéixer com `odoo-bin`.
- En la imatge oficial de Docker sol estar instal·lat com la comanda `odoo` (sovint en `/usr/bin/odoo`).
:::

:::{caution}
**Compte amb els dos `odoo` de la comanda**

En `docker compose exec -u odoo web odoo ...`:
- primer `odoo` (després de `-u`) = usuari Linux
- segon `odoo` = programa que executa Odoo
:::

I després, si has canviat Python, reinicia el servei:

```bash
docker compose restart web
```

:::{tip}
**Regla curta en Docker**

- Canvi només visual/declaratiu (views, menús, permisos, data, manifest) → `-u`
- Canvi només Python (models, mètodes, controladors, hooks) → `restart`
- Canvi mixt → primer `-u`, després `restart`
:::

### Quan usar cada acció?

| Acció              | Quan?                                      | Què recarrega?                          |
| --- | --- | --- |
| Reiniciar servidor | Canvis en codi Python                      | Classes, models, controladors           |
| Instal·lar          | Primera vegada en la BD                    | Tot: models, vistes, menús, permisos    |
| Actualitzar        | Canvis en XML, manifest, permisos, camps   | Vistes, permisos, dades, esquema        |

Regla ràpida:
- Afegixes un camp nou → update (-u)
- Canvies lògica Python d’un mètode → reinici
- Afegixes una vista nova al manifest → update
- Primera vegada que poses el mòdul → install

## Resum del capítol i recomanacions
En aquest capítol hem vist com crear un mòdul bàsic en Odoo, amb models, vistes i permisos. També hem parlat de les diferències entre reiniciar el servidor, instal·lar i actualitzar un mòdul, i quan usar cada acció. Ara convidria realitzar [l'Exercici pràctic 4: Creació d’un mòdul bàsic en Odoo per a la colla](../../Annexos/Tema4_prac6_CrearModul.md) per posar en pràctica aquests conceptes.