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


::: {admonition} Objectius de la pràctica
:class: tip
En acabar la pràctica sabràs:
- Crear grups reals d’usuaris.
- Assignar permisos amb `ir.model.access.csv`.
- Comprovar què passa quan falten permisos.
- Aplicar record rules i vore la diferència abans/després.
- Entendre per què amagar botons no és seguretat.
:::

### Requisits previs
👉 En esta pràctica NO crearem vistes noves, només seguretat real (grups, ACL i record rules). No crearem vistes noves, però **necessitem que el model `patinatge.inscripcio` tinga almenys una vista tree i una form** per poder provar els permisos. Si no has fest l'excerccici anterior o el teu mòdul `patinatge_inscripcio` no les té definides, usa la vista següent a `views/patinatge_inscripcio_views.xml` 

:::{dropdown} Codi complet de la vista `patinatge_inscripcio_views.xml`
:class-container: tip

```xml

<?xml version="1.0" encoding="utf-8"?>
<odoo>

    <record id="view_patinatge_inscripcio_tree" model="ir.ui.view">
        <field name="name">patinatge.inscripcio.tree</field>
        <field name="model">patinatge.inscripcio</field>
        <field name="arch" type="xml">
            <tree create="false" edit="true">
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
            </tree>
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
        <field name="view_mode">tree,form</field>
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

:::{tip}

**Pots descarregar el fitxer:**

**[patinatge_inscripcio_views.xml](../_static/scripts/patinatge_inscripcio_views.xml)**

```{eval-rst}
.. only:: latex

  .. raw:: latex

    \noindent\textit{Versió PDF (visors compatibles): }\textattachfile{patinatge_inscripcio_views.xml}{patinatge\_inscripcio\_views.xml}
