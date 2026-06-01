# Exercici pràctic: Permisos i rols en Odoo (club de patinatge)

## Context de la pràctica
El club de patinatge ja utilitza Odoo per gestionar inscripcions, grups i patinadores.  
Ara la directiva s’ha cansat del “tothom ho veu tot” i vol posar ordre:

- La directiva mana (com sempre 😅).
- Les entrenadores gestionen, però amb límits.
- Les patinadores només poden vore i crear el que és seu.

::: {admonition} Avís important sobre els menús
:class: warning
En Odoo, un menú **no apareix** si l’usuari no pertany a cap dels grups que el poden veure.

Encara que:
- El menú estiga ben definit
- L’acció existisca
- El model tinga permisos

👉 Si l’usuari no té el grup correcte, **el menú desapareix sense donar cap error**.

Aquesta pràctica està pensada perquè detectes i entengues aquest comportament.
:::

### Requisits previs
👉 En esta pràctica NO crearem vistes noves, només seguretat real (grups, ACL i record rules). No crearem vistes noves, però **necessitem que el model `patinatge.inscripcio` tinga almenys una vista list i una form** per poder provar els permisos. Si el teu mòdul `patinatge_inscripcio` no les té definides, usa la vista següent a `views/patinatge_inscripcio_views.xml` 

:::{admonition} Codi complet de la vista `patinatge_inscripcio_views.xml`
:class-container: tip

```xml

<?xml version="1.0" encoding="utf-8"?>
<odoo>

    <record id="view_patinatge_inscripcio_list" model="ir.ui.view">
        <field name="name">patinatge.inscripcio.list</field>
        <field name="model">patinatge.inscripcio</field>
        <field name="arch" type="xml">
            <list create="false" edit="true">
                <field name="reference" string="Ref"/>
                <field name="nom_patinadora" string="Nom patinadora"/>
                <field name="data_naixement" string="Data naixement"/>
                <field name="categoria"
                    decoration-info="categoria == 'iniciacio'"
                    decoration-primary="categoria == 'federades'"/>

                <field name="nom_tutor" string="Pare/Mare"/>
                <field name="dni_tutor" string="DNI tutor"/>
                <field name="telefon_tutor"/>
                <field name="email_tutor"/>

                <field name="estat"
                    decoration-success="estat == 'acceptada'"
                    decoration-danger="estat == 'rebutjada'"
                    decoration-warning="estat == 'pendent_signatura'"/>
            </list>
        </field>
    </record>

    <record id="view_patinatge_inscripcio_form" model="ir.ui.view">
        <field name="name">patinatge.inscripcio.form</field>
        <field name="model">patinatge.inscripcio</field>
        <field name="arch" type="xml">
            <form string="Inscripció al club">
                <header>
                    <button name="action_acceptar"
                            string="Acceptar"
                            type="object"
                            class="oe_highlight"
                            attrs="{'invisible': [('estat', '!=', 'signada')]}"/>

                    <button name="action_rebutjar"
                            string="Rebutjar"
                            type="object"
                            attrs="{'invisible': [('estat', '!=', 'signada')]}"/>
                    
                    <field name="estat" widget="statusbar"/>
                </header>
                <sheet>
                    <group>
                        <group string="Dades de la patinadora">
                            <field name="nom_patinadora"/>
                            <field name="data_naixement"/>
                            <field name="categoria"/>
                        </group>

                        <group string="Tutor legal">
                            <field name="nom_tutor"/>
                            <field name="dni_tutor"/>
                            <field name="email_tutor"/>
                            <field name="telefon_tutor"/>
                        </group>
                    </group>

                    <group string="Estat i documents">
                        <field name="estat" readonly="1"/>
                        <field name="pdf_original" filename="reference"/>
                        <field name="pdf_signat" filename="reference"/>
                    </group>
                </sheet>
            </form>
        </field>
    </record>

    <record id="action_patinatge_inscripcio" model="ir.actions.act_window">
        <field name="name">Inscripcions</field>
        <field name="res_model">patinatge.inscripcio</field>
        <field name="view_mode">list,form</field>
    </record>

    <menuitem id="menu_patinatge_inscripcio_root"
            name="Inscripcions"
            sequence="10"/>

    <menuitem id="menu_patinatge_inscripcio"
              name="Gestió d’inscripcions"
              parent="menu_patinatge_inscripcio_root"
              action="action_patinatge_inscripcio"
              sequence="10"/>
</odoo>

```
:::

