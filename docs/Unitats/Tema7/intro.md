
## Introducció
En este tema deixem de “jugar” i comencem a controlar qui pot fer què dins d’Odoo.  
Si no controles els permisos… acabes amb el músic esborrant dades i la directiva amb cara de 🤨.

Continuem treballant el tema amb **la colla de dolçaines i tabals**, perquè s’entenga de veritat.

::: {admonition} Objectiu pràctic
:class: tip
Al final del tema sabràs:
- Crear grups d’usuaris (rols).
- Donar permisos reals sobre models amb `ir.model.access.csv`.
- Diferenciar permisos (server) de visibilitat (vistes).
- Aplicar record rules per limitar “quins” registres veu cada grup.
:::

## Usuaris, grups i permisos (idea clau)
En Odoo:
- Un **usuari** pot pertànyer a **un o més grups**
- Els **permisos** s’assignen als **grups**
- Els permisos s’apliquen **als models**

Permisos bàsics:
- read (llegir)
- write (editar)
- create (crear)
- unlink (esborrar)

Si un usuari **no té permís al model**, el sistema el frena encara que “veja” botons.

:::{caution} 

El que “es veu” és frontend. El que “es pot fer” és seguretat de servidor.  
La seguretat real sempre va en CSV i record rules, no en les vistes.
:::

## Estructura de seguretat d’un mòdul

```text
agrupaciomusical/
├── models/
├── views/
├── security/
│   ├── security.xml
│   └── ir.model.access.csv
└── __manifest__.py
```

L’ordre importa:
1. Primer **grups**
2. Després **permisos**

::: {admonition} Checklist ràpid
:class: note
- Hi ha grups definits en `security.xml`?  
- El model apareix en `ir.model.access.csv`?  
- El manifest carrega `security.xml` i el CSV?  
:::

## Creació de grups (`security/security.xml`)
El fitxer `security.xml` defineix els grups d’usuaris. Aquest fitxer és opcional, però molt recomanat: és la base per organitzar rols (directiva, responsable, music…) i després assignar-los permisos sobre els models.

En les versions actuals d'Odoo, la jerarquia d'accés s'estructura en tres nivells connectats: Categories, Privilegis i Grups.

**Categoria** (`ir.module.category`):

La categoria és el contenidor de nivell més alt. Serveix per a agrupar visualment tots els permisos relacionats amb el nostre mòdul dins de la configuració d'Odoo, separant-los de les aplicacions estàndard (com Vendes o Facturació).
```xml
<record 
  id="module_category_agrupaciomusical" 
  model="ir.module.category">
    <field name="name">Agrupació Musical</field>
    <field name="description">Gestió de rols i permisos per a la colla de dolçaines i tabals.</field>
    <field name="sequence">10</field>
</record>
```

- `id`: L'identificador XML únic per a fer referència a aquesta categoria més endavant.
- `name`: El títol que veurà l'usuari a la interfície gràfica.
- `sequence`: L'ordre numèric en què apareixerà aquesta secció en la pantalla de configuració (com més baix és el número, més amunt es mostra).

**El Privilegi** (`res.groups.privilege`):

En l'arquitectura d'Odoo, els grups no s'enllacen directament a la categoria global, sinó que es vinculen a un **Privilegi**. Aquest model actua com un pont o connector que permet orquestrar de manera precisa com interactuaran els rols de seguretat sota la mateixa categoria d'aplicació.
```xml
<record 
  id="res_groups_privilege_agrupacionmusical" 
  model="res.groups.privilege">
    <field name="name">Agrupació Musical</field>
    <field name="category_id" ref="module_category_agrupaciomusical"/>
    <field name="sequence">70</field>
</record>
```
- `category_id`: Enllaça aquest privilegi amb la seua categoria pare creada al bloc anterior mitjançant l'atribut `ref=""`.

**Els Grups d'Usuaris** (`res.groups`):

Els grups són els rols funcionals reals. Cada grup té assignats uns usuaris i hereta uns determinats permisos del sistema.

Per a la colla definirem 3 grups d'usuari: *Músic*, *Responsable* i *Directiu*. El rol de Músic està pensat per a la gent de la colla que només consultarà esdeveniments o dades des del Portal de la web (usuaris externs), mentre que Responsable i Directiu són rols d'administració per a la gent que realment gestionarà l'associació des de dins d'Odoo (usuaris interns).

Vegem com es defineixen utilitzant com a exemple el grup més restrictiu i el més avançat:

A) El Rol de Músic (Usuari del Portal)

```xml
<record id="group_musics" model="res.groups">
    <field name="name">Músic de la colla</field>
    <field name="privilege_id" 
           ref="res_groups_privilege_agrupacionmusical"/>
    <field name="implied_ids" 
           eval="[(4, ref('base.group_portal'))]"/>
</record>
```

