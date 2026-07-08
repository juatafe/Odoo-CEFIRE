# Permisos i rols en Odoo per a la colla


## Context de la tasca
La colla de dolçaines i tabals ja utilitza Odoo per gestionar músics, grups i actes.
Ara la directiva s’ha cansat del “tothom ho veu tot” i vol posar ordre:

- La directiva mana (com sempre).
- Els responsables gestionen, però amb límits.
- Els músics només poden veure el que és seu.


**El flux de treball de la Colla**

A diferència d'altres sistemes on la informació és estàtica, a la nostra colla les dades viatgen a través d'un flux viu de validació. Imagina el següent escenari de la vida real:

1. **La Convocatòria**: La directiva o el responsable crea un acte (per exemple, «Processó de Sant Joan») i hi afig línies de participació per a diversos músics en estat Pendent. Cada músic ha de tindre assignat el seu Instrument (dolçaina, tabal, percussió...) perquè tenim músics que poden tocar més d'un instrument.

2. **La Resposta del Músic**: El músic rep la notificació al seu portal i té l'obligació d'**Acceptar** o **Rebutjar** la seua assistència segons la seua disponibilitat.

3. **El Triatge (La plantilla definitiva)**: A vegades hi ha més músics disponibles dels que realment contracten per a l'acte. És en aquest moment on el **Responsable de l'acte** o bé la **Directiva** entra en acció: revisa qui ha acceptat i selecciona la plantilla final. Aquells músics que sí que havien acceptat però que finalment no fan falta, el responsable canviarà el seu estat a **Anul·lat**.

🔒 **Què volem aconseguir amb la seguretat?**

El nostre objectiu és que el sistema reaccione de manera intel·ligent segons el rol de l'usuari connectat:

- **Músics**: Només han de veure les participacions on estan convocats i, atenció, **si el responsable anul·la la seua participació, l'acte ha de desaparéixer instantàniament de la seua vista** per a evitar confusions. A més, poden acceptar o rebutjar, però tenen prohibit anul·lar ningú.

- **Responsables**: Sols han de veure les participacions i els músics dels actes dels quals **ells són els responsables assignats**, podent realitzar el triatge (anul·lar participacions) des del backend.

- **Directiva**: Com que tenen el control total, ho veuen absolutament tot i supervisen la colla.

::: {admonition} Avís important sobre els menús
:class: warning
En Odoo, un menú **no apareix** si l’usuari no pertany a cap dels grups que el poden veure.

Encara que:
- El menú estiga ben definit
- L’acció existisca
- El model tinga permisos

👉 Si l’usuari no té el grup correcte, **el menú desapareix sense donar cap error**.

Aquesta tasca està pensada perquè detectes i entengues aquest comportament.
:::

**Objectius de la tasca**
En acabar la tasca sabràs:

- Crear categories i grups reals d'usuaris adaptats a Odoo 19.
- Assignar permisos estructurats amb ir.model.access.csv.
- Aplicar **Record Rules** (regles de registre) avançades amb condicions combinades (`user_id` i l'estat del registre).
- Programar validacions de seguretat en el servidor amb Python per a protegir els botons d'acció.
- Entendre la diferència real entre la interfície de gestió (backend) i la d'usuaris externs (portal).

## Preparació de l’entorn
En aquesta tasca **NO crearem models nous**, sinó que configurarem la seguretat real (grups, ACL i *record rules*) sobre la infraestructura que ja tenim. No obstant això, per a poder implementar el flux de treball de la colla (convocatòria, triatge i anul·lació), necessitem assegurar-nos que els nostres models en Python tenen els camps necessaris i que disposem d'una interfície gràfica (vistes) on es mostren aquests canvis.

### Ampliació dels models en Python (`models/`)
Abans de tocar la seguretat, revisa els teus fitxers `.py` i assegura't que els models d'**Acte** i de **Participacio** incorporen els següents camps clau per a la lògica de negoci:

- Al model `agrupaciomusical.acte`: Hem d'afegir el camp `responsable_id` per a saber quin usuari gestiona l'esdeveniment.
- Al model `agrupaciomusical.participacio`: Necessitem el camp `instrument`, el camp `estat` (amb els 4 estats del cicle) i els botons per a interactuar.

Per tant afegeix en el fitxer `acte.py` la definició del camp per al responsable, que pot heretat o bé de músic o bé de l'usuari que es connecta a l' aplicació. Per a evitar problemes en les comprovacions de seguretat millor triem l'opció de relacionar-lo amb l'usuari (`res.users`).

```python
# Enllaçem l'acte amb l'usuari intern del sistema que serà el responsable
responsable_id = fields.Many2one('res.users', string='Responsable de l\'acte')

```

El codi que hem d'ampliar en el model `participacio` és per un costat afegir els camps per a l'instrument i per a l'estat, i per un altre costat afegir els botons per canviar el valor de l'estat. Per a l'instrument podem aprofitar la constant que ja vam definir en el model `music`, però per això hem d'afegir un import nou. Per als valos de l'estat també definirem una constant nova.

```python
from .music import INSTRUMENT_SELECTION

ESTAT_SELECTION = [
    ('pendent', 'Pendent de confirmar'),
    ('confirmat', 'Confirmat'),
    ('rebutjat', 'Rebutjat'),
    ('anulat', 'Anul·lat')
]

class Participacio(models.Model):
    ...

    estat = fields.Selection(ESTAT_SELECTION, string="Estat") 

    instrument = fields.Selection(
        INSTRUMENT_SELECTION,
        string="Instrument",
        default='pendent',
        required=True,
        readonly=True
    )

    ...

    # Mètodes per als botons d'acció (la seua seguretat es programarà en l'apartat 7)
    def action_acceptar(self):
        for rec in self:
            rec.estat = 'acceptat'

    def action_rebutjar(self):
        for rec in self:
            rec.rec.estat = 'rebutjat'

    def action_anular(self):
        for rec in self:
            rec.estat = 'anulat'

```

### Definició de les vistes (`views/`)
Per a poder provar els permisos i interactuar amb el flux, necessitem que el model `participacio` tinga almenys una vista de llista (list) i una de formulari (form).

Si el teu mòdul no les té definides (o vols actualitzar-les amb els nous camps i botons), utilitza la següent configuració al fitxer `views/agrupaciomusical_participacio_views.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<odoo>
    <record id="view_agrupaciomusical_participacio_list" model="ir.ui.view">
        <field name="name">agrupaciomusical.participacio.list</field>
        <field name="model">agrupaciomusical.participacio</field>
        <field name="arch" type="xml">
            <list string="Participacions en Actes">
                <field name="acte_id"/>
                <field name="music_id"/>
                <field name="instrument"/>
                <field name="estat" widget="badge" 
                       decoration-info="estat == 'pendent'" 
                       decoration-success="estat == 'acceptat'" 
                       decoration-danger="estat == 'rebutjat'" 
                       decoration-muted="estat == 'anul·lat'"/>
            </list>
        </field>
    </record>

    <record id="view_agrupaciomusical_participacio_form" model="ir.ui.view">
        <field name="name">agrupaciomusical.participacio.form</field>
        <field name="model">agrupaciomusical.participacio</field>
        <field name="arch" type="xml">
            <form string="Participació">
                <header>
                    <button name="action_acceptar" 
                            string="Acceptar Convocatòria" 
                            type="object" 
                            class="oe_highlight" 
                            invisible="estat != 'pendent'"/>
                    <button name="action_rebutjar" 
                            string="Rebutjar" 
                            type="object" 
                            invisible="estat != 'pendent'"/>
                    <button name="action_anular" 
                            string="Anul·lar Participació" 
                            type="object" 
                            class="btn-danger" 
                            invisible="estat != 'acceptat'"/>
                    <field name="estat" 
                           widget="statusbar" 
                           statusbar_visible="pendent,acceptat,rebutjat,anul·lat"/>
                </header>
                <sheet>
                    <group>
                        <group>
                            <field name="acte_id"/>
                            <field name="music_id"/>
                        </group>
                        <group>
                            <field name="instrument"/>
                        </group>
                    </group>
                </sheet>
            </form>
        </field>
    </record>
    <record id="action_agrupaciomusical_participacio" 
            model="ir.actions.act_window">
        <field name="name">Assistència</field>
        <field name="res_model">agrupaciomusical.participacio</field>
        <field name="view_mode">list,form</field>
        <field name="help" type="html">
            <p class="o_view_nocontent_smiling_face">
                No hi ha cap participació creada.
            </p>
            <p>
                La directiva o els responsables crearan ací les convocatòries de músics.
            </p>
        </field>
    </record>
</odoo>
```


**Què fa especial aquesta vista?**

Fixa't en l'etiqueta `<header>`. Hem col·locat tres botons que criden als mètodes de Python que acabem de definir. Utilitzem l'atribut `invisible="estat != '...'"` per a fer que els botons apareguen o desapareguen dinàmicament segons la fase del flux en què es trobe la participació.

::: {admonition} Fixa't
:class: tip
A la fi del fitxer XML hem creat una acció. Recorda que si més endavant un usuari es connecta a l'Odoo i aquest menú de sobte desapareix d'una manera completament invisible (sense errors en pantalla), no és perquè s'haja esborrat l'XML, sinó perquè s'està aplicant la seguretat de l'ORM d'Odoo que anem a programar en els pròxims punts.
::: 

Abans de continuar, recorda comprovar que tant els fitxers `.py` com el nou XML de vistes estan correctament llistats al teu `__manifest__.py` i que has creat una nova opció en el menú (`views/agrupaciomusical_menus.xml`).

:::{caution} 
Com que has fet canvis estructurals recorda que cal reiniciar el teu entorn Docker per aplicar-los, no sols actualitzar el mòdul.
:::


## Creació de categories, privilegis i grups de seguretat
Una vegada tenim els models i les vistes preparats, és el moment de dissenyar l'estructura de rols de l'aplicació, per això el primer pas serà escriure el codi XML per a declarar l'estructura base de seguretat de la colla. Dins de la carpeta del teu mòdul, crea el subdirectori `security/` (si no el tenies ja) i, a dins, un fitxer anomenat `security.xml`.
Els passos són:
1. Definir un *record* per a la nova categoria basat en el model `ir.module.category` 
2. Definir un *record* per al privilegi d'esta categoria, basat en el model `res.groups.privilege`
3. Definir un *record* per cada rol basat en el model `res.groups` relacionats amb el privilegi anterior. Cada rol ha de tindre també la referència del privilegi del punt 2

<!-- Exemple:
```xml
<?xml version="1.0" encoding="utf-8"?>
<odoo>
    <data noupdate="0">
        <!--Definició de la categoria-->
        <record id="module_category_agrupaciomusical" model="ir.module.category">
            <field name="name">Agrupació Musical</field>
            <field name="description">Gestió de rols i permisos per a la colla de dolçaines i tabals.</field>
            <field name="sequence">10</field>
        </record>

        <record id="res_groups_privilege_agrupacionmusical" model="res.groups.privilege">
            <field name="name">Accés General Agrupació Musical</field>
            <field name="category_id" ref="module_category_agrupaciomusical"/>
            <field name="sequence">70</field>
        </record>
        <!--El Rol de Músic (Usuari Base)-->
        <record id="group_musics" model="res.groups">
            <field name="name">Músic de la colla</field>
            <field name="privilege_id" ref="res_groups_privilege_agrupacionmusical"/>
            <field name="implied_ids" eval="[(4, ref('base.group_portal'))]"/>
        </record>
        <!--El Rol de Directiu (Administrador del Mòdul)-->
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

    </data>
</odoo>
```
-->

::: {admonition} Idea clau
• `base.group_portal`: Fa que el grup es comporte com un usuari extern (veurà la web simplificada, l'apartat de "Músic").

• `base.group_user`: Converteix l'usuari en personal intern (veurà el backend ple d'aplicacions, menús i llistats).

• **L'ordre al manifest**: Els fitxers de seguretat XML s'han de carregar **sempre abans** de qualsevol vista o fitxer CSV. Si no es fa així, Odoo donarà un error indicant que l'ID del grup no existeix quan intente comprovar els permisos.
:::

Una vegada tens el xml que defineix els nous rols recorda afegir-lo en el `__manifest__.py` dins de la llista `'data'`, i vigila que quede exactament per damunt del fitxer de vistes que vas crear a l'apartat anterior.

Per a comprovar que vas pel bon camí accedeix al web amb el mode desenvolupador activat, i navega a Configuració → Usuaris i Empreses → Grups, busca *Agrupació Musical*. Si tot s'ha carregat correctament, veuràs els teus tres nous grups definits. 

## Definició de permisos per taula (ACL · `ir.model.access.csv`)
Al Capítol 7 hem après que el fitxer `ir.model.access.csv` és la primera línia de defensa d'Odoo. També recordareu la **regla d'or de les ACL**: si un model no està llistat ací, cap usuari del sistema (excepte el superusuari) podrà fer absolutament res amb ell.

En aquest apartat configurarem quines accions globals (`read`, `write`, `create`, `unlink`) pot fer cada grup sobre els nostres dos nous models: `agrupaciomusical.acte` i `agrupaciomusical.participacio`.

### Creació del fitxer d'accessos

Dins de la carpeta del teu mòdul, entra al directori `security/` i crea un fitxer anomenat exactament `ir.model.access.csv`.

Recorda que la primera línia d'aquest fitxer ha de contindre sempre les capçaleres obligatòries d'Odoo:

```
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
```

### Guia de disseny de permisos (El teu torn!)

En lloc de copiar un codi tancat, has de reflexionar i escriure les línies del CSV basant-te en la lògica de funcionament de la colla. Ací tens les directrius de la directiva:

1. **Gestió d'Actes** (`model_agrupaciomusical_acte`):
* **Directius:** Han de tindre el control total (poden llegir, editar, crear i esborrar actes).
* **Responsables d'actes:** Necessiten poder veure els actes i modificar-los (per a assignar-se o fer canvis), però la directiva no vol que puguen crear actes nous ni esborrar-los de la base de dades.
* **Músics:** Sols han de tindre permís de lectura (veure quins actes hi ha), però mai editar-los, crear-ne de nous ni esborrar-los.


2. **Gestió de Participacions** (`model_agrupaciomusical_participacio`):
* **Directius:** Control total.
* **Responsables i Músics:** Ambdós grups necessiten poder llegir i també editar (*write*) aquest model. Pensa que el músic ha de poder polsar el botó de "Acceptar/Rebutjar" (això modifica el camp `estat`, per tant, és escriptura) i el responsable ha de poder fer el triatge. Cap dels dos necessita esborrar registres globals.


::: {caution} Atenció amb els IDs de grup en Odoo 19!
Quan faces referència als teus grups en la columna `group_id:id`, recorda utilitzar el prefix del nom de la carpeta del teu mòdul seguit de l'ID XML que vas definir en el punt anterior (ex: `nom_modul.group_musics`, `nom_modul.group_responsable`, etc.).
:::

Ací tens una plantilla parcial del que ha d'anar al teu fitxer `ir.model.access.csv` per a començar. Completa les línies que falten per a tots els models i rols seguint la guia anterior (recorda fer servir `1` per a permetre i `0` per a prohibir):

```text
access_directiva_participacio,accés de directiva a participació,model_agrupaciomusical_participacio,agrupaciomusical.group_directiu,1,1,1,1
access_responsable_participacio,accés de responsable a participació,model_agrupaciomusical_participacio,agrupaciomusical.group_responsable,1,1,0,0
access_music_participacio,accés de músic a participació,model_agrupaciomusical_participacio,agrupaciomusical.group_musics,1,1,0,0
access_directiva_acte,accés de directiva a acte,model_agrupaciomusical_acte,agrupaciomusical.group_directiu,1,1,1,1
# ... ARA COMPLETA TU ELS ACCESSOS PER A RESPONSABLES I MÚSICS SOBRE EL MODEL ACTE ...

```

### Registre al Manifest i Prova de Càrrega

Un fitxer CSV de seguretat no fa res si Odoo no sap que ha de processar-lo. Obre el teu `__manifest__.py` i afegeix el CSV a la secció `'data'`.

:::🧐 Recordes la teoria de l'ordre?
El fitxer CSV utilitza els IDs dels grups que vas crear al fitxer XML. Per tant, el CSV s'ha de carregar **després del** `security.xml`, però **abans de les vistes**.
:::

El teu manifest ha de quedar així:

```python
'data': [
    # 1r: L'estructura de rols (XML)
    'security/security.xml',                  
    # 2n: Els permisos per taula (CSV)
    'security/ir.model.access.csv',           
    # 3r: Les interfícies gràfiques
    'views/agrupaciomusical_participacio_views.xml', 
    ...
],

```

Guarda els canvis, reinicia el teu entorn Docker i actualitza el mòdul. Si Odoo no llança cap error a la terminal durant la instal·lació, significa que has estructurat les línies i les referències perfectament!

Si ara et connectes amb un usuari que pertanga al grup de *Músics*, voràs que l'interfície et permet veure la llista d'actes, però si intentes crear-ne un de nou, el botó "Nou" haurà desaparegut o el sistema et llançarà un bloqueig de seguretat des del servidor.



## Seguretat per fila (Record Rules): Restringint l'accés al Músic

Al punt anterior hem configurat els permisos per taula mitjançant l'ACL (el CSV). Ara mateix, un músic té permís global de lectura i edició sobre les participacions. Però tenim un problema de "privacitat": si un músic entra al sistema, pot veure les convocatòries de *tots* els altres músics de la colla i saber si han acceptat o no.

Com vau aprendre a la teoria, per a solucionar l'efecte "tothom ho veu tot" i llimar l'accés a files de dades concretes, hem d'utilitzar les **Regles de Registre (Record Rules)** de l'ORM d'Odoo.

### La teoria de la triangulació (`partner_id`)

Abans d'escriure el codi XML, hem de pensar com sap Odoo si la línia de participació pertany al músic que ha iniciat la sessió.

Recordeu com tenim dissenyat el nostre model:

1. L'usuari connectat a Odoo és un registre del model `res.users`. Aquest registre té un camp intern anomenat `user.partner_id` (el seu contacte base).
2. El músic és un registre de `agrupaciomusical.music`, que hereta per delegació de `res.partner` (té el seu propi `partner_id`).
3. La participació (`agrupaciomusical.participacio`) apunta a un `music_id`.

Per tant, per a filtrar que el músic connectat només veja el que és seu, el domini de la regla ha de comparar si el contacte del músic de la participació coincideix amb el contacte de l'usuari que navega pel sistema.

### Creació del Record Rule del Músic

Obri el teu fitxer `security/security.xml` i, just abans de tancar l'etiqueta `</data>`, afegeix la primera regla de registre del mòdul.

Analitza bé l'estructura del codi i completa el camp del domini (*domain_force*) tenint en compte que la directiva ha demanat una condició doble: **El músic només veu la seua línia I a més l'estat d'aquesta NO ha de ser 'anul·lat'** (si el responsable el desmarca de l'acte, la participació ha de desaparéixer automàticament de la seua pantalla).