::: {admonition} Objectius de la pràctica
:class: tip
En acabar la pràctica sabràs:
- Crear grups reals d’usuaris.
- Assignar permisos amb `ir.model.access.csv`.
- Comprovar què passa quan falten permisos.
- Aplicar record rules i vore la diferència abans/després.
- Entendre per què amagar botons no és seguretat.
:::

---

## 1) Preparació de l’entorn
Abans de començar la pràctica, cal tindre clar com està organitzat el projecte.
En aquesta pràctica no treballem amb un únic mòdul, sinó amb dos mòduls relacionats:

📦 Mòduls del projecte
- patinatge
  - Mòdul base del projecte. Conté:
      - Models generals (patinadores, grups, entrenaments…)
      - Vistes de backend
      - Estructura principal del club

- patinatge_inscripcio
  - Mòdul específic per gestionar:
      - El model patinatge.inscripcio
      - Les inscripcions al club
      - La lògica associada a l’alta de patinadores

👉 Tot i ser mòduls diferents, treballen junts i comparteixen dades.
Requisits:
- Mòdul “patinatge” instal·lat.
- Model `patinatge.inscripcio` operatiu.
- Almenys 3 usuaris de prova:
  - `directiva_test`
  - `entrenadora_test`
  - `patinadora_test`

👉 Si no existeixen, crea’ls des del backend: Configuració → Usuaris.

 
En cas de dubte, comprova que els usuaris tenen els grups assignats correctament des del backend. En configuració → Usuaris i Empreses → Usuaris → selecciona l’usuari i comprova els grups.
:::{image} /_static/assets/img/Tema8/administrador-club.png
:alt: Administrador del club
:width: 100%
:::

### 🔎 Verificar usuaris de prova amb SQL (Docker)
::: {admonition} Dins del contenidor
:class: note
Executa psql al servei de base de dades del docker-compose:
```bash
docker compose exec db psql -U odoo -d morrallaodoo
```

Ja dins de psql, comprova els usuaris de prova:
```sql
SELECT u.login, p.name
FROM res_users u
JOIN res_partner p ON p.id = u.partner_id
WHERE u.login LIKE '%_test';

```

Resultat esperat:
```text
 login            | name
------------------+-------------------
 directiva_test   | Directiva Test
 entrenadora_test | Entrenadora Test
 patinadora_test  | Patinadora Test
```

👉 Si apareixen → tot correcte  
👉 Si no → el hook no s’ha executat (reinstal·la el mòdul amb -i o crea’ls des del backend).
:::

::: {admonition} Assignar contrasenyes als usuaris
:class: note
Hi ha **dos formes** de posar la contrasenya a un usuari per codi:

✔️ **Forma pràctica (recomanada per a proves i classe)**
Afegir directament el camp `password` en crear l’usuari:

```python
env['res.users'].create({
    'login': 'directiva_test',
    'name': 'Directiva Test',
    'password': 'odoo123',
})
```
Odoo s’encarrega d’encriptar-la, no es guarda en clar.

⚠️ Forma “oficial” d’Odoo (no recomanada per a classe)
Crear l’usuari i usar action_reset_password():
```python
user = env['res.users'].create({
    'login': 'directiva_test',
    'name': 'Directiva Test',
})
user.action_reset_password()
```

Açò envia un correu i necessita el sistema de mail configurat.

👉 Per a classe i pràctiques: usa la primera.
:::

<!-- ::: {admonition} Actualitzar el mòdul (Linux)
:class: note
Des del terminal de VS Code:
- Situa’t en el directori del projecte i executa:

```bash
./odoo-bin -u patinatge -d <nom_bd>
```

Substitueix `<nom_bd>` pel nom de la teua base de dades.
::: -->

---

## 2) Crear els grups de seguretat

Objectiu:
- Definir els rols: Directiva, Entrenadora, Patinadora.

Tasca:
- Crea (o revisa) el fitxer `security/security.xml` i afig els grups del club de patinatge (els mateixos del tema teòric). En el mòdul `patinatge_inscripcio` no en `patinatge`.


```xml
<odoo>
  <data noupdate="0">
    <record id="module_category_patinatge" model="ir.module.category">
      <field name="name">Club de Patinatge</field>
      <field name="description">Gestió de rols del club</field>
      <field name="sequence">10</field>
    </record>

    <record id="group_patinatge_directiva" model="res.groups">
      <field name="name">Directiva</field>
      <field name="category_id" ref="module_category_patinatge"/>
      <field name="users" eval="[(4, ref('base.user_root')), (4, ref('base.user_admin'))]"/>
    </record>

    <record id="group_patinatge_entrenadora" model="res.groups">
      <field name="name">Entrenadora</field>
      <field name="category_id" ref="module_category_patinatge"/>
    </record>

    <record id="group_patinatge_patinadora" model="res.groups">
      <field name="name">Patinadora</field>
      <field name="category_id" ref="module_category_patinatge"/>
    </record>

    </data>
</odoo>
```

::: {admonition} Ordre de càrrega en `__manifest__.py` (important)
:class: warning
En la clau `data` del manifest:
1) Primer `security/security.xml` (crea grups)  
2) Després `security/ir.model.access.csv` (aplica permisos als grups)

Si carregues el CSV abans, referenciaràs grups que encara no existixen.
👉 A partir d’aquest moment:
- Els grups **existeixen**
- Però **no fan res encara**
- Sense ACL i record rules, un grup és només una etiqueta
:::

Verificació:
- Els grups apareixen al backend. En Configuració → Usuaris i Empreses → Grups.
- Es poden assignar als usuaris:
  - `directiva_test` → Directiva
  - `entrenadora_test` → Entrenadora
  - `patinadora_test` → Patinadora


:::{image} /_static/assets/img/Tema8/grups-filtre.png
:alt: Grups de seguretat del club de patinatge.
:width: 100%
:::

---

## 3) Definir permisos al model (ACL · `ir.model.access.csv`)

Objectiu:
- Controlar què pot fer cada grup sobre `patinatge.inscripcio`.

Tasca:
- Obri `security/ir.model.access.csv` i afig les regles següents:

```text
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_inscripcio_directiva,inscripcio directiva,model_patinatge_inscripcio,patinatge_inscripcio.group_patinatge_directiva,1,1,1,1
access_inscripcio_entrenadora,inscripcio entrenadora,model_patinatge_inscripcio,patinatge_inscripcio.group_patinatge_entrenadora,1,1,0,0
access_inscripcio_patinadora,inscripcio patinadora,model_patinatge_inscripcio,patinatge_inscripcio.group_patinatge_patinadora,1,0,1,0
```

::: {admonition} Precisió tècnica (CSV)
:class: tip
En `model_id:id` usa el prefix `model_` i guions baixos:  
`patinatge.inscripcio` → `model_patinatge_inscripcio`
:::

Actualitza el mòdul i prova amb cada usuari:

- 👑 Directiva → pot crear, editar i esborrar inscripcions.
- 👩‍🏫 Entrenadora → pot vore i editar; ❌ no pot crear ni esborrar.
- 🛼 Patinadora → pot crear; ❌ no pot editar ni esborrar.

👉 Pregunta clau: La patinadora veu totes les inscripcions?  
Sí… de moment 😏. L’ACL diu “què pot fer”, però no “quins registres” veu.  Encara que la patinadora només tinga permís de lectura i creació,
encara veu totes les inscripcions.


:::{image} /_static/assets/img/Tema8/usuaris-confi.png
:alt: Usuaris de prova amb els seus rols assignats.
:width: 100%
:::


