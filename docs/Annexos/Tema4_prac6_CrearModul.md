# Creació d’un mòdul bàsic en Odoo per a la colla
## Objectiu de la pràctica

Aquesta pràctica té com a objectiu crear un mòdul senzill d’Odoo utilitzant els coneixements vistos fins ara. El mòdul gestionarà la informació bàsica d’una agrupació musical, incloent músics, grups i actes. Amb aquest exercici aprendrem a:

- Crear manualment l’estructura bàsica d’un mòdul d’Odoo.
- Entendre i configurar el fitxer `__manifest__.py`.
- Crear models en Python i relacionar-los (Many2one / One2many) incloent una relació ternària amb model associatiu.- Aplicar **herència per delegació** (`_inherits`) per a reutilitzar `res.partner`, i saber quins camps cal declarar manualment perquè el partner no els té.
- Aplicar criteris d'**integritat referencial** (`ondelete`) adequats a cada relació: `restrict` per a enllaços estructurals i `cascade` per a entitats dèbils.- Generar el fitxer de permisos `ir.model.access.csv`.
- Instal·lar el mòdul i observar les vistes automàtiques que genera Odoo.
- Deixar preparat el mòdul per a afegir vistes XML en el següent exercici.

El mòdul representarà un **sistema bàsic de gestió d’una agrupació musical**.