```xml
<record id="rule_participacio_music_actiu" model="ir.rule">
    <field name="name">Els músics sols veuen la seua participació activa</field>
    <field name="model_id" ref="model_agrupaciomusical_participacio"/>
    <field name="groups" eval="[(4, ref('agrupaciomusical.group_musics'))]"/>
    <field name="domain_force">[('music_id.partner_id', '=', user.partner_id.id), ('estat', '!=', 'anulat')]</field>
    <field name="perm_read" eval="True"/>
    <field name="perm_write" eval="True"/>
    <field name="perm_create" eval="True"/>
    <field name="perm_unlink" eval="True"/>
</record>

```
::: Idea clau sobre els operadors en els dominis
Recorda que en Odoo, quan col·loques dues tuples seguides dins d'una llista de domini (com ara `[(condicio1), (condicio2)]`), el sistema les avalua de manera interna amb un operador lògic **AND** implícit. Això vol dir que s'han de complir les dues condicions alhora per a mostrar el registre en pantalla.
:::

### Prova de funcionament

Com que aquest fitxer XML (`security/security.xml`) ja el tenies registrat al teu `__manifest__.py` des de l'apartat 3, només has de seguir aquests passos per a comprovar el canvi:

1. Reinicia el teu contenidor de Docker i actualitza el teu mòdul des de l'interfície d'Odoo.
2. Crea un acte nou des de l'usuari administrador i afegeix tres línies de participació per a tres músics diferents (assegura't que l'estat inicial és *Pendent*).
3. Connecta't a Odoo (obrint una finestra d'incògnit al navegador) utilitzant el compte d'un d'eixos músics de prova.
4. Entra al menú **Assistència**.

