# Vistes per als models Grup i Acte
## Objectiu de l'exercici

Este exercici és la continuació directa de l’anterior. L’objectiu d’aquesta pràctica és **completar el mòdul `agrupaciomusical`** aplicant als altres models el que ja s’ha treballat prèviament amb les vistes i els menús, concretament:

- `agrupaciomusical.grup`
- `agrupaciomusical.acte`

L’alumnat haurà de:
- Crear accions de finestra,
- Crear menús i submenús,
- Definir vistes *list* i *form* personalitzades, i comprovar que Odoo utilitza aquestes vistes en lloc de les automàtiques.

👉 No s’introdueixen conceptes nous: **només es practica i es consolida** el que ja s’ha vist.

Per això, esta activitat s’ha separat en dos exercicis: primer es crea la base del mòdul i després s’amplia de manera incremental amb les vistes i els menús.

## Models amb els quals treballarem
### Model `agrupaciomusical.grup`

El model `agrupaciomusical.grup` disposa dels següents camps principals:
- `name`
- `instruments`
- `musics_ids` (One2many)
- `participacio_ids` (One2many cap a `agrupaciomusical.participacio`) 

### Model `agrupaciomusical.acte`

El model `agrupaciomusical.acte` inclou:
- `name`
- `data`
- `duracio`
- `localitat`
- `hora_inici`
- `num_musics`
- `repetori`
- `tipus`
- `grup_id` (Many2one)
- `participacio_ids` (One2many cap a `agrupaciomusical.participacio`)

## Crear les accions i els menús

En el fitxer `views/agrupaciomusical_menus.xml`, cal afegir **dues accions de finestra noves** i **dos submenús** dins del menú principal *agrupaciomusical*.

### Acció i menú per a Grups

- Acció:
  - Model: `agrupaciomusical.grup`
  - Vistes: `list,form`
- Submenú:
  - Nom: **Grups**
  - Penjat del menú **Agrupació Musical**

```xml
<record id="action_agrupaciomusical_grups" model="ir.actions.act_window">
    <field name="name">Grups</field>
    <field name="res_model">agrupaciomusical.grup</field>
    <field name="view_mode">list,form</field>
</record>

<menuitem id="menu_agrupaciomusical_grups"
          name="Grups"
          parent="menu_agrupaciomusical_root"
          action="action_agrupaciomusical_grups"/>
```

### Acció i menú per a Actes

- Acció:
  - Model: `agrupaciomusical.acte`
  - Vistes: `list,form`
- Submenú:
  - Nom: **Actes**
  - Penjat del menú **Agrupació Musical**

```xml
<record id="action_agrupaciomusical_actes" model="ir.actions.act_window">
    <field name="name">Actes</field>
    <field name="res_model">agrupaciomusical.acte</field>
    <field name="view_mode">list,form</field>
</record>

<menuitem id="menu_agrupaciomusical_actes"
          name="Actes"
          parent="menu_agrupaciomusical_root"
          action="action_agrupaciomusical_actes"/>
```

:::{admonition} Per què no hi ha menú per a Participació?
:class: tip
El model `agrupaciomusical.participacio` és una **entitat associativa** (model de la relació ternària). No té sentit accedir-hi directament: les participacions es creen i consulten des dels formularis de Músic i Acte, a través dels camps `participacio_ids`. Per tant, **no cal crear-li cap acció ni submenú propi**.
:::

### Estat final del fitxer `agrupaciomusical_menus.xml`

Amb les dues incorporacions anteriors, el fitxer complet queda així:

```xml
<?xml version="1.0" encoding="utf-8"?>
<odoo>
    <!-- Accions de finestra -->
    <record id="action_agrupaciomusical_musics" model="ir.actions.act_window">
        <field name="name">Músics</field>
        <field name="res_model">agrupaciomusical.music</field>
        <field name="view_mode">list,form</field>
    </record>

    <record id="action_agrupaciomusical_grups" model="ir.actions.act_window">
        <field name="name">Grups</field>
        <field name="res_model">agrupaciomusical.grup</field>
        <field name="view_mode">list,form</field>
    </record>

    <record id="action_agrupaciomusical_actes" model="ir.actions.act_window">
        <field name="name">Actes</field>
        <field name="res_model">agrupaciomusical.acte</field>
        <field name="view_mode">list,form</field>
    </record>

    <!-- Menú principal -->
    <menuitem id="menu_agrupaciomusical_root"
              name="Agrupació Musical"
              sequence="10"/>

    <!-- Submenús -->
    <menuitem id="menu_agrupaciomusical_musics"
              name="Músics"
              parent="menu_agrupaciomusical_root"
              action="action_agrupaciomusical_musics"/>

    <menuitem id="menu_agrupaciomusical_grups"
              name="Grups"
              parent="menu_agrupaciomusical_root"
              action="action_agrupaciomusical_grups"/>

    <menuitem id="menu_agrupaciomusical_actes"
              name="Actes"
              parent="menu_agrupaciomusical_root"
              action="action_agrupaciomusical_actes"/>

</odoo>
```