```

:::


---

## Preparació de l’entorn
Abans de començar la pràctica, cal tindre clar com està organitzat el projecte.
En aquesta pràctica treballem amb un únic mòdul (`patinatge_inscripcio`) que no depén d'altres mòduls. S'ha preparat així per centrar-nos exclusivament en la seguretat sense complicar-ho amb dependències.

📦 Mòdul

- patinatge_inscripcio
  - Mòdul específic per gestionar:
      - El model patinatge.inscripcio
      - Les inscripcions al club
      - La lògica associada a l’alta de patinadores


Consisteix a crear els grups de seguretat, definir els permisos d’accés al model i aplicar una record rule per a que les patinadores només vegen les seues inscripcions:
- Model `patinatge.inscripcio` operatiu.
- Almenys 3 usuaris de prova (els crearem automàticament amb un hook, però si vols crear-los a mà, són aquests):
  - `directiva_test`
  - `entrenadora_test`
  - `patinadora_test`

👉 Si no existeixen, cal que els crees des del backend: Configuració → Usuaris.

 
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
docker compose exec db psql -U odoo -d cpa
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

👉 Per a classe i proves: utilitza la primera.
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

## Crear els grups de seguretat

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

## Definir permisos al model (ACL · `ir.model.access.csv`)

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

- **Directiva**: pot crear, editar i esborrar inscripcions.
- **Entrenadora**: pot vore i editar; no pot crear ni esborrar.
- **Patinadora**: pot crear; no pot editar ni esborrar.

### Observació important: limitacions de l'ACL

La patinadora veu totes les inscripcions registrades al sistema, malgrat que l'ACL li permet només lectura i creació.

Això ocorre perquè l'ACL defineix **quines accions pot fer** (lectura, escriptura, creació, eliminació), però **no defineix sobre quins registres específics** pot aplicar eixes accions.

Per tant, fins que no s'afegisca una record rule, l'ACL és insuficient per garantir que cada usuari només veja les dades que li pertanyen.


:::{image} /_static/assets/img/Tema8/usuaris-confi.png
:alt: Usuaris de prova amb els seus rols assignats.
:width: 100%
:::


### Problema real: els permisos existeixen, però l'usuari no està al grup

Arribats a aquest punt, pot ocórrer una situació molt habitual en la pràctica:

- Els grups existeixen als paràmetres de seguretat.
- El fitxer CSV amb els permisos està correctament definit.
- Però el menú no apareix a la interfície de l'usuari.

Això no és un error en la configuració del CSV ni en la definició de la vista.

**La causa més probable és que l'usuari no té assignat el grup de seguretat que correspon.**

En Odoo, per veure un menú, l'usuari ha de pertànyer almenys a un dels grups que s'han definit en la configuració de seguretat. Si falta aquesta assignació, la interfície no mostra cap error; simplement amaga el menú de manera silenciosa.

Per resoldre-ho, verifica que cada usuari de prova té assignats els grups correctes:
- `directiva_test` → Directiva
- `entrenadora_test` → Entrenadora  
- `patinadora_test` → Patinadora

Accedeix a **Configuració → Usuaris i Empreses → Usuaris**, selecciona cada usuari i confirma que apareix el grup corresponent en el camp de grups.

### 🔧 Arreglar usuaris de prova amb un post_init_hook
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

## Prerequisit per a les record rules: afegir `partner_id` al model
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
- Actualitza el mòdul: `docker compose exec web odoo -u patinatge_inscripcio -d cpa --stop-after-init`  
:::

## Aplicar una record rule: ara sí, seguretat de veritat 🔥

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

### Què significa el `4` en `(4, ref(...))`?

El `4` és un comando ORM de **Many2many** d'Odoo. En camps relacionals Many2many, s'utilitza una llista de tuples amb un codi numèric per indicar l'operació:

| Codi | Operació |
|------|----------|
| `0`  | Crea i enllaça un nou registre |
| `1`  | Modifica un registre existent |
| `2`  | Elimina i desenllaça un registre |
| `3`  | Desenllaça (sense eliminar) |
| `4`  | **Enllaça un registre existent** (sense crear ni eliminar) |
| `5`  | Desenllaça tots |
| `6`  | Substitueix tota la llista |

En aquest cas, `(4, ref('patinatge_inscripcio.group_patinatge_patinadora'))` vol dir:

> "Afegeix el grup `group_patinatge_patinadora` a la relació `groups` de la regla, sense crear-lo ni eliminar-lo, simplement associant-lo."

És equivalent a un **ADD** en una relació Many2many: la regla d'accés `rule_patinadora_veure_propia_inscripcio` quedarà vinculada al grup **Patinadora**.


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

## I si la patinadora sols ha d'accedir al portal?

En molts casos reals, les patinadores **no necessiten accedir al backend d'Odoo** (el panell d'administració). Només necessiten accedir al **portal web** per consultar o gestionar la seua inscripció.

En Odoo, els usuaris de tipus **portal** (`base.group_portal`) accedeixen a una interfície pública simplificada, sense menús d'administració ni vistes internes.

Per implementar-ho, cal crear l'usuari patinadora com a **portal** en lloc d'**internal**. El hook `post_init_hook` del mòdul s'encarrega d'aquesta lògica automàticament en instal·lar-lo.

A més, incorporem un `uninstall_hook` que **elimina els usuaris de prova** quan es desinstal·la el mòdul, per deixar el sistema net.

Crea o actualitza el fitxer `hooks.py` a l'arrel del mòdul:

```python
# Importem l'API d'Odoo i la constant SUPERUSER_ID per executar accions com a superusuari
from odoo import api, SUPERUSER_ID

# Llista dels logins dels usuaris de prova que gestiona aquest mòdul
TEST_USERS = ['directiva_test', 'entrenadora_test', 'patinadora_test']

# Diccionari que mapeja cada login amb la referència XML del seu partner (res.partner) de prova
TEST_USER_PARTNERS = {
    'directiva_test': 'patinatge_inscripcio.partner_directiva_test',
    'entrenadora_test': 'patinatge_inscripcio.partner_entrenadora_test',
    'patinadora_test': 'patinatge_inscripcio.partner_patinadora_test',
}

# Referència única de la inscripció de prova de la patinadora
TEST_PATINADORA_REF = 'TEST-PAT-001'