::: {admonition} Què hauria de passar?
:class: note
Si la teua *Record Rule* funciona correctament, el músic només veurà una única fila a la graella: la seua. La resta de convocatòries dels seus companys hauran quedat completament filtrades pel servidor de manera transparent.
:::

## Seguretat per fila (Record Rules): La vista del Responsable de l'acte

Al punt anterior hem blindat el portal dels músics perquè cadascun d'ells només puga accedir a les seues pròpies línies d'assistència. Ara hem de resoldre la segona part de l'encàrrec de la directiva: **la gestió dels Responsables d'actes**.

Actualment, a causa dels permisos globals del CSV, qualsevol usuari que pertanga al grup de *Responsables* pot veure absolutely totes les participacions de tots els actes de la colla. No obstant això, la directiva vol aplicar una política de privacitat i eficiència: un responsable de l'acte "Processó de Festes" només ha de veure els músics convocats a *eixe* acte, i no els de l'acte "Concert de Santa Cecília" del qual és responsable un altre company.

### Com creuar camps entre diferents models?

Al Capítol 7 vàrem aprendre a fer dominis simples basats en l'usuari connectat (`user.id`). Però en aquest cas, la restricció no depén directament del model `agrupaciomusical.participacio`, sinó del model relacionat `agrupaciomusical.acte`.