- `privilege_id`: Associa el grup al connector de privilegis que hem definit anteriorment.
- `implied_ids`: Defineix l'herència de permisos (permisos implícits). La sintaxi `[(4, ref('base.group_portal'))]` significa que qualsevol usuari que siga "Músic" heretarà automàticament els permisos de la categoria "Usuari extern" (`base.group_portal`) d'Odoo, estalviant-nos haver de reconfigurar des de zero els permisos bàsics de connexió al sistema.

B) El Rol de Responsable (Usuari Base)
```xml
<record id="group_responsable" model="res.groups">
    <field name="name">Responsable d'actes</field>
    <field name="privilege_id" 
           ref="res_groups_privilege_agrupacionmusical"/>
    <field name="implied_ids" 
           eval="[(4, ref('base.group_user'))]"/>
</record>
```

- `privilege_id`: Associa el grup al connector de privilegis que hem definit anteriorment.
- `implied_ids`: Defineix l'herència de permisos (permisos implícits). La sintaxi `[(4, ref('base.group_user'))]` significa que qualsevol usuari que siga "Responsable" heretarà automàticament els permisos de la categoria "Usuari intern" (`base.group_user`) d'Odoo, estalviant-nos haver de reconfigurar des de zero els permisos bàsics de connexió al sistema.

C) El Rol de Directiu (Administrador del Mòdul)
```xml
<record id="group_directiu" model="res.groups">
    <field name="name">Directiu</field>
    <field name="privilege_id" 
           ref="res_groups_privilege_agrupacionmusical"/>
    <field name="implied_ids" 
           eval="[(4, ref('base.group_user'))]"/>
    <field name="user_ids" 
           eval="[(4, ref('base.user_root')), 
                  (4, ref('base.user_admin'))
            ]"/>
</record>
```
- `user_ids`: Permet preassignar usuaris de manera automàtica en instal·lar el mòdul. Utilitzant el mètode `(4, ID)`, estem indicant a Odoo que afija l'usuari superadministrador del sistema (`base.user_root`) i l'usuari administrador per defecte (`base.user_admin`) directament dins del grup Directiu, assegurant-nos que l'administrador del sistema puga testejat i tindre control total des del primer segon.


Codi complet per al fitxer `security.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<odoo>
    <!--Definició de la categoria-->
    <record id="module_category_agrupaciomusical" model="ir.module.category">
        <field name="name">Agrupació Musical</field>
        <field name="description">Gestió de rols i permisos per a la colla de dolçaines i tabals.</field>
        <field name="sequence">10</field>
    </record>
    <!--Definició del privilegi-->
    <record id="res_groups_privilege_agrupacionmusical" model="res.groups.privilege">
        <field name="name">Agrupació Musical</field>
        <field name="category_id" ref="module_category_agrupaciomusical"/>
        <field name="sequence">70</field>
    </record>
    <!--El Rol de Músic (Usuari Base)-->
    <record id="group_musics" model="res.groups">
        <field name="name">Músic de la colla</field>
        <field name="privilege_id" ref="res_groups_privilege_agrupacionmusical"/>
        <field name="implied_ids" eval="[(4, ref('base.group_portal'))]"/>
    </record>
    <!--El Rol de Responsable (Usuari Base que gestiona les actuacions)-->
    <record id="group_responsable" model="res.groups">
        <field name="name">Responsable d'actes</field>
        <field name="privilege_id" ref="res_groups_privilege_agrupacionmusical"/>
        <field name="implied_ids" eval="[(4, ref('base.group_user'))]"/>
    </record>
    <!--El Rol de Directiu (Administrador del Mòdul)-->
    <record id="group_directiu" model="res.groups">
        <field name="name">Directiu</field>
        <field name="privilege_id" ref="res_groups_privilege_agrupacionmusical"/>
        <field name="implied_ids" eval="[(4, ref('base.group_user'))]"/>
        <field name="user_ids" eval="[(4, ref('base.user_root')), (4, ref('base.user_admin'))]"/>
    </record>
  </odoo>
```
::: {danger} 
**Errors comuns**

- Crear grups però no incloure `security.xml` al manifest.  
- Pensar que “categoria” dona permisos. No, només ordena.
- No actualitzar les dependències a `web` i `website` en el manifest.
:::

## Permisos de model (`ir.model.access.csv`)
El fitxer `ir.model.access.csv` és obligatori si el mòdul crea models. Si un model no apareix ací, per a l’usuari “no existix”.

Format obligatori:
```xml
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
```

Què significa cada columna:
- `id`: identificador de la regla
- `name`: nom descriptiu
- `model_id:id`: referència al model (ex: `module.model_name`)
- `group_id:id`: grup al qual s’aplica
- `perm_read/write/create/unlink`: 1 sí, 0 no