### Situació i cas d’ús (posada en context)
La colla de dolçaines i tabals "La Morralla" de L'Olleria necessita organitzar la informació bàsica per al seu dia a dia:
- Qui són els/les músics que formen la colla (dades bàsiques).
- Quin grup toca cadascun (segons l'instrument).
- Quan es programen els actes i a quin grup van dirigits.

Amb aquest mòdul farem un primer pas per a digitalitzar la colla, i en el futur podríem afegir assistències, cobraments, despeses, clients, calendaris, comptabilitat, informes, ...

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
\node[entity] (Music) at (-4,0) {MÚSIC};
\node[entity] (Grup) at (4,0) {GRUP};
\node[entity] (Acte) at (0,-4) {ACTE};

% --- 2. ATRIBUTS (desplaçats per a connexions obliqües) ---
\node[attribute] (dni) at ($(Music.north)+(-0.85,1.05)$) {\underline{dni}};
\node[attribute] (gnom) at ($(Grup.north)+(0.85,1.05)$) {name};
\node[attribute] (edat) at ($(Acte.south)+(0.95,-1.00)$) {data};

\draw[thick] ([xshift=-0.45cm]Music.north) -- (dni.south);
\draw[thick] ([xshift=0.45cm]Grup.north) -- (gnom.south);
\draw[thick] ([xshift=0.20cm]Acte.south) -- (edat.north);

% --- 3. RELACIÓ TERNÀRIA MÚSIC - GRUP - ACTE (N:1:M) ---
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
\draw[thick] (Music.south east) -- (-1.05,-1.35) node[pos=0.72, above] {n};
\draw[thick] (Grup.south west) -- (1.05,-1.35) node[pos=0.72, above] {1};
\draw[thick] (Acte.north) -- (0,-3.05) node[pos=0.60, right] {m};

% Nom de la relació
\node[font=\scriptsize\itshape] at (1.75,-1.90) {participa};

\end{tikzpicture}

```

:::{admonition} Nota
:class: tip
El dibuix representa una **relació ternària** Músic - Grup - Acte amb cardinalitat **N:1:M** (costat Músic = N molts, costat Grup = 1 únic, costat Acte = M molts).

Interpretació pràctica: per a una combinació concreta `(músic, acte)` només hi ha **un** `grup` possible. Això sol ser coherent si per a cada acte es crea un únic grup.
:::

### Mòdul que crearem: `agrupaciomusical`
- Nom complet: Gestionar Agrupació Musical.
- Nom tècnic: `agrupaciomusical`
- Descripció: Mòdul bàsic per a gestionar una agrupació musical
- Autor: [El vostre nom]
- Categoria: Events
- Dependències: `base`
- Versió: 19.0.1.0.0
- Llicència: LGPL-3
- Instal·lable i aplicació: Sí
- Models: `agrupaciomusical.music`, `agrupaciomusical.grup`, `agrupaciomusical.acte`, `agrupaciomusical.participacio`
- Vistes: Generades automàticament per Odoo (sense vistes XML en aquest exercici)
- Permisos: Accés complet als models per a usuaris interns
- Estructura mínima preparada per a afegir vistes en el següent exercici
- Activitat dividida en dos exercicis incrementals

## Models que anem a crear

A partir de la documentació de la colla de dolçaines i tabals "La Morralla" de l'Olleria, definirem tres models bàsics perfectament assumibles amb el que sabem fins ara. Els instruments i els nivells de la colla seran implementats com **camps Selection**, ja que encara no necessitem crear models independents. Més endavant, en altres exercicis, podrem ampliar el mòdul amb més funcionalitats.

Els músics tindran:
- Un **grup d'instrument habitual**.  
- Un **nivell**.  
- Una llista de **participacions** en actes (relació ternària).

:::{admonition} Nota sobre el model associatiu
:class: tip
Per a mantindre coherència amb el diagrama, la participació no la modelarem com un `Many2many` directe, sinó amb un model associatiu (`agrupaciomusical.participacio`) amb tres claus alienes:
- `music_id`
- `grup_id` (VNN, però **fora** de la clau única)
- `acte_id`

Gràcies a la cardinalitat N:1:M (triangle blanc al costat del Grup, cardinalitat = 1), la restricció d'unicitat recau sobre la **parella** `(music_id, acte_id)`: un músic no pot aparèixer dues vegades en el mateix acte, i el grup on participa queda determinat per l'acte mateix.

El camp `grup_id` en `agrupaciomusical.music` és independent: representa el **grup habitual** del músic, mentre que `agrupaciomusical.participacio.grup_id` registra a quin grup pertany la participació efectiva en cada acte (i ha de coincidir sempre amb el `grup_id` de l'acte).
:::

Els actes són els esdeveniments on participen els músics quan ixen a tocar.

### Model `agrupaciomusical.music`

**Camps bàsics (dades personals):**

Gràcies a `_inherits`, la majoria de camps personals s'hereten automàticament del `res.partner` associat; **no cal redeclarar-los**. Només hem d'afegir manualment els camps que el partner **no té**:

| Camp | Origen | Obligatori? |
|------|--------|-------------|
| `name` | Heretat de `res.partner` | Sí (via partner) |
| `street`, `phone`, `email` | Heritats de `res.partner` | No (opcionals) |
| `cognoms` | Declarat manualment | No |
| `dni` | Declarat manualment | **Sí (VNN)** – clau natural del negoci |
| `data_naixement` | Declarat manualment | No |

:::{admonition} Per què `dni` i `data_naixement` no s'hereten?
:class: warning
`res.partner` és un model **genèric** d'Odoo dissenyat per a clients, proveïdors, empreses... i molta altra gent que no té per què tindre un DNI ni una data de naixement rellevant en el context del sistema. Per això, aquests camps simplement **no existeixen** al partner estàndard i els hem d'afegir manualment al nostre model `agrupaciomusical.music`. Res a vore amb màgia negra! 😄
:::

**Nivell (segons línies de la colla):**
- Iniciació
- Intermig
- Professional

Això ho implementarem amb un camp `Selection`.

**Relacions:**
- `grup_id` – Many2one (grup habitual)  
- `participacio_ids` – One2many (participacions de músic)  


### Model `agrupaciomusical.grup`

Cada grup es defineix per:
- `name` – Char  
- `instruments` – Char  

**Relació amb músics:**
- `musics_ids` – One2many  
  (llista de músics del grup)

**Relacions ternàries:**
- `participacio_ids` – One2many  
  (participacions del grup en actes)

### Model `agrupaciomusical.acte`

Cada acte és una eixida amb característiques pròpies:
- `name` – Char  
- `data` – Date  
- `duracio` – Integer  
- `grup_id` – Many2one  
  (el grup que participa en l'acte)

**Participants de l 'esdeveniment:**
- `participacio_ids` – One2many  
  (registre de participacions de músics en eixe acte)

### Model `agrupaciomusical.participacio` (relació ternària)

Este model és l’entitat associativa de la ternària **Músic - Grup - Acte**:

- `music_id` – Many2one (`agrupaciomusical.music`)
- `grup_id` – Many2one (`agrupaciomusical.grup`)
- `acte_id` – Many2one (`agrupaciomusical.acte`)

Per a evitar duplicitats, la restricció d'unicitat s'aplica **únicament sobre la parella** `(music_id, acte_id)`:
- `unique(music_id, acte_id)`

El `grup_id` **no entra en la clau única** perquè, d'acord amb la cardinalitat N:1:M (triangle blanc = costat Grup = 1), per a una parella concreta (músic, acte) ja hi ha implícitament **un únic grup possible**. Afegir-lo a la `unique` seria redundant i incorrecte: indicaria que el mateix músic podria anar al mateix acte amb grups distints, cosa que viola el model.

:::{admonition} Truc mnemotècnic
:class: tip
Pensa-ho així: "Pep va a l'acte del divendres... i punt. No pot anar-hi dues vegades al mateix acte. El grup on va? Eixe ja ve determinat per l'acte mateix!"
:::

A més, per a coherència del negoci, afegim una validació (`@api.constrains`) que força que el grup de la participació coincidisca amb el grup contractat per a l'acte:
- `participacio.grup_id == participacio.acte_id.grup_id`

## Crear el mòdul manualment

Com ja hem vist, és millor crear el mòdul manualment per a entendre bé quina funció té cada fitxer i cada carpeta.

Des de la carpeta `dev_addons`, crea l'estructura inicial del mòdul:

```bash
mkdir -p agrupaciomusical/{models,security,views}
touch agrupaciomusical/__init__.py
touch agrupaciomusical/__manifest__.py
touch agrupaciomusical/models/__init__.py
touch agrupaciomusical/security/ir.model.access.csv
```

## Preparació de l’estructura mínima

El mòdul ha de tindre, com a mínim, esta estructura:

- `__init__.py`
- `__manifest__.py`
- `models/`
- `security/`
- `views/`

---

## Crear els models

### Exemple de `models/music.py`

```python
from odoo import models, fields


# -- Seleccions reutilitzables -----
NIVELL_SELECTION = [
    ('educando',  'Educando'),
    ('iniciacio',  'Iniciació'),
    ('intermig',  'Intermig'),
    ('professional', 'Professional')
]


class Music(models.Model):
    _name = 'agrupaciomusical.music'
    _description = 'Músic de la colla'

    # -- Herencia per delegacio ----
    # _inherits li diu a Odoo: "Quan crees un músic, crea tambe un
    # res.partner i vincula'l per mitjà de partner_id".
    # Tots els camps del partner (name, street, phone, email...) queden
    # disponibles directament al model Music  sense haver de redeclarar-los.
    _inherits = {'res.partner': 'partner_id'}

    # Clau de delegacio.
    # ondelete='restrict': impedeix esborrar el partner si té un músic
    # associat. El partner "aguanta" mentre existisca el músic.
    partner_id = fields.Many2one(
        'res.partner',
        string="Contacte Odoo",
        required=True,
        ondelete='restrict',
    )

    # -- Camps que res.partner NO té => els declarem nosaltres (VNN) -----------
    # dni: clau natural del negoci. res.partner no l'inclou perque és un model
    # generic per a qualsevol tipus de contacte.
    dni = fields.Char(
        string="DNI",
        required=True,
    )

    # data_naixement: opcional, per saber si és major d'edat
    # Tampoc existeix al partner estandard d'Odoo.
    data_naixement = fields.Date(
        string="Data de naixement"
    )

    # cognoms: camp addicional per a facilitar l'ordenacio per cognom.
    cognoms = fields.Char(string="Cognoms")

    # -- Camps propis de la colla ----
    instrument = fields.Selection(
        MODALITAT_SELECTION,
        string="Instrument",
    )

    nivell = fields.Selection(
        NIVELL_SELECTION,
        string="Nivell",
    )

    # -- Relacions -----
    # Grup habitual (pot quedar buit si encara no té grup assignat).
    grup_id = fields.Many2one(
        'agrupaciomusical.grup',
        string="Grup habitual",
        ondelete='set null',
    )
    # Totes les participacions en actes (via model associatiu ternari).
    participacio_ids = fields.One2many(
        'agrupaciomusical.participacio',
        'music_id',
        string="Participacions",
    )

    # -- Restriccions SQL -----
    _sql_constraints = [
        ('dni_unique', 'unique(dni)',
         'Ja existeix un músic amb aquest DNI. Comprova que no el registres dos vegades!'),
        ('partner_unique', 'unique(partner_id)',
         'Aquest contacte ja és un músic. Un músic, un contacte!'),
    ]
```

### Exemple de `models/participacio.py`

```python
from odoo import models, fields, api
from odoo.exceptions import ValidationError


class Participacio(models.Model):
    _name = 'agrupaciomusical.participacio'
    _description = "Participacio d'un músic en un acte (ternaria)"

    # -- Entitat debil: ondelete='cascade' en tots els camps ---
    # Una participacio no té sentit per si sola: depèn del músic,
    # del grup i de l'acte. Si qualsevol dels tres s'esborra,
    # les participacions associades s'han d'esborrar en cascada.
    music_id = fields.Many2one(
        'agrupaciomusical.music',
        string="Músic",
        required=True,
        ondelete='cascade',
    )
    grup_id = fields.Many2one(
        'agrupaciomusical.grup',
        string="Grup",
        required=True,      # VNN: obligatori, però fora de la clau única
        ondelete='cascade',
    )
    acte_id = fields.Many2one(
        'agrupaciomusical.acte',
        string="Acte",
        required=True,
        ondelete='cascade',
    )

    # -- Restriccio d'unicitat -----
    # D'acord amb la cardinalitat N:1:M (triangle blanc = costat Grup = 1),
    # per a cada parella (músic, acte) només pot haver-hi UN grup.
    # La unicitat és sobre la PARELLA; grup_id queda fora perquè ve determinat
    # per l'acte i afegir-lo seria redundant i incorrecte.
    _sql_constraints = [
        (
            'uniq_music_acte',
            'unique(music_id, acte_id)',
            'Aquesta músic ja participa en eixe acte. '
            'Comprova que no esteu registrant-lo dues vegades!',
        ),
    ]

    # -- Integritat de negoci -----
    # El grup de la participacio ha de coincidir amb el grup convocat
    # de l'acte. Si no, tindríem a Sergi del grup Percussió acudint
    # en un acte del grup de Dolçaines... i Ramón posaria el crit al cel!
    @api.constrains('grup_id', 'acte_id')
    def _check_grup_coherent(self):
        for rec in self:
            if rec.acte_id.grup_id and rec.grup_id != rec.acte_id.grup_id:
                raise ValidationError(
                    "El grup de la participacio (%s) no coincideix amb el grup "
                    "convocat de l'acte (%s). Revisa-ho!" % (
                        rec.grup_id.name,
                        rec.acte_id.grup_id.name,
                    )
                )
```

_(Els models `grup` i `acte` s'implementen igual, afegint els seus camps i el `One2many` cap a `agrupaciomusical.participacio`.)_

## Configurar el `__manifest__.py`

```python
{
    'name': "Gestió Agrupació Musical",
    'version': '19.0.1.0.0',
    'summary': "Mòdul bàsic per a gestionar una agrupació musical.",
    'description': "Exercici pràctic per a crear un mòdul senzill d’Odoo que gestiona una agrupació musical, com són els músics, grups i actes per a la colla de Dolçaines i tablas La Morralla de l'Olleria.",
    'author': "El vostre nom",
    'license': 'LGPL-3',
    'category': 'Events',
    'depends': ['base'],
    'data': [
        'security/ir.model.access.csv',
    ],
    'installable': True,
    'application': True,
}
```

## Crear el fitxer de permisos

`security/ir.model.access.csv`:

```
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_agrupaciomusical_music,access_agrupaciomusical_music,model_agrupaciomusical_music,base.group_user,1,1,1,1
access_agrupaciomusical_grup,access_agrupaciomusical_grup,model_agrupaciomusical_grup,base.group_user,1,1,1,1
access_agrupaciomusical_acte,access_agrupaciomusical_acte,model_agrupaciomusical_acte,base.group_user,1,1,1,1
access_agrupaciomusical_participacio,access_agrupaciomusical_participacio,model_agrupaciomusical_participacio,base.group_user,1,1,1,1
```

## Instal·lació i vistes automàtiques

1. Reiniciar Odoo  
2. Instal·lar el mòdul  
3. Buscar el model, al menú **Tècnic > Models**. Voreu que no existeixen vistes XML definides per als models. Ara cal parar atenció a les vistes automàtiques que genera Odoo però com que no tenim ni un menú ni una acció de finestra, no podrem veure-les des de la interfície d’usuari. A la propera pràctica afegirem menús i abans de veure les vistes XML personalitzades, podrem observar les vistes automàtiques generades per Odoo. 

Consell pràctic: per no treballar “a cegues”, després d’instal·lar el mòdul aneu a **Configuració > Tècnic > Estructures de dades > Models**, busqueu `agrupaciomusical.music` i podreu observar els camps que s'han creat.


::::{admonition} Nota
:class: tip
Odoo genera vistes automàtiques a partir del model, però perquè es vegen cal, com a mínim, una acció de finestra; i la forma normal de llançar eixa acció és mitjançant un menú. Si no es crea un menú bàsic, no podrem visualitzar les vistes des de la interfície d’usuari. En el següent exercici aprendrem a crear vistes i menús XML personalitzats.
::::

## Repàs ràpid de relacions (el que estàs practicant)

- **Many2one**: un acte pertany a un grup (`grup_id` en `agrupaciomusical.acte`).
- **One2many**: cada entitat principal (`music`, `grup`, `acte`) veu les seues participacions.
- **Relació ternària**: es materialitza amb `agrupaciomusical.participacio` (3 Many2one + una `unique` sobre la **parella** `(music_id, acte_id)`, d'acord amb la cardinalitat N:1:M del diagrama).
- **`ondelete='restrict'`** als enllaços estructurals (delegació `partner_id`): el partner no es pot esborrar mentre hi haja un músic que l'apunte.
- **`ondelete='cascade'`** a l'entitat dèbil (`agrupaciomusical.participacio`): si s'esborra un músic, un grup o un acte, les seues participacions desapareixen automàticament.
- **`@api.constrains`** al model `Participacio` per a garantir que el grup de la participació sempre coincideix amb el grup convocat a l'acte.

Este exercici cobreix el patró clàssic de relació n-ària en Odoo mitjançant model associatiu.

## Preparació per al següent exercici

La carpeta `views/` queda preparada per a afegir les vistes XML i els menús en el següent exercici.

Este exercici està plantejat com una primera part. El següent exercici serà incremental: partirem d'este mateix mòdul i continuarem ampliant-lo pas a pas.

## Nota sobre l’activitat

Este exercici no s'entrega de manera independent. S'ha dividit en dos parts per a fer-lo més senzill, evitar mesclar massa conceptes alhora i avançar de forma progressiva.

L'entrega es farà quan s'acabe el següent exercici, que continuarà sobre esta mateixa base.