Recordem com viatgen les dades a la nostra base de dades:

1. L'usuari que ha iniciat la sessió al backend té un identificador únic accessible des d'XML com a `user.id`.
2. Cada línia de participació té un camp anomenat `acte_id` que apunta a l'acte corresponent.
3. Cada acte té un camp anomenat `responsable_id` que apunta a l'usuari (`res.users`) que el gestiona.

Per tant, per a filtrar les files des de la participació, hem d'utilitzar la notació de punt (`.`) per a "navegar" a través de la relació *Many2one* i arribar fins al responsable final de l'acte: `acte_id.responsable_id`.

### Creació del Record Rule del Responsable

Obre de nou el teu fitxer `security/security.xml`. Just davall de la regla del músic que vas escriure al punt anterior, afegeix aquesta segona regla de registre.

El teu objectiu és completar el camp `domain_force` perquè es complisca la condició: 
> **El responsable només veu les participacions on ell és el responsable de l'acte associat.**

```xml
<record id="rule_participacio_responsable_actes" model="ir.rule">
    <field name="name">Els responsables sols veuen els músics dels seus actes</field>
    <field name="model_id" 
           ref="model_agrupaciomusical_participacio"/>
    <field name="groups" 
           eval="[(4, ref('agrupaciomusical.group_responsable'))]"/>
    <field name="domain_force">[('acte_id.responsable_id', '=', user.id)]</field>
    <field name="perm_read" eval="True"/>
    <field name="perm_write" eval="True"/>
    <field name="perm_create" eval="True"/>
    <field name="perm_unlink" eval="True"/>
</record>

```

::: 🧠 Què passa amb el grup Directiu?
Potser et preguntes: *"Si apliquem aquest filtre, la Directiva podrà continuar veient-ho tot?"*. La resposta és **sí**. Com que no hem lligat aquesta regla al grup de directius (camp `groups`), l'ORM d'Odoo no els aplicarà cap filtre per fila sobre aquest model, mantenint el seu dret a supervisar tota la colla tal com especificava el CSV.
:::

### Prova del "Triatge" al Backend

Guarda el fitxer XML, reinicia el teu entorn Docker i actualitza el mòdul des de l'interfície d'Odoo per a carregar la nova regla a la base de dades.

Per a comprovar que la seguretat funciona com un rellotge, farem el següent experiment:

1. Amb l'usuari administrador, crea **dos actes diferents**:
* Acte A: "Cercavila Falla Corea" → Assigna com a responsable a l'usuari *Responsable A*.
* Acte B: "Entrada de Moros i Cristians" → Assigna com responsable a l'usuari *Responsable B*.


2. Afegeix diverses línies de participació de músics en ambdós actes.
3. Tanca la sessió (o obre una finestra d'incògnit) i entra al backend d'Odoo amb el compte de l'usuari *Responsable A*.
4. Navega fins al menú **Assistència**.

::: {admonition} Resultat esperat
:class: note
L'usuari *Responsable A* només ha de poder veure les files de participació que fan referència a la "Cercavila Falla Corea". Les línies de l'altre acte han d'haver desaparegut completament de la seua vista. Si tot és correcte, el responsable ja està llest per a entrar al formulari de cada músic de manera segura i gestionar qui va i qui es queda fora de la seua actuació!
:::

## Lògica de negoci en el servidor: El control de l'anul·lació en Python

Hem d'insistir molt en una regla d'or de la ciberseguretat en ERPs: **amagar un botó a la interfície gràfica NO és seguretat real**. Les vistes només controlen la visibilitat (frontend); la seguretat de veritat s'ha d'executar sempre al servidor (backend).

Si recordes la vista de formulari que vam preparar al punt 2, utilitzàrem l'atribut `invisible="estat != 'acceptat'"` per a controlar quan apareixia el botó d'anul·lar participacions. Això està molt bé per a guiar l'usuari, però si un músic maliciós utilitzara l'API d'Odoo, un script extern o el mode desenvolupador, podria llançar el mètode `action_anular` directament des del servidor i anul·lar la seua pròpia participació (o la d'un company) tot i tindre el botó ocult.