## Crear les vistes per al model Grup

Crea un fitxer nou dins de la carpeta `views/`:

```
agrupaciomusical_grup_views.xml
```

### Vista de llistat (list) de Grups

La vista *list* ha de mostrar:
- `name`
- `instruments`

### Vista de formulari (form) de Grups

El formulari ha d’estar ben organitzat:
- camps principals,
- una pestanya amb les musics del grup (`musics_ids`).

💡 *Consell:* utilitza `<group>` i `<notebook>` com ja has fet amb Músics.


### 👥 Resultat final – model Grup

Vista de llistat (*list*) de Grups:
```{image} /_static/assets/img/T5_prac7_VistaGrupList.png
:alt: Vista Grup list
:class: img-fluid
:width: 80%
:align: center
```

Vista de formulari (*form*) de Grup, amb pestanya de músics:
```{image} /_static/assets/img/T5_prac7_VistaGrupForm.png
:alt: Vista Grup form
:class: img-fluid
:width: 80%
:align: center
```

## Crear les vistes per al model Acte

Crea un fitxer nou dins de `views/`:

```
agrupaciomusical_acte_views.xml
```

### Vista de llistat (list) d’Actes

La vista *list* ha de mostrar:
- `name`
- `data`
- `duracio`
- `localitat`
- `repertori`

### Vista de formulari (form) d’Actes

El formulari ha d’incloure:
- Dades bàsiques de l’acte,
- El grup associat,
- Una pestanya amb les participacions de l'acte (`participacio_ids`), que mostrarà els músics i el grup de cada participació.

:::{admonition} Recorda
:class: tip
No hi ha cap camp `musics_ids` al model `agrupaciomusical.acte`. La relació amb els músics es fa a través del model associatiu `agrupaciomusical.participacio`, que és el que reflecteix la relació ternària del diagrama. Usa `participacio_ids` com a `One2many` en la pestanya.
:::

### 🏋️ Resultat final – model Acte

Vista de llistat (*list*) d’Actes:
```{image} /_static/assets/img/T5_prac7_VistaActeList.png
:alt: Vista Actes
:class: img-fluid
:width: 80%
:align: center
```

Vista de formulari (*form*) d’Acte amb grup i músics:
```{image} /_static/assets/img/T5_prac7_VistaActeForm.png
:alt: Vista Acte form
:class: img-fluid
:width: 80%
:align: center
```

## Actualitzar el manifest

Com que s’han creat fitxers XML nous, cal afegir-los al `__manifest__.py`:

```python
'data': [
    'security/ir.model.access.csv',
    'views/agrupaciomusical_menus.xml',
    'views/agrupaciomusical_music_views.xml',
    'views/agrupaciomusical_grup_views.xml',
    'views/agrupaciomusical_acte_views.xml',
],
```


## Comprovacions finals

Abans de donar l’activitat per bona, comprova que:

- Apareixen els menús **Músics**, **Grups** i **Actes**.
- Cada menú obri la seua vista *list* personalitzada.
- En crear o obrir un registre es mostra la vista *form* definida.
- Odoo **no utilitza vistes automàtiques**.

Si tot això funciona, l’activitat està correcta.


## Entrega

Ara sí, en acabar este segon exercici, ja es pot fer l’entrega completa de l’activitat.

Cal entregar:

- El mòdul `agrupaciomusical` complet en format `.zip`,
- Un PDF amb:
  - Captures de pantalla de:
    - vista *list* i *form* de **Grups**,
    - vista *list* i *form* d’**Actes**,
  - Una breu explicació del treball realitzat, problemes trobats i solucions implementades.


😏 *Si açò et funciona, ja no estàs fent proves… estàs fent mòduls d’Odoo com cal.*
