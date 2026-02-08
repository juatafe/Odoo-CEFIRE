# Annex L Exercici pràctic 7: Vistes per als models Grup i Entrenament

## 1. Objectiu de l'exercici

L’objectiu d’aquesta pràctica és **aplicar els coneixements del capitol 5** a la resta de models del mòdul `patinatge`, concretament:

- `patinatge.grup`
- `patinatge.entrenament`

L’alumnat haurà de:
- Crear accions de finestra,
- Crear menús i submenús,
- Definir vistes *tree* i *form* personalitzades, i comprovar que Odoo utilitza aquestes vistes en lloc de les automàtiques.

👉 No s’introdueixen conceptes nous: **només es practica i es consolida** el que ja s’ha vist.

---

## 2. Models amb els quals treballarem

### 2.1 Model `patinatge.grup`

El model `patinatge.grup` disposa dels següents camps principals:
- `name`
- `entrenadora`
- `modalitat`
- `categoria`
- `patinadores_ids` (One2many)

---

### 2.2 Model `patinatge.entrenament`

El model `patinatge.entrenament` inclou:
- `name`
- `data`
- `duracio`
- `grup_id` (Many2one)
- `patinadores_ids` (Many2many)

---

## 3. Crear les accions i menús

En el fitxer `views/patinatge_menus.xml`, cal afegir **dues accions de finestra noves** i **dos submenús** dins del menú principal *Patinatge*.

### 3.1 Acció i menú per a Grups

- Acció:
  - Model: `patinatge.grup`
  - Vistes: `tree,form`
- Submenú:
  - Nom: **Grups**
  - Penjat del menú **Patinatge**

---

### 3.2 Acció i menú per a Entrenaments

- Acció:
  - Model: `patinatge.entrenament`
  - Vistes: `tree,form`
- Submenú:
  - Nom: **Entrenaments**
  - Penjat del menú **Patinatge**

💡 *Pista:* el codi és molt semblant al de Patinadores; només canvien els noms i el `res_model`.


## 4. Crear les vistes per al model Grup

Crea un fitxer nou dins de la carpeta `views/`:

```
patinatge_grup_views.xml
```

### 4.1 Vista de llistat (tree) de Grups

La vista *tree* ha de mostrar com a mínim:
- `name`
- `modalitat`
- `categoria`
- `entrenadora`

---

### 4.2 Vista de formulari (form) de Grups

El formulari ha d’estar ben organitzat:
- camps principals en dues columnes,
- una pestanya amb les patinadores del grup (`patinadores_ids`).

💡 *Consell:* utilitza `<group>` i `<notebook>` com ja has fet amb Patinadores.


### 👥 Resultat final – model Grup

Vista de llistat (*tree*) de Grups:
```{image} /_static/assets/img/Tema6/vista-grups.png
:alt: Vista Grups
:class: img-fluid
:width: 80%
:align: center
```

Vista de formulari (*form*) de Grup, amb pestanya de patinadores:
```{image} /_static/assets/img/Tema6/vista-grup-form.png
:alt: Vista Grup form
:class: img-fluid
:width: 80%
:align: center
```

---

## 5. Crear les vistes per al model Entrenament

Crea un fitxer nou dins de `views/`:

```
patinatge_entrenament_views.xml
```

### 5.1 Vista de llistat (tree) d’Entrenaments

La vista *tree* ha de mostrar:
- `name`
- `data`
- `duracio`
- `grup_id`

---

### 5.2 Vista de formulari (form) d’Entrenaments

El formulari ha d’incloure:
- Dades bàsiques de l’entrenament,
- El grup associat,
- Una pestanya amb les patinadores participants (`patinadores_ids`).

### 🏋️ Resultat final – model Entrenament

Vista de llistat (*tree*) d’Entrenaments:
```{image} /_static/assets/img/Tema6/vista-entrenaments.png
:alt: Vista Entrenaments
:class: img-fluid
:width: 80%
:align: center
```

Vista de formulari (*form*) d’Entrenament amb grup i patinadores:
```{image} /_static/assets/img/Tema6/vista-entrenaments-form.png
:alt: Vista Entrenament form
:class: img-fluid
:width: 80%
:align: center
```

---

## 6. Actualitzar el manifest

Com que s’han creat fitxers XML nous, cal afegir-los al `__manifest__.py`:

```python
'data': [
    'security/ir.model.access.csv',
    'views/patinatge_menus.xml',
    'views/patinatge_patinadora_views.xml',
    'views/patinatge_grup_views.xml',
    'views/patinatge_entrenament_views.xml',
],
```

---

## 7. Comprovacions finals

Abans de donar la pràctica per bona, comprova que:

- apareixen els menús **Patinadores**, **Grups** i **Entrenaments**,
- cada menú obri la seua vista *tree* personalitzada,
- en crear o obrir un registre es mostra la vista *form* definida,
- Odoo **no utilitza vistes automàtiques**.

Si tot això funciona, la pràctica està correcta.

---

## 8. Entrega

Cal entregar:

- El mòdul `patinatge` complet en format `.zip`,
- Un pdf amb:
  - Captures de pantalla de:
    - vista *tree* i *form* de **Grups**,
    - vista *tree* i *form* d’**Entrenaments**,
  - Una breu explicació del treball realitzat.

---

😏 *Si açò et funciona, ja no estàs fent proves… estàs fent mòduls d’Odoo com toca.*