Per a evitar-ho, blindarem els mètodes de Python de la nostra lògica de negoci.

### Com comprovar els grups des de Python?

L'ORM d'Odoo ens proveeix d'una eina molt potent dins de l'entorn de l'usuari connectat (`self.env.user`). El mètode `has_group('ID_EXTERN_DEL_GRUP')` ens permet preguntar-li al servidor si l'usuari que està intentant clicar el botó té el rol necessari. Si no el té, llançarem una excepció de seguretat (`UserError`) que aturarà la transició a la base de dades immediatament.

### Blindatge del mètode `action_anular` (El teu torn!)

Obre el teu fitxer de models `models/participacio.py` (o on tinguies definit el model `agrupaciomusical.participacio`). Per a poder llançar errors controlats en Odoo, primer ens hem d'assegurar d'importar les excepcions del sistema a la primera línia del fitxer:

```python
from odoo.exceptions import UserError
```

Ara, busca el mètode `action_anular` que vas escriure en l'apartat 2. Has de modificar-lo per a afegir una condició: **Sols els usuaris que pertanguen al grup de Responsables o al grup de Directius poden anul·lar una participació.** Si un usuari amb el rol de Músic intenta executar el mètode, el sistema l'ha de frenar en sec.

Completa el codi seguint aquesta estructura:

```python
def action_anular(self):
    # 1. Comprovem si l'usuari actual NO és Directiu I TAMBOC és Responsable
    # Pista: has de posar l'ID extern complet: 'nom_del_teu_modul.id_del_grup'
    is_directiu = self.env.user.has_group('agrupaciomusical.group_directiu')
    is_responsable = self.env.user.has_group('agrupaciomusical.group_responsable')

    if not is_directiu and not is_responsable:
        # EL TEU TORN: Llança una excepció UserError amb un missatge d'avís corporatiu
        raise UserError("Acció denegada: Només la junta directiva o el responsable de l'acte poden anul·lar participacions.")

    # 2. Si passa la seguretat, s'executa la lògica de negoci normal
    for rec in self:
        rec.estat = 'anulat'

```

### Prova de "Correfoc a Benifairó" al Servidor

Com que hem modificat un fitxer de lògica en Python (`.py`), recorda que actualitzar el mòdul des de la interfície gràfica no és suficient. **És obligatori reiniciar el teu contenidor de Docker** perquè el servidor d'Odoo torne a compilar el codi Python.

Per a testejar que el backend està realment blindat:

1. Entra a l'Odoo amb un usuari que siga **Músic**.
2. Com que el músic té la seua regla de registre activa, només veu la seua participació activa. Si està en estat *Pendent*, veurà els botons d'**Acceptar** o **Rebutjar**. Clica en **Acceptar**.
3. En eixe moment, l'estat canvia a *Acceptat* i la vista amaga els botons gràcies a l'atribut `invisible`.
4. Si un alumne intentara forçar la crida al mètode `action_anular` (per exemple, canviant els atributs de la vista temporalment des de l'inspector web del navegador per a fer aparéixer el botó d'Anul·lar i clicar-lo), el servidor d'Odoo processarà la petició, botarà el codi Python, detectarà que l'usuari no té el grup de gestió necessari i pintarà una finestra emergent de bloqueig amb el text del teu `UserError`.

La teua aplicació ja no és només bonica pel frontend, ara està blindada des del cor del servidor!

## El Músic al Portal web: Integració d'usuaris externs

En la teoria ja es va introduir una distinció clau en l'ecosistema d'Odoo: els usuaris que gestionen l'empresa o associació des de dins (*usuaris interns*) davant d'aquells que només interactuen amb el sistema com a clients, proveïdors o, en el nostre cas, **músics de la colla** (*usuaris externs o de portal*).

Quan vam dissenyar el fitxer `security.xml` a l'apartat 3, vam fer que el grup de músics (`group_musics`) heretara directament de `base.group_portal`. En aquest apartat veurem la importància d'aquesta decisió arquitectònica i com canvia de manera radical l'experiència de l'usuari.

### Configurar un usuari com a Músic (Portal)

Per a comprovar el comportament del portal de manera real, hem de crear un usuari de proves que actue exclusivament com a músic exterior:

1. Entra a Odoo amb l'usuari administrador.
2. Navega fins a **Configuració → Usuaris i empreses → Usuaris**.
3. Crea un usuari nou anomenat, per exemple, *Joan Músic* i assigna-li un correu electrònic.
4. En la secció de **Drets d'accés**, comprova els teus grups de l'Agrupació Musical:
* Assegura't de marcar la casella **Músic de la colla**.
* Deixa completament en blanc o desmarcats els rols de *Responsable* i *Directiu*.


