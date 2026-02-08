# ✍️ Pràctica 1  · Creació d’un mòdul bàsic en Odoo per al Club de Patinatge

## 1. Objectiu de la pràctica

Aquesta pràctica té com a objectiu crear un mòdul senzill d’Odoo utilitzant els coneixements del **Tema 5**:

- Crear un mòdul amb `scaffold`.
- Entendre i configurar el fitxer `__manifest__.py`.
- Crear models en Python i relacionar-los (Many2one / One2many).
- Generar el fitxer de permisos `ir.model.access.csv`.
- Instal·lar el mòdul i observar les vistes automàtiques que genera Odoo.
- Deixar preparat el mòdul per a afegir vistes XML en el **Tema 6**.

El mòdul representarà un **sistema bàsic de gestió d’un club de patinatge**.

### 1.1 Situació i cas d’ús (posada en context)
El Club de Patinatge “CPA Tavernes de la Valldigna” necessita organitzar la informació bàsica per al seu dia a dia:
- Qui són les patinadores/ors (dades bàsiques i nivell).
- En quin grup entrena cadascun.
- Quan es programen els entrenaments i a quin grup van dirigits.

Amb aquest mòdul farem un primer pas per a informatitzar el club, i en pràctiques futures podriem afegir assistències, quotes, entrenadores, calendaris i informes etc.

### 1.2 Modul que crearem: `patinatge`
- Nom complet: Gestió Club Patinatge
- Nom tècnic: `patinatge`
- Descripció: Mòdul bàsic per a gestionar patinadores i grup
- Autor: [Nom de l’alumne]
- Categoria: Sports
- Dependències: `base`
- Versió: 16.0.1.0.0
- Llicència: LGPL-3
- Instalable i aplicació: Sí
- Models: `patinatge.patinadora`, `patinatge.grup`, `patinatge.entrenament`
- Vistes: Generades automàticament per Odoo (sense vistes XML en aquesta pràctica)
- Permisos: Accés complet als models per a usuaris interns
- Estructura mínima preparada per a afegir vistes en el Tema 6
- Entrega: `.zip` amb el mòdul i PDF amb captures i explicació
---

## 2. Models que anem a crear

A partir de la documentació del Club de Patinatge “CPA Tavernes de la Valldigna”, definirem tres models bàsics perfectament assumibles amb el que sabem del Tema 5. Les modalitats i categories del club seran implementades com **camps Selection**, ja que encara no necessitem crear models independents. Més endavant, en altres pràctiques, podrem ampliar el mòdul amb més funcionalitats.

Les patinadores tindran:
- un **grup habitual**,  
- una **modalitat**,  
- una **categoria/nivell**,  
- i una llista d’**entrenaments on participen** (Many2many).

:::{admonition} Nota
:class: tip 
Many2many és una relació que encara no hem vist en detall, però que és fàcil d’entendre:
- Una patinadora pot participar en diversos entrenaments.
- Un entrenament pot tenir diverses patinadores.            
:::

Els entrenaments són sessions puntuals on participen diverses patinadores.

---

### 2.1 Model `patinatge.patinadora`

**Camps bàsics (dades personals):**
- `name` – Char  
- `cognoms` – Char  
- `data_naixement` – Date
- `dni` – Char   
- `adreça` – Char  
- `telèfon` – Char  
- `email` – Char   

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
- `entrenaments_ids` – Many2many (entrenaments on participa)  

---

### 2.2 Model `patinatge.grup`

Cada grup es defineix per:
- `name` – Char  
- `entrenadora` – Char  
- `modalitat` – Selection  
- `categoria` – Selection  

**Relació amb patinadores:**
- `patinadores_ids` – One2many  
  (llista de patinadores assignades habitualment al grup)

---

### 2.3 Model `patinatge.entrenament`

Cada entrenament és una sessió amb característiques pròpies:
- `name` – Char  
- `data` – Date  
- `duracio` – Integer  
- `grup_id` – Many2one  
  (el grup que organitza la sessió)

**Participants de la sessió:**
- `patinadores_ids` – Many2many  
  (llista de patinadores que assisteixen)

---

## 3. Crear el mòdul amb scaffold

```
./odoo-bin scaffold patinatge /mnt/extra-addons
```

---

## 4. Preparació de l’estructura mínima

Mantindre:

- `__init__.py`
- `__manifest__.py`
- `models/`
- `security/`
- `views/`

---

## 5. Crear els models

### Exemple de `models/patinadora.py`

```python
from odoo import models, fields

class Patinadora(models.Model):
    _name = 'patinatge.patinadora'
    _description = 'Patinadora del club'

    name = fields.Char(string="Nom", required=True)
    cognoms = fields.Char(string="Cognoms")
    data_naixement = fields.Date(string="Data de naixement")
    nivell = fields.Selection(
        [('iniciacio','Iniciació'),
         ('intermig','Intermig'),
         ('avançat','Avançat')],
        string="Nivell"
    )
    grup_id = fields.Many2one('patinatge.grup', string="Grup")
    entrenaments_ids = fields.Many2many('patinatge.entrenament', string="Entrenaments")
```

_(La pràctica completa conté també els exemples per a `grup` i `entrenament`.)_

---

## 6. Configurar el `__manifest__.py`

```python
{
    'name': "Gestió Club Patinatge",
    'version': '16.0.1.0.0',
    'summary': "Mòdul bàsic per a gestionar patinadores i grups.",
    'description': "Pràctica del Tema 5.",
    'author': "Nom de l’alumne",
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

## 7. Crear el fitxer de permisos

`security/ir.model.access.csv`:

```
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_patinatge_patinadora,access_patinatge_patinadora,model_patinatge_patinadora,base.group_user,1,1,1,1
access_patinatge_grup,access_patinatge_grup,model_patinatge_grup,base.group_user,1,1,1,1
access_patinatge_entrenament,access_patinatge_entrenament,model_patinatge_entrenament,base.group_user,1,1,1,1
```

---

## 8. Instal·lació i vistes automàtiques

1. Reiniciar Odoo  
2. Instal·lar el mòdul  
3. Buscar el model, al menú **Tècnic > Models**. Voreu que no existeixen vistes XML definides per als models. Ara cal parar atenció a les vistes automàtiques que genera Odoo però com que no tenim ni un menú ni una acció de finestra, no podrem veure-les des de la interfície d’usuari. A la propera pràctica afegirem menús i abans de veure les vistes XML personalitzades, podrem observar les vistes automàtiques generades per Odoo. 


::::{admonition} Nota
:class: tip
Odoo genera vistes automàtiques a partir del model, però perquè es vegin cal, com a mínim, una acció de finestra; i la forma normal de llançar eixa acció és mitjançant un menú. Si no es crea un menú bàsic, no podrem visualitzar les vistes des de la interfície d’usuari. En el **Tema 6** aprendrem a crear vistes i menús XML personalitzats.
::::

---

## 9. Preparació per al Tema 6

La carpeta `views/` queda preparada per a afegir les vistes XML i menús.

---

## 10. Entrega

- `.zip` amb el mòdul  
- PDF breu amb captures i explicació  