# Hook que s'executa després d'instal·lar o actualitzar el mòdul (post_init_hook)
def create_test_users(cr, registry):
    # Creem un entorn Odoo amb permisos de superusuari
    env = api.Environment(cr, SUPERUSER_ID, {})

    # Obtenim els grups funcionals definits al mòdul
    group_dir = env.ref('patinatge_inscripcio.group_patinatge_directiva')
    group_ent = env.ref('patinatge_inscripcio.group_patinatge_entrenadora')
    group_pat = env.ref('patinatge_inscripcio.group_patinatge_patinadora')
    # Obtenim els grups estàndard d'Odoo per al tipus d'usuari
    group_internal = env.ref('base.group_user')   # usuari intern (empleat)
    group_portal = env.ref('base.group_portal')   # usuari portal (accés limitat)

    # Afegim el grup Directiva a l'usuari administrador (sense treure'n cap altre)
    admin = env.ref('base.user_admin')
    admin.write({'groups_id': [(4, group_dir.id)]})

    # Definim els usuaris de prova: (login, nom mostrat, grup funcional, tipus d'accés)
    users_to_fix = [
        # login, name, grup funcional, tipus usuari
        ('directiva_test', 'Directiva Test', group_dir, 'internal'),
        ('entrenadora_test', 'Entrenadora Test', group_ent, 'internal'),
        ('patinadora_test', 'Patinadora Test', group_pat, 'portal'),
    ]

    for login, name, group, user_type in users_to_fix:
        # Busquem el partner de prova associat a aquest usuari (pot no existir)
        partner = env.ref(TEST_USER_PARTNERS[login], raise_if_not_found=False)

        # Valors comuns: contrasenya i grup funcional específic del rol
        vals = {
            'password': 'odoo123',
            'groups_id': [(4, group.id)],  # (4, id) = afegir grup sense eliminar els altres
        }

        # Si existeix el partner de prova, l'associem a l'usuari
        if partner:
            vals['partner_id'] = partner.id

        # Assignem el tipus d'usuari: intern o portal (mutuament excloents a Odoo)
        if user_type == 'internal':
            # (4, ...) afegeix el grup; (3, ...) desenllaça sense eliminar
            vals['groups_id'] += [(4, group_internal.id), (3, group_portal.id)]
        else:
            vals['groups_id'] += [(4, group_portal.id), (3, group_internal.id)]

        # Comprovem si l'usuari ja existeix (per login)
        user = env['res.users'].search([('login', '=', login)], limit=1)
        if user:
            # Si ja existeix, actualitzem els seus valors
            user.write(vals)
        else:
            # Si no existeix, el creem amb login, nom i la resta de valors
            env['res.users'].create({
                'login': login,
                'name': name,
                **vals,  # desempaquetem el diccionari vals dins del create
            })

    # Un cop creats els usuaris, assegurem que existeix la inscripció de prova
    ensure_patinadora_inscripcio(env)


def ensure_patinadora_inscripcio(env):
    # Busquem el partner de la patinadora de prova; si no existeix, no fem res
    partner = env.ref('patinatge_inscripcio.partner_patinadora_test', raise_if_not_found=False)
    if not partner:
        return

    # Comprovem si ja existeix una inscripció amb la referència de prova
    inscripcio = env['patinatge.inscripcio'].search([
        ('reference', '=', TEST_PATINADORA_REF)
    ], limit=1)

    # Valors de la inscripció de prova
    vals = {
        'reference': TEST_PATINADORA_REF,
        'partner_id': partner.id,
        'nom_patinadora': 'Patinadora Test',
        'cognoms_patinadora': 'Test',
        'data_naixement': '2012-05-10',
        'categoria': 'iniciacio',
        'nom_tutor': 'Tutor/a Test',
        'dni_tutor': '00000000T',
        'telefon_tutor': '600000000',
        'email_tutor': 'patinadora_test@example.com',
    }

    if inscripcio:
        # Si ja existeix, només actualitzem el partner_id per garantir la consistència
        inscripcio.write({'partner_id': partner.id})
    else:
        # Si no existeix, creem la inscripció completa
        env['patinatge.inscripcio'].create(vals)


# Hook que s'executa quan es desinstal·la el mòdul
def uninstall_hook(cr, registry):
    # Creem un entorn Odoo amb permisos de superusuari
    env = api.Environment(cr, SUPERUSER_ID, {})

    # Busquem la inscripció de prova, incloent les arxivades (active_test=False)
    inscripcio_test = env['patinatge.inscripcio'].with_context(active_test=False).search([
        ('reference', '=', TEST_PATINADORA_REF)
    ])
    if inscripcio_test:
        # Eliminem definitivament la inscripció de prova
        inscripcio_test.unlink()
        print(f"Inscripció de prova eliminada: {TEST_PATINADORA_REF}")

    # Busquem tots els usuaris de prova, incloent els arxivats
    users = env['res.users'].with_context(active_test=False).search([
        ('login', 'in', TEST_USERS)
    ])
    if users:
        # Eliminem definitivament els usuaris de prova de la base de dades
        users.unlink()
        print(f"Usuaris eliminats: {TEST_USERS}")