5. Guarda el registre i, a la barra superior, utilitza l'acció **Acció → Canviar contrasenya** per a establir-li una contrasenya senzilla (ex: `Joan12345`).

### L'impacte de `base.group_portal` (El canvi d'interfície)

Ara que tenim el nostre músic a punt, farem la prova definitiva d'accés. Tanca la teua sessió d'administrador o obre una finestra d'incògnit al teu navegador i accedeix a la URL base del teu entorn local d'Odoo. Introdueix les credencials del músic que acabes de crear (*Joan Músic*).

Fixa't en la pantalla. **Què ha passat amb la interfície plena de menús, aplicacions i l'entorn de gestió tradicional de l'ERP?**

Efectivament, l'usuari no ha entrat al backend d'Odoo. En lloc d'això, Odoo l'ha redirigit de manera automàtica a una pàgina web neta i corporativa: el **Portal de Client / Usuari Extern**. Això és la màgia d'haver utilitzat l'herència de `base.group_portal`.

::: {admonition} Idea clau
:class: tip
Un usuari de portal té prohibit l'accés a l'entorn de gestió intern (backend). Odoo, de manera nativa, renderitza els models que li permetem veure a través de vistes web (controladors del *Website*).
:::

**Checklist de verificació del portal**

Per a donar aquest apartat per superat, l'alumne ha de comprovar que l'usuari *Joan Músic*:

* No pot accedir a la URL `/web` (el sistema el redirigeix al frontend `/my`).
* Només veu les opcions del portal web autoritzades.
* Si s'ha implementat la integració web del mòdul, pot veure exclusivament les seues línies de participació actives gràcies al *Record Rule* que programàrem al punt 5.



## Automatització d'usuaris de prova amb Hooks

Provar la seguretat d'un ERP pot ser una tasca repetitiva: hem d'entrar com a Directiu, desconnectar-nos, entrar com a Músic, comprovar el portal, tornar a eixir, entrar com a Responsable... I si esborrem la base de dades o reinstal·lem el mòdul, hem de tornar a crear tots els usuaris de proves a mà.

