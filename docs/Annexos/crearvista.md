# Exercici pràctic: Vistes per als models Grup i Entrenament

## 1. Objectiu de l'exercici

Este exercici és la continuació directa de l’anterior. L’objectiu d’aquesta pràctica és **completar el mòdul `patinatge`** aplicant als altres models el que ja s’ha treballat prèviament amb les vistes i els menús, concretament:

- `patinatge.grup`
- `patinatge.entrenament`

L’alumnat haurà de:
- Crear accions de finestra,
- Crear menús i submenús,
- Definir vistes *tree* i *form* personalitzades, i comprovar que Odoo utilitza aquestes vistes en lloc de les automàtiques.

👉 No s’introdueixen conceptes nous: **només es practica i es consolida** el que ja s’ha vist.

Per això, esta activitat s’ha separat en dos exercicis: primer es crea la base del mòdul i després s’amplia de manera incremental amb les vistes i els menús.

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
- `participacio_ids` (One2many cap a `patinatge.participacio`)

---

## 3. Crear les accions i els menús

En el fitxer `views/patinatge_menus.xml`, cal afegir **dues accions de finestra noves** i **dos submenús** dins del menú principal *Patinatge*.

### 3.1 Acció i menú per a Grups

- Acció:
  - Model: `patinatge.grup`
  - Vistes: `tree,form`
- Submenú:
  - Nom: **Grups**
  - Penjat del menú **Patinatge**

```xml
<record id="action_patinatge_grups" model="ir.actions.act_window">
    <field name="name">Grups</field>
    <field name="res_model">patinatge.grup</field>
    <field name="view_mode">tree,form</field>
</record>

<menuitem id="menu_patinatge_grups"
          name="Grups"
          parent="menu_patinatge_root"
          action="action_patinatge_grups"/>
```

---

### 3.2 Acció i menú per a Entrenaments

- Acció:
  - Model: `patinatge.entrenament`
  - Vistes: `tree,form`
- Submenú:
  - Nom: **Entrenaments**
  - Penjat del menú **Patinatge**

```xml
<record id="action_patinatge_entrenaments" model="ir.actions.act_window">
    <field name="name">Entrenaments</field>
    <field name="res_model">patinatge.entrenament</field>
    <field name="view_mode">tree,form</field>
</record>

<menuitem id="menu_patinatge_entrenaments"
          name="Entrenaments"
          parent="menu_patinatge_root"
          action="action_patinatge_entrenaments"/>
```

:::{admonition} Per què no hi ha menú per a Participació?
:class: tip
El model `patinatge.participacio` és una **entitat associativa** (model de la relació ternària). No té sentit accedir-hi directament: les participacions es creen i consulten des dels formularis de Patinadora i Entrenament, a través dels camps `participacio_ids`. Per tant, **no cal crear-li cap acció ni submenú propi**.
:::

### 3.3 Estat final del fitxer `patinatge_menus.xml`

Amb les dues incorporacions anteriors, el fitxer complet queda així:

```xml
<?xml version="1.0" encoding="utf-8"?>
<odoo>

    <!-- Accions de finestra -->
    <record id="action_patinatge_patinadores" model="ir.actions.act_window">
        <field name="name">Patinadores</field>
        <field name="res_model">patinatge.patinadora</field>
        <field name="view_mode">tree,form</field>
    </record>

    <record id="action_patinatge_grups" model="ir.actions.act_window">
        <field name="name">Grups</field>
        <field name="res_model">patinatge.grup</field>
        <field name="view_mode">tree,form</field>
    </record>

    <record id="action_patinatge_entrenaments" model="ir.actions.act_window">
        <field name="name">Entrenaments</field>
        <field name="res_model">patinatge.entrenament</field>
        <field name="view_mode">tree,form</field>
    </record>

    <!-- Menú principal -->
    <menuitem id="menu_patinatge_root"
              name="Patinatge"
              sequence="10"/>

    <!-- Submenús -->
    <menuitem id="menu_patinatge_patinadores"
              name="Patinadores"
              parent="menu_patinatge_root"
              action="action_patinatge_patinadores"/>

    <menuitem id="menu_patinatge_grups"
              name="Grups"
              parent="menu_patinatge_root"
              action="action_patinatge_grups"/>

    <menuitem id="menu_patinatge_entrenaments"
              name="Entrenaments"
              parent="menu_patinatge_root"
              action="action_patinatge_entrenaments"/>

</odoo>
```


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
- Una pestanya amb les participacions de la sessió (`participacio_ids`), que mostrarà la patinadora i el grup de cada participació.

:::{admonition} Recorda
:class: tip
No hi ha cap camp `patinadores_ids` al model `patinatge.entrenament`. La relació amb les patinadores es fa a través del model associatiu `patinatge.participacio`, que és el que reflecteix la relació ternària del diagrama. Usa `participacio_ids` com a `One2many` en la pestanya.
:::

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

Abans de donar l’activitat per bona, comprova que:

- Apareixen els menús **Patinadores**, **Grups** i **Entrenaments**.
- Cada menú obri la seua vista *tree* personalitzada.
- En crear o obrir un registre es mostra la vista *form* definida.
- Odoo **no utilitza vistes automàtiques**.

Si tot això funciona, l’activitat està correcta.

---

## 8. Verificació i repte final

Ara sí, en acabar aquest segon exercici, ja pots verificar el funcionament complet del mòdul.

Assegura't de:
- Comprovar la vista *tree* i *form* de **Grups**, comprovant que les relacions i dades es visualitzen correctament.
- Comprovar la vista *tree* i *form* d'**Entrenaments** i els seus camps.
- Reflexionar sobre el treball realitzat, els problemes trobats i les solucions implementades durant el desenvolupament de la pràctica.

---

😏 *Si açò et funciona, ja no estàs fent proves… estàs fent mòduls d’Odoo com cal.*