Exemple real:
```xml
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_directiva_participacio,accés de directiva a participació,model_agrupaciomusical_participacio,agrupaciomusical.group_directiu,1,1,1,1
access_responsable_participacio,accés de responsable a participació",model_agrupaciomusical_participacio,agrupaciomusical.group_responsable,1,1,0,0
access_music_participacio,accés de músic a participació",model_agrupaciomusical_participacio,agrupaciomusical.group_musics,1,1,0,0
```

:::{admonition} 🧠 Traducció clara (i realista)
:class: tip
👑 Administrador → ho veu i ho fa tot (no precisa CSV).  
👩‍💼 Directiva → crear, veure, editar i esborrar del model `participacio`.  
👩‍🏫 Responsable → veure i editar (sense crear ni esborrar).  
🛼 Músic → editar i veure la seua participació (sense crear ni esborrar).  
:::

Traducció ràpida:
- La **directiva** ho pot fer tot.
- El **responsable** pot veure i editar (els actes dels que és responsable).
- El **músic** només pot veure (i editar la seua).

::: {caution} 

El CSV diu “què es pot fer” sobre el model.  
Les record rules diuen “sobre quins registres” exactament. Sense record rules, un grup amb lectura veu tots els registres del model.
:::

## Permisos ≠ visibilitat
Regla d’or:

> El CSV controla la **seguretat real**  
> Les vistes només controlen el que **es veu**

Amagar un botó **NO** és seguretat. La seguretat sempre ha d’estar al servidor.

::: {admonition} Idea clau
:class: tip
Si no tens permís, Odoo et para encara que el botó existisca.  
Si només amagues el botó, un usuari amb API o accés indirecte pot fer l’acció igual.
:::

## Aplicar grups en vistes i menús
Exemple en una vista:
```xml
<button name="action_esborrar"
        string="Esborrar"
        type="object"
        groups="agrupaciomusical.group_directiu"/>
```

Exemple en un menú:
```xml
<menuitem id="menu_agrupaciomusical_actes"
          name="Actes"
          groups="agrupaciomusical.group_responsable,agrupaciomusical.group_directiu"
          action="action_agrupaciomusical_actes"/>
```

::: {admonition} Ús correcte
:class: note
- Les vistes “filtren visibilitat”, no permissions.  
- Combina “groups” en vistes amb el CSV per tindre seguretat real.
:::

## Regles de registre (record rules)
Les **record rules** controlen **quins registres** veu un usuari dins d’un model. Es defineixen en `ir.rule` i es relacionen amb grups.

Exemple:
- Un músic només veu **els actes en els que participa**.
- Un responsable veu **els actes dels que és el responsable**.

Les regles:
- globals → apliquen sempre (resten).
- de grup → s’acumulen segons el grup.

Definició en `security/security.xml`:
```xml
<record id="rule_music_veure_seus_actes" model="ir.rule">
  <field name="name">Músic: veure els seus actes</field>
  <field name="model_id" 
         ref="model_agrupaciomusical_participacio"/>
  <field name="domain_force">
    [('music_id.partner_id.id', '=', user.partner_id.id)]
  </field>
</record>
```
Ací filtrem perquè el músic només veja les seues participacions als actes on el partner del músic `music_id.partner_id` coincideix amb el partner del seu usuari (`user.partner_id.id`).

::: {admonition} Idea clau
:class: tip
- CSV: “què es pot fer” (read, write, create, unlink).  
- Record rules: “sobre quins registres” exactes (dominis).  
:::

## Resum final

✔️ Els permisos es defineixen **per grups**  
✔️ El CSV és obligatori  
✔️ Les vistes no són seguretat  
✔️ Sense permisos, Odoo et para

O dit més clar:
> En Odoo no mana qui eres,  
> **mana el grup on estàs**.

I qui no controla els permisos… després plora 😄

::: {admonition} Checklist de tancament
:class: tip
- Grups creats i visibles al backend.  
- CSV amb el model i permisos per cada grup.  
- Vistes amb `groups` per a visibilitat.  
- Record rules aplicades si cal limitar registres.  
:::

::: {admonition} Errors que evitem
:class: warning
- Deixar models sense línies en el CSV.  
- Confiar la seguretat només a les vistes.  
- No carregar `security.xml` al manifest.  
:::


## Resum i pròxims passos
En aquest capítol hem après a crear grups d’usuaris, assignar permisos reals sobre models amb `ir.model.access.csv`, diferenciar entre permisos de servidor i visibilitat en les vistes, i aplicar record rules per limitar quins registres veu cada grup. Si no ho has fet encara, convidria realitzar l'Exercici pràctic: [Permisos i rols en Odoo per a la colla](../../Annexos/Tema7_prac10_permisosrols.md), on aplicarem aquests conceptes per a configurar els permisos dels diferents rols de la colla de dolçaines i tabals. 