Per a evitar-ho, utilitzarem un **post-init hook** d'Odoo. Com vàrem veure en la teoria, un *hook* és un mètode en Python que s'executa de manera automàtica en un moment concret del cicle de vida del mòdul (en aquest cas, immediatament després de prémer el botó d'instal·lar).

### Creació del fitxer `hooks.py`

Dins de la carpeta arrel del teu mòdul (al mateix nivell que el manifest o la carpeta `models/`), crea un fitxer anomenat exactament `hooks.py`.

Escriu el següent codi per a automatitzar l'assignació dels nostres usuaris de prova:

```python
# -*- coding: utf-8 -*-
from odoo import api, SUPERUSER_ID

def post_init_hook(env):
    """Mètode que s'executa automàticament després d'instal·lar el mòdul"""
    
    # 1. Obtenir les referències dels nostres grups de seguretat
    # NOTA: Assegura't que el prefix coincideix amb el nom de la teua carpeta
    group_dir = env.ref('agrupaciomusical.group_directiu')
    group_resp = env.ref('agrupaciomusical.group_responsable')
    group_music = env.ref('agrupaciomusical.group_musics')

    # 2. Llistat d'usuaris de prova que volem comprovar
    # El format és: ('login_de_l_usuari', grup_a_assignar)
    users_to_fix = [
        ('directiu_test', group_dir),
        ('responsable_test', group_resp),
        ('music_test', group_music),
    ]

    # 3. Bucle per a buscar els usuaris i assignar-los el seu rol automàticament
    for login, group in users_to_fix:
        user = env['res.users'].search([('login', '=', login)], limit=1)
        if user:
            # Si l'usuari ja existeix (perquè l'hem creat prèviament), 
            # li assignem el seu nou grup de la colla
            user.write({'groups_id': [(4, group.id)]})

```

### Registrar el Hook al Manifest i al Sistema

Perquè Odoo sàpiga que ha d'executar aquest script, hem de fer dos passos d'enllaç obligatoris:

1. **Al fitxer `__init__.py` arrel del mòdul:** Hem d'importar el fitxer que acabem de crear. Afegeix aquesta línia al final:
```python
from .hooks import post_init_hook
```


2. **Al fitxer `__manifest__.py`:** Hem de registrar el disparador indicant-li a Odoo quina funció ha de cridar en acabar la instal·lació. Afegeix aquesta clau al teu diccionari del manifest:
```python
'post_init_hook': 'post_init_hook',
```



### Comprovació

A partir d'aquest moment, si crees tres usuaris l'Odoo amb els logis `directiu_test`, `responsable_test` i `music_test`, en el mateix instant en què actualitzes o instal·les el mòdul de la colla des de la llista d'aplicacions, veuràs com el sistema els ha marcat les caselles dels rols corresponents de manera 100% automàtica. Ja ho tens tot llest per a fer les teues proves de seguretat sense perdre ni un segon!


## Conclusions

En acabar aquesta tasca, hem transformat una aplicació on "tothom ho veia tot" en un sistema empresarial blindat, modular i adaptat als estàndards moderns d'**Odoo 19**. Les lliçons clau que has d'endur-te d'aquest exercici són:

1. **La seguretat d'Odoo 19 és modular:** A diferència de versions anteriors, ja no lliguem els grups directament a les categories. Hem après a utilitzar els **Privilegis (`res.groups.privilege`)** com a capa intermediària, el que permet una gestió de rols molt més neta i escalable en projectes reals.
2. **El CSV és el "Què" i el Record Rule és el "Qui":** L'ACL (`ir.model.access.csv`) ens ha servit per a definir quines accions globals (llegir, crear, editar) té permés cada grup per taula. Després, les *Record Rules* ens han permés filar més prim i decidir, fila per fila, quins registres exactes pot veure cada usuari.
3. **Triangulació d'identitat amb `res.partner`:** En lloc de lligar els músics directament als usuaris, hem utilitzat la potència de l'herència d'Odoo. Comparar `music_id.partner_id` amb `user.partner_id.id` ens dona la versatilitat de gestionar músics que només són contactes i activar-los l'accés al portal només quan és necessari, mantenint la coherència amb el que hem vist en el bloc d'OWL.
4. **La seguretat gràfica és una il·lusió:** Fer que un botó siga `invisible` a la vista XML ajuda a guiar l'usuari, però no el frena si intenta fer trampa. La seguretat real s'ha de programar al servidor. Amb el blindatge en Python (`UserError` i `has_group`), hem assegurat que cap músic puga suplantar el rol del responsable i anul·lar participacions.
5. **Separació de rols (Backend vs Portal):** Gràcies a l'herència de `base.group_portal`, hem comprovat com Odoo pot canviar radicalment la interfície d'un usuari extern (músic) per a protegir l'entorn de gestió intern on treballen els responsables i la directiva.
6. **L'automatització amb Hooks:** Finalment, el *post-init hook* ens ha demostrat com els desenvolupadors d'Odoo poden automatitzar configuracions feixugues (com crear o assignar usuaris de prova) en el mateix instant en què el client instal·la l'aplicació.


## Entrega

Per a donar per finalitzada i avaluada aquesta tasca de seguretat, s'haurà de lliurar la següent documentació:

- **El codi font del mòdul**

* El directori complet del teu mòdul (per exemple, `agrupaciomusical` o el nom exacte que li hages donat a la carpeta) comprimit en un fitxer **ZIP**, o bé l'enllaç al teu repositori privat de **GitHub/GitLab** on es puga revisar el codi.
* Es verificarà especialment:
* L'ordre correcte de càrrega dels fitxers XML, CSV i la declaració del hook al fitxer `__manifest__.py`.
* La correcta definició de l'esquema de privilegis i rols en Odoo 19.
* La neteja del codi Python en el mètode de control d'anul·lació.



- **Document de memòria i verificació (PDF)**

Un únic document en format **PDF** que continga les següents evidències gràfiques (captures de pantalla de la teua instància local d'Odoo) degudament comentades:

1. **Evidència de Rols i Hooks:** Una captura de la pantalla d'**Configuració > Usuaris** on es veja que els teus usuaris de prova (`music_test`, `responsable_test`, `directiu_test`) tenen assignades les seues caselles de grup automàticament gràcies a l'execució del teu *post-init hook*.
2. **Evidència del Músic (Abans i després de la Record Rule):**
* Una captura de la pantalla **Assistència** iniciant sessió com a `music_test` *abans* d'aplicar la regla de registre (on es demostrarà que, tot i tindre permisos de lectura pel CSV, l'usuari comet l'error de veure les convocatòries de tots els companys).
* Una captura de la mateixa pantalla *després* d'activar la *Record Rule*, demostrant que el servidor ja filtra correctament i el músic només veu la seua pròpia fila activa.


3. **Evidència del Responsable d'Actes:** Una captura de la graella d'assistència iniciant sessió amb l'usuari `responsable_test`, on es puga comprovar visualment el triatge: l'usuari només veu els músics convocats als actes dels quals ell és responsable directe.
4. **Evidència del Directiu:** Una captura del backend demostrant que l'usuari administrador o directiu continua tenint una vista global absoluta de totes les participacions de la colla, verificant que les regles per fila no l'afecten.
5. **Evidència del Blindatge en Python:** Una captura de la finestra emergent d'error (`UserError`) que llança el servidor d'Odoo quan s'intenta forçar l'anul·lació d'una participació sense tindre el rol autoritzat.

- **Reflexió personal (Conclusions de l'alumne)**

Al final del teu document PDF, respon de manera breu a les següents preguntes a mode de valoració personal:

* Quina impressió tens ara sobre la flexibilitat de la seguretat en Odoo en comparació amb el que coneixies de les bases de dades tradicionals?
* T'ha resultat complex entendre com interactuen el fitxer CSV (ACL) i el fitxer XML (Record Rules) de manera combinada?
* Quin ha sigut el problema més gran amb el qual t'has trobat durant el desplegament de la tasca (errors de sintaxi als dominis, dependències al manifest, problemes amb els usuaris de prova) i com l'has aconseguit resoldre?
