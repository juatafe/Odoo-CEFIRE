Exercici pràctic: Creació d’un mòdul bàsic en Odoo per al Club de Patinatge
===============================================================================

## Objectiu de la pràctica

Aquesta pràctica té com a objectiu crear un mòdul senzill d’Odoo utilitzant els coneixements vistos fins ara. El mòdul gestionarà la informació bàsica d’un club de patinatge, incloent patinadores, grups i entrenaments. Amb aquest exercici aprendrem a:

- Crear manualment l’estructura bàsica d’un mòdul d’Odoo.
- Entendre i configurar el fitxer `__manifest__.py`.
- Crear models en Python i relacionar-los (Many2one / One2many) incloent una relació ternària amb model associatiu.
- Generar el fitxer de permisos `ir.model.access.csv`.
- Instal·lar el mòdul i observar les vistes automàtiques que genera Odoo.
- Deixar preparat el mòdul per a afegir vistes XML en el següent exercici.

El mòdul representarà un **sistema bàsic de gestió d’un club de patinatge**.

### Situació i cas d’ús (posada en context)
El Club de Patinatge “CPA Tavernes de la Valldigna” necessita organitzar la informació bàsica per al seu dia a dia:
- Qui són les patinadores/ors (dades bàsiques i nivell).
- En quin grup entrena cadascun.
- Quan es programen els entrenaments i a quin grup van dirigits.

Amb aquest mòdul farem un primer pas per a digitalitzar el club, i en el futur podríem afegir assistències, quotes, entrenadores, calendaris i informes.

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

% --- 1. ENTITATS (Distribució en triangle per a la N:M) ---
\node[entity] (Patinadora) at (-4,0) {PATINADORA};
\node[entity] (Grup) at (4,0) {GRUP};
\node[entity] (Entrenament) at (0,-4) {ENTRENAMENT};

% --- 2. ATRIBUTS (desplaçats per a connexions obliqües) ---
\node[attribute] (dni) at ($(Patinadora.north)+(-0.85,1.05)$) {\underline{dni}};
\node[attribute] (gnom) at ($(Grup.north)+(0.85,1.05)$) {name};
\node[attribute] (edat) at ($(Entrenament.south)+(0.95,-1.00)$) {data};

\draw[thick] ([xshift=-0.45cm]Patinadora.north) -- (dni.south east);
\draw[thick] ([xshift=0.45cm]Grup.north) -- (gnom.south west);
\draw[thick] ([xshift=0.20cm]Entrenament.south) -- (edat.north west);

% --- 3. RELACIÓ TERNÀRIA PATINADORA - GRUP - ENTRENAMENT (N:1:N) ---
\coordinate (RelC) at (0,-1.95);

% Símbol ternari (mateix estil que a intro.md): 4 triangles congruents
\filldraw[fill=black, draw=black, thick]
  (-1.05,-1.35) -- (0,-1.35) -- (-0.52,-2.20) -- cycle;  % esquerra
\filldraw[fill=white, draw=black, thick]
  (1.05,-1.35) -- (0,-1.35) -- (0.52,-2.20) -- cycle;    % dreta (costat Grup = 1)
\filldraw[fill=black, draw=black, thick]
  (0,-3.05) -- (-0.52,-2.20) -- (0.52,-2.20) -- cycle;   % inferior
\filldraw[fill=white, draw=black, thick]
  (0,-1.35) -- (-0.52,-2.20) -- (0.52,-2.20) -- cycle;   % central

% Connexions des de les entitats al símbol ternari
\draw[thick] (Patinadora.south east) -- (-1.05,-1.35) node[pos=0.72, above] {n};
\draw[thick] (Grup.south west) -- (1.05,-1.35) node[pos=0.72, above] {1};
\draw[thick] (Entrenament.north) -- (0,-3.05) node[pos=0.60, right] {n};

% Nom de la relació
\node[font=\scriptsize\itshape] at (1.75,-1.90) {participa};

\end{tikzpicture}