### 🔥 3.1) Problema real: els permisos existeixen, però l’usuari no està al grup
Arribats a aquest punt, pot passar una cosa molt habitual:

👉 Els grups existeixen  
👉 El CSV està correcte  
👉 Però el menú **NO apareix**

Això no és un error del CSV ni de la vista.

👉 **L’usuari no té assignat el grup que toca**.
### 🔧 3.2) Arreglar usuaris de prova amb un post_init_hook
Per assegurar-nos que tots els usuaris de prova tenen el grup correcte,
usarem un `post_init_hook`.  Aquest pas NO és obligatori en un projecte real,  
però en una pràctica ens evita errors humans i ens permet centrar-nos en la seguretat.


Aquest hook:
- Assigna cada usuari al seu grup
- Evita haver-ho de fer a mà
- Reprodueix un cas real de projecte

 Recorda afegir la crida a la funció en el fitxer `__manifest__.py` per executar-la en la instal·lació o actualització del mòdul. Cal crear un fitxer anomenat `hooks.py` i afegir-lo a `__init__.py` amb `from .hooks import create_test_users`

```python
from odoo import api, SUPERUSER_ID

def create_test_users(cr, registry):
    env = api.Environment(cr, SUPERUSER_ID, {})
    
    # 1. Obtenir referències dels grups
    # Nota: assegura't que el prefix és el nom de la carpeta del teu mòdul
    group_dir = env.ref('patinatge_inscripcio.group_patinatge_directiva')
    group_ent = env.ref('patinatge_inscripcio.group_patinatge_entrenadora')
    group_pat = env.ref('patinatge_inscripcio.group_patinatge_patinadora')

    # 2. L'Admin sempre ha de ser Directiva
    admin = env.ref('base.user_admin')
    admin.write({'groups_id': [(4, group_dir.id)]})

    # 3. Llista d'usuaris i el seu grup corresponent
    users_to_fix = [
        ('directiva_test', group_dir),
        ('entrenadora_test', group_ent),
        ('patinadora_test', group_pat),
    ]

    for login, group in users_to_fix:
        user = env['res.users'].search([('login', '=', login)], limit=1)
        if user:
            # Si l'usuari ja existeix, li "marquem" el seu grup
            user.write({'groups_id': [(4, group.id)]})
        else:
            # Si no existeix, el creem de zero amb el grup
            env['res.users'].create({
                'login': login,
                'name': login.replace('_', ' ').title(),
                'password': 'odoo123',
                'groups_id': [(4, group.id)]
            })
```
Les contrassenyes poden ser senzilles per a proves (ex: `odoo123`). Es creen amb el codi anterior afegint la línia següent al manifest:

```python
'post_init_hook': 'create_test_users',
```
:::{admonition} Nota important sobre el post_init_hook
:class: important
El post_init_hook s’executa en la instal·lació del mòdul (-i), no en cada actualització (-u). Caldrà desinstalar i tornar a instal·lar el mòdul per veure els canvis.

Per això:

- -i → crea dades inicials (usuaris, configuració, etc.)

- -u → només actualitza codi i dades XML

Si el hook no s’executa, no és un error, és el comportament normal d’Odoo.
::: 



::: {admonition} Per què ací i no abans?
:class: note
El hook **no crea seguretat**.

Només fa una cosa:
- Assegurar que els usuaris estan dins dels grups correctes

Sense grup:
- El menú no apareix
- Els permisos no s’apliquen
- Odoo no dóna cap error

👉 Primer definim seguretat, després arreglem usuaris.
👉 Si ho fas al revés, acabaràs pensant que Odoo està boig (i no ho està).
:::



---

## 4) Prerequisit per a les record rules: afegir `partner_id` al model
Per poder filtrar “el que és meu”, el model ha de saber qui és el contacte (partner) que fa la inscripció. Afig el camp `partner_id` a `patinatge.inscripcio`. Açò és provisional per a la pràctica ja que caldria acceptar la inscripció per a convertir-la en patinadora però cal tenir un camp relacionat amb res.partner per a la record rule.