```
:::{tip}

**Pots descarregar el fitxer:**

**[hooks.py](../_static/scripts/hooks.py)**

```{eval-rst}
.. only:: latex

  .. raw:: latex

    \noindent\textit{Versió PDF (visors compatibles): }\textattachfile{hooks.py}{hooks.py}
```

:::
::: {admonition} Punts clau d'aquest hook
:class: note
- La llista `users_to_fix` defineix cada usuari de prova amb el seu **tipus** (`internal` o `portal`).
- Per a `patinadora_test` s'assigna `base.group_portal` i s'elimina `base.group_user` (grup intern), de manera que **no podrà accedir al backend**.
- Es crea (o es reassigna) una inscripció de prova a `patinadora_test`, perquè la record rule li mostre almenys un registre seu.
- El codi `(3, group_portal.id)` desenllaça el grup portal sense eliminar-lo (si no estava assignat, no fa res).
- El `uninstall_hook` usa `active_test=False` i elimina tant la **inscripció de prova** com els **usuaris de prova**.


:::
Recorda que cal declarar els hooks al `__manifest__.py`:

```python
'post_init_hook': 'hooks.create_test_users',
'uninstall_hook': 'hooks.uninstall_hook',
```
També cal assegurar-se que el fitxer `hooks.py` està importat a `__init__.py`:

```python
from .hooks import create_test_users, uninstall_hook
```

---

## Conclusions 
Ara ens quedaria una vista de portal per a la patinadora que pobra ja no pot vore la seua inscripció al backend. A més caldria afegir l'acceptació de la inscripció per a convertir-la en patinadora i que tinga accés real al portal ja que l'hem creada com a test. Així una inscripció derivaria a un procés de validació per part de la directiva o entrenadora i després es convertiria en usuari de portal real amb accés a les seues dades. Exedeix de l'objectiu del curs però t'animes a implementar-ho? 

El més important és entendre què hem fet i per què.

**Què passava abans de la record rule?**  
L'ACL (CSV) permetia que la patinadora pogués llegir i crear inscripcions, però **sense filtrar per registre**. Veia totes les inscripcions del sistema, malgrat que no podia editar-les. Era com tenir les claus d'una porta però poder veure dins totes les finestres.

**Què ha canviat després d'afegir-la?**  
La record rule afegeix un filtre de domini: `[('partner_id', '=', user.partner_id.id)]`. Ara, **només veu els registres que li pertanyen**. La patinadora veu només la seua inscripció. La directiva i l'entrenadora (sense record rule) ho veuen tot.

**Per què el CSV no és suficient en molts casos?**  
El CSV controla **accions** (read, write, create, unlink), però no **quins registres** s'apliquen aquestes accions. Per a sistemes multi-usuari on cadascun ha de veure només les seues dades, calen record rules que defineixin dominis.

**Per què no és bona idea confiar només en vistes?**  
Les vistes són interfície de usuari: es pot desactivar JavaScript, manipular DOM o accedir directament a la API REST. **Amagar un botó no és seguretat**. Les record rules i l'ACL s'apliquen al servidor (backend), on l'usuari no pot manipular-les.

**Què passar si la patinadora és un usuari de portal?**  
Si la patinadora és un usuari de portal (`base.group_portal`), no té accés al backend i només podrà veure les seues dades a través del portal web. En aquest cas, la record rule seguiria aplicant-se per garantir que només accedeix a les seues inscripcions, però la interfície seria diferent (portal vs backend).

---

## Entrega

Cal entregar:
- El mòdul “patinatge_inscripcio”  (zip o repo).
- Un PDF amb:
  - Captura com a patinadora abans de la record rule.
  - Captura com a patinadora després de la record rule.
  - Captura com a directiva.
  - Captura si has implementat alguna funcionalitat addicional.
  - Explica quina impresió tens ara sobre la seguretat a Odoo i què has après amb aquesta pràctica, si t'ha resultat fàcil o difícil, si tens dubtes pendents, si has tingut algun problema i com l'has resolt, etc.