```

:::{admonition} Nota
:class: tip
El dibuix representa una **relació ternària** Patinadora - Grup - Entrenament amb cardinalitat **N:1:N** (costat Patinadora = molts, costat Grup = u, costat Entrenament = molts).

Interpretació pràctica: per a una combinació concreta `(patinadora, entrenament)` només hi ha **un** `grup` possible. Això sol ser coherent si cada entrenament l’organitza un únic grup.
:::

### Mòdul que crearem: `patinatge`
- Nom complet: Gestió Club Patinatge
- Nom tècnic: `patinatge`
- Descripció: Mòdul bàsic per a gestionar patinadores i grup
- Autor: [El vostre nom]
- Categoria: Sports
- Dependències: `base`
- Versió: 16.0.1.0.0
- Llicència: LGPL-3
- Instal·lable i aplicació: Sí
- Models: `patinatge.patinadora`, `patinatge.grup`, `patinatge.entrenament`, `patinatge.participacio`
- Vistes: Generades automàticament per Odoo (sense vistes XML en aquest exercici)
- Permisos: Accés complet als models per a usuaris interns
- Estructura mínima preparada per a afegir vistes en el següent exercici
- Activitat dividida en dos exercicis incrementals
---

## Models que anem a crear

A partir de la documentació del Club de Patinatge “CPA Tavernes de la Valldigna”, definirem tres models bàsics perfectament assumibles amb el que sabem fins ara. Les modalitats i categories del club seran implementades com **camps Selection**, ja que encara no necessitem crear models independents. Més endavant, en altres exercicis, podrem ampliar el mòdul amb més funcionalitats.

Les patinadores tindran:
- Un **grup habitual**.  
- Una **modalitat**.  
- Una **categoria/nivell**.  
- Una llista de **participacions** en entrenaments (relació ternària).

:::{admonition} Nota
:class: tip 
Per mantindre coherència amb el diagrama, la participació no la modelarem com un `Many2many` directe, sinó amb un model associatiu (`patinatge.participacio`) amb tres claus alienes:
- `patinadora_id`
- `grup_id`
- `entrenament_id`

Això representa explícitament la relació ternària i permet afegir restriccions (per exemple, evitar duplicitats amb una clau única composta).

El camp `grup_id` en `patinatge.patinadora` pot conviure amb la ternària: representa el **grup habitual** de la patinadora, mentre que `patinatge.participacio` registra la participació efectiva en cada sessió.
:::

Els entrenaments són sessions puntuals on participen diverses patinadores.

---

### Model `patinatge.patinadora`

**Camps bàsics (dades personals):**
- `name` – Char (heretat de `res.partner` via `_inherits`)  
- `cognoms` – Char  
- `data_naixement` – Date
- `dni` – Char   
- `adreça` – Char (heretat de `res.partner`)  
- `telèfon` – Char (heretat de `res.partner`)  
- `email` – Char (heretat de `res.partner`)   

**Modalitat (segons el club):**
- lliure  
- dansa: 
  - individual
  - parelles  
  - show   

**Categoria / nivell (segons línies del club):**
- Escoleta: Iniciació 1, Iniciació 2  
- Federades: 
  - Nivells 1, 2, 3, 4, 5, 6  
  - Territorials: Benjamí, Aleví, Infantil, Cadet, Júnior, Juvenil, Sènior

Això ho implementarem amb un camp `Selection`.

**Relacions:**
- `grup_id` – Many2one (grup habitual)  
- `participacio_ids` – One2many (participacions de la patinadora)  

---

### Model `patinatge.grup`

Cada grup es defineix per:
- `name` – Char  
- `entrenadora` – Char  
- `modalitat` – Selection  
- `categoria` – Selection  

**Relació amb patinadores:**
- `patinadores_ids` – One2many  
  (llista de patinadores del grup)

**Relacions ternàries:**
- `participacio_ids` – One2many  
  (participacions del grup en entrenaments)

---

### Model `patinatge.entrenament`

Cada entrenament és una sessió amb característiques pròpies:
- `name` – Char  
- `data` – Date  
- `duracio` – Integer  
- `grup_id` – Many2one  
  (el grup que organitza la sessió)

**Participants de la sessió:**
- `participacio_ids` – One2many  
  (registre de participacions de patinadores en eixa sessió)

---

### Model `patinatge.participacio` (relació ternària)

Este model és l’entitat associativa de la ternària **Patinadora - Grup - Entrenament**:

- `patinadora_id` – Many2one (`patinatge.patinadora`)
- `grup_id` – Many2one (`patinatge.grup`)
- `entrenament_id` – Many2one (`patinatge.entrenament`)

I, per evitar duplicitats, afegim:
- `unique(patinadora_id, grup_id, entrenament_id)`

Per a coherència estricta del negoci, si `patinatge.entrenament` també té `grup_id` (grup organitzador), convé afegir una validació (`@api.constrains`) que force:
- `participacio.grup_id == participacio.entrenament_id.grup_id`

---

## Crear el mòdul manualment

Com ja hem vist, és millor crear el mòdul manualment per a entendre bé quina funció té cada fitxer i cada carpeta.

Des de la carpeta `dev_addons`, crea l'estructura inicial del mòdul:

```bash
mkdir -p patinatge/{models,security,views}
touch patinatge/__init__.py
touch patinatge/__manifest__.py
touch patinatge/models/__init__.py
touch patinatge/security/ir.model.access.csv
```

---

## Preparació de l’estructura mínima

El mòdul ha de tindre, com a mínim, esta estructura:

- `__init__.py`
- `__manifest__.py`
- `models/`
- `security/`
- `views/`

---

## Crear els models

### Exemple de `models/patinadora.py`

```python
from odoo import models, fields