```python
# filepath: patinatge_inscripcio/models/patinatge_inscripcio.py
from odoo import api, fields, models

class PatinatgeInscripcio(models.Model):
    _name = 'patinatge.inscripcio'
    # ...existing code...

    partner_id = fields.Many2one(
        'res.partner',
        string='Contacte (qui fa la inscripció)',
        required=True,
        default=lambda self: self.env.user.partner_id
    )

    # ...existing code...
```

::: {admonition} Per què és necessari?
:class: note
- Les record rules filtren per “qui eres” (usuari) i “a qui representes” (partner).  
- Amb `partner_id` podem fer el domini: `[('partner_id', '=', user.partner_id.id)]`.  
- Si ja tens un camp com `soci_id`, pots mantindre’l o substituir-lo per `partner_id` en la regla.
:::

::: {admonition} Actualitza i prova
:class: tip
- Actualitza el mòdul: `docker compose exec web odoo -u patinatge_inscripcio -d morrallaodoo --stop-after-init`  
:::

## 5) Aplicar una record rule: ara sí, seguretat de veritat 🔥

Objectiu:
- Fer que la patinadora només veja les seues inscripcions. Ara mateix veu totes però no pot editar.
  
:::{image} /_static/assets/img/Tema8/patinadora-test.png
:alt: Patinadora veient totes les inscripcions abans d’aplicar la record rule
:width: 100%
:::

Tasca:
- En `security/security.xml`, afig esta regla:

```xml
  <record id="rule_patinadora_veure_propia_inscripcio" model="ir.rule">
    <field name="name">Patinadora: veure pròpia inscripció</field>
    <field name="model_id" ref="model_patinatge_inscripcio"/>
    <!-- La variable 'user' és global en dominis: cada usuari té un partner vinculat -->
    <field name="domain_force">[('partner_id', '=', user.partner_id.id)]</field>
    <!-- Aplica la regla al grup Patinadora -->
    <field name="groups" eval="[(4, ref('patinatge_inscripcio.group_patinatge_patinadora'))]"/>
  </record>
```
A la imatge es veu que ja no té accés a les altres inscripcions. 
:::{image} /_static/assets/img/Tema8/patinadora-despres.png
:alt: Patinadora veient només la seua inscripció després d’aplicar la record rule
:width: 100%
:::

::: {admonition} Relació usuari ↔ partner (clau per a record rules)
:class: note
En Odoo, cada usuari (res.users) està vinculat a un contacte (res.partner).  
Aquesta relació és automàtica i és clau per a les record rules.

Quan usem:
`user.partner_id.id` → accedim al contacte associat a l’usuari actual.

Per això la record rule:
`[('partner_id', '=', user.partner_id.id)]`  
funciona: filtra els registres que pertanyen al partner de l’usuari connectat.

> Usuari = qui entra al sistema  
> Partner = a qui representen les dades
:::

Actualitza el mòdul.

Verificació final 🔍
- Entra com a patinadora: ✔️ només veu les seues inscripcions.
- Entra com a directiva: ✔️ ho veu tot.
- Entra com a entrenadora: ✔️ continua veient el que li toca segons permisos.

👉 Mateix CSV, resultat diferent → gràcies a la record rule.

::: {admonition} Idea clau
:class: tip
- ACL (CSV) → “què pot fer” cada grup (read, write, create, unlink).  
- Record rule → “sobre quins registres” exactes pot aplicar eixes accions.  
:::

---

## 6) Conclusions (obligatòries)
Respon breument:
- Què passava abans de la record rule?
- Què ha canviat després d’afegir-la?
- Per què el CSV no és suficient en molts casos?
- Per què no és bona idea confiar només en vistes?

---

## 7) Entrega

Cal entregar:
- El mòdul “patinatge” actualitzat (zip o repo).
- Un PDF amb:
  - Captura com a patinadora abans de la record rule.
  - Captura com a patinadora després de la record rule.
  - Captura com a directiva.
  - Respostes a les preguntes de conclusions.
:::