class Patinadora(models.Model):
  _name = 'patinatge.patinadora'
  _description = 'Patinadora del club'
  # Deleguem en res.partner per a dades personals (nom, telèfon, adreça...)
  _inherits = {'res.partner': 'partner_id'}
  # `name` ja està disponible per delegació; no cal redeclarar-lo

  partner_id = fields.Many2one('res.partner', ondelete='restrict', required=True)

  # Camps específics de patinatge
  nivell = fields.Selection(
    [
      ('iniciacio', 'Iniciació'),
      ('intermig', 'Intermig'),
      ('avançat', 'Avançat'),
    ],
    string="Nivell"
  )

  grup_id = fields.Many2one('patinatge.grup', string="Grup", ondelete='set null')
  participacio_ids = fields.One2many('patinatge.participacio', 'patinadora_id', string="Participacions")

  _sql_constraints = [
    ('partner_unique', 'unique(partner_id)', 'Aquest contacte ja és una patinadora!'),
  ]
```

### Exemple de `models/participacio.py`

```python
from odoo import models, fields


class Participacio(models.Model):
  _name = 'patinatge.participacio'
  _description = 'Participació de patinadora en entrenament (ternària)'

  patinadora_id = fields.Many2one('patinatge.patinadora', required=True, ondelete='restrict')
  grup_id = fields.Many2one('patinatge.grup', required=True, ondelete='restrict')
  entrenament_id = fields.Many2one('patinatge.entrenament', required=True, ondelete='restrict')

  _sql_constraints = [
    (
      'uniq_participacio_ternaria',
      'unique(patinadora_id, grup_id, entrenament_id)',
      'Esta participació ja existeix.'
    ),
  ]
```

_(Els models `grup` i `entrenament` s'implementen igual, afegint els seus camps i el `One2many` cap a `patinatge.participacio`.)_

---

## Configurar el `__manifest__.py`

```python
{
    'name': "Gestió Club Patinatge",
    'version': '16.0.1.0.0',
    'summary': "Mòdul bàsic per a gestionar patinadores i grups.",
    'description': "Exercici pràctic per a crear un mòdul senzill d’Odoo que gestiona patinadores, grups i entrenaments per al Club de Patinatge CPA Tavernes de la Valldigna.",
    'author': "El vostre nom",
    'license': 'LGPL-3',
    'category': 'Sports',

    'depends': ['base'],

    'data': [
        'security/ir.model.access.csv',
    ],

    'installable': True,
    'application': True,
}
```

---

## Crear el fitxer de permisos

`security/ir.model.access.csv`:

```
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_patinatge_patinadora,access_patinatge_patinadora,model_patinatge_patinadora,base.group_user,1,1,1,1
access_patinatge_grup,access_patinatge_grup,model_patinatge_grup,base.group_user,1,1,1,1
access_patinatge_entrenament,access_patinatge_entrenament,model_patinatge_entrenament,base.group_user,1,1,1,1
access_patinatge_participacio,access_patinatge_participacio,model_patinatge_participacio,base.group_user,1,1,1,1
```

---

## Instal·lació i vistes automàtiques

1. Reiniciar Odoo  
2. Instal·lar el mòdul  
3. Buscar el model, al menú **Tècnic > Models**. Voreu que no existeixen vistes XML definides per als models. Ara cal parar atenció a les vistes automàtiques que genera Odoo però com que no tenim ni un menú ni una acció de finestra, no podrem veure-les des de la interfície d’usuari. A la propera pràctica afegirem menús i abans de veure les vistes XML personalitzades, podrem observar les vistes automàtiques generades per Odoo. 

Consell pràctic: per no treballar “a cegues”, després d’instal·lar el mòdul aneu a **Configuració > Tècnic > Estructures de dades > Models**, busqueu `patinatge.patinadora` i feu clic a **Veure dades**. Així podreu crear un registre de prova i comprovar que el model funciona.


::::{admonition} Nota
:class: tip
Odoo genera vistes automàtiques a partir del model, però perquè es vegin cal, com a mínim, una acció de finestra; i la forma normal de llançar eixa acció és mitjançant un menú. Si no es crea un menú bàsic, no podrem visualitzar les vistes des de la interfície d’usuari. En el següent exercici aprendrem a crear vistes i menús XML personalitzats.
::::

## Repàs ràpid de relacions (el que estàs practicant)

- **Many2one**: un entrenament pertany a un grup (`grup_id` en `patinatge.entrenament`).
- **One2many**: cada entitat principal (`patinadora`, `grup`, `entrenament`) veu les seues participacions.
- **Relació ternària**: es materialitza amb `patinatge.participacio` (3 Many2one + una `unique` composta).

Este exercici cobreix el patró clàssic de relació n-ària en Odoo mitjançant model associatiu.

---

## Preparació per al següent exercici

La carpeta `views/` queda preparada per a afegir les vistes XML i els menús en el següent exercici.

Este exercici està plantejat com una primera part. El següent exercici serà incremental: partirem d'este mateix mòdul i continuarem ampliant-lo pas a pas.

---

## Nota sobre l’activitat

Este exercici no s'entrega de manera independent. S'ha dividit en dos parts per a fer-lo més senzill, evitar mesclar massa conceptes alhora i avançar de forma progressiva.

L'entrega es farà quan s'acabe el següent exercici, que continuarà sobre esta mateixa base.
