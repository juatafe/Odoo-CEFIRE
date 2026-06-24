# Portal de la colla

## Context de la pràctica
La colla de dolçaines i tabals vol que els músics puguen consultar les seues dades de les futures actuacions, sense necessitat d'accedir al backend administratiu d'Odoo.  
Per a fer-ho possible, partirem del mòdul ja existent `agrupaciomusical` i dels coneixements adquirits sobre controladors web, QWeb i la llibreria OWL.  

::: {admonition} Objectius d’aprenentatge
:class: tip
- Heretar i modificar plantilles QWeb del portal d'Odoo.
- Crear un controlador web amb rutes HTTP i JSON.
- Connectar el controlador amb els models d'Odoo per a llegir recordsets.
- Combinar l'estructura estàtica de QWeb amb la reactivitat de components OWL al frontend.
- Configurar correctament el manifest (data i assets) en Odoo 19.
:::

::: {admonition} Requisits previs
:class: note
- Mòdul `agrupaciomusical` instal·lat.
- Tindre creats i amb dades almenys els models d'actes i el model de participacions.
- Usuaris de prova registrats amb accés correcte al Portal. De moment no calen permisos especials encara.
:::

## Afegir l'enllaç de la colla al portal principal
**Objectiu:** Afegir un botó visual dins de la pàgina de benvinguda del portal d'usuari que redirigisca el músic cap a la seua secció.
**Instruccions:**
1) Crea el fitxer `views/portal_templates.xml` (si no el tenies creat ja).
2) Hereta la plantilla base del portal d'Odoo (`portal.portal_my_home`).
3) Utilitza una expressió `xpath` (preferiblement buscant per classe amb `contains`) per a introduir un enllaç (`<a>`) amb estil de botó Bootstrap
4) L'enllaç ha d'apuntar cap a la ruta `/my/actuacionsfutures`.

::: {admonition} Pista
:class: tip
Si afegeixes **més d’un botó** al portal, és recomanable **agrupar-los dins d’un `div`** amb classes de Bootstrap per a millorar la presentació.

Per exemple:

* `d-flex` → col·loca els botons en una mateixa fila
* `mt-3` → afegeix marge superior
* `gap-2` → crea espai entre els botons

Així els botons queden **alineats, separats i visualment més clars**, sense necessitat de CSS personalitzat.

:::
<!-- Exemple (QWeb):
```xml
<odoo>
    <template id="portal_my_home_inherit" inherit_id="portal.portal_my_home" name="Portal Home - La Morralla">
        <xpath expr="//div[contains(@class, 'o_portal_my_home')]" position="inside">       
            <a href="/my/actuacionsfutures" class="btn btn-primary mt-3">Les meues actuacions</a>
        </xpath>
    </template>
</odoo>
-->

Actualitza el manifest per a carregar el fitxer:
```python
'data': [
    # ...altres fitxers...
    'views/portal_templates.xml',
],
```

**Verificació:**
- Actualitza el mòdul (`-u agrupaciomusical`) i obri `/my`, ha d’aparéixer el nou botó "Les meues actuacions".
- En clicar-lo, ha de retornar un **error 404** de pàgina no trobada. Això és correcte, ja que encara no hem programat el controlador que escolta eixa ruta.
  
```{image} /_static/assets/img/T6_prac8_PortalPersonalitzat.png
:alt: Vista frontend pàgina personalitzada amb botó
:class: img-fluid
:align: center
:width: 100%
```

## Crear el controlador HTTP i la pàgina QWeb base

**Objectiu:** Crear la ruta en Python per a interceptar la URL i renderitzar una pàgina web buida integrada amb el disseny (layout) original d'Odoo.

**Instruccions:**
1) Al fitxer `controllers/controllers.py`, crea una classe controladora que herete de `http.Controller`.
2) Defineix el mètode encarregat de gestionar la ruta `/my/actuacionsfutures` fent ús del decorador `@http.route` amb configuració per a frontends (`website=True`) i accés restringit a usuaris registrats (`auth='user'`).

Exemple (Python):
```python
from odoo import http
from odoo.http import request

class AgrupacioMusicalPortal(http.Controller):

    @http.route('/my/actuacionsfutures', type='http', auth='user', website=True)
    def portal_actuacionsfutures(self, **kw):
        # Primer pas: Renderitzem la pàgina base sense dades dinàmiques encara
        return request.render('agrupaciomusical.portal_actuacionsfutures_page', {})
```

3) Crea el fitxer `views/portal_pages.xml` i defineix l'estructura HTML base fent un `t-call="portal.portal_layout"` per a mantindre la capçalera i peu de pàgina de la colla.  
<!-- Exemple (QWeb):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<odoo>
    <template id="portal_actuacionsfutures_page" name="Portal Actuacions Futures Page">
        <t t-call="portal.portal_layout">
            <div class="container mt-4">
                <h2>Les meues dades de la colla</h2>
                <p class="text-muted">Aquesta és una pàgina de prova del portal.</p>               
Ací s'injectarà el component OWL en els passos següents                
                <a href="/my" class="btn btn-secondary mt-3">Tornar al portal</a>
            </div>
        </t>
    </template>
</odoo>
``` -->

Recorda afegir `views/portal_pages.xml` al manifest del mòdul.

**Verificació:**
- Reinicia el servidor d'Odoo (necessari sempre que es modifica codi Python) i actualitza el mòdul.  
- En clicar el botó del portal, la pàgina s'ha de carregar mostrant el títol formatat correctament i sense errors.  

```{image} /_static/assets/img/T6_prac8_actuacionsfutures.png
:alt: Vista frontend pàgina personalitzada bàsica
:class: img-fluid
:align: center
:width: 100%
``` 
## Crear el controlador JSON (Llegir les dades del backend)
**Objectiu:** Crear una ruta de tipus JSON que actue com una API interna. Serà l'encarregada de buscar en la base dades les participacions futures del músic connectat i retornar-les en un format de llista/diccionari que el navegador puga entendre.  
**Instruccions:**
- Al mateix controlador de Python (`controllers/controllers.py`), afig una nova ruta configurada amb `type='json'`.
- Recupera l'usuari actual mitjançant `request.env.user`.
- Utilitza un `.search()` sobre el model de participacions filtrant per l'ID de contacte del músic (`partner_id`) i assegurant que la data de l'acte siga igual o posterior al dia de hui.
- Retorna les dades mapejades en estructures de dades pures (JSON)

Exemple (Python):
```python
@http.route('/my/actuacionsfutures/json', type='json', auth='user')
def actuacionsfutures_json(self):

    user = request.env.user        
    participacions = 
        request.env['agrupaciomusical.participacio'].sudo().search([
        ('music_id.partner_id', '=', user.partner_id.id),
        ('acte_id.data', '>=', date.today())
    ])

    return [
        {
            'id': p.id,
            'acte': p.acte_id.name,
            'data': p.acte_id.data.strftime('%d/%m/%Y'),
            'hora': p.acte_id.hora_inici.strftime('%H:%M') 
                if p.acte_id.hora_inici else '',
        }
        for p in participacions
    ]
```
El `request.env` és una manera segura d’accedir als models d’Odoo des d’un controlador web i amb .search() busquem tots els registres, en el nostre cas filtrant per el id de user i la data de hui. L’ús de `sudo()` és només temporal i didàctic. Més endavant veurem com substituir-ho per permisos i regles adequades. Ara ens permet accedir als registres sense restriccions de permisos, cosa que és útil en aquest context de portal on els usuaris poden no tenir permisos complets. El resultat de la cerca es passa a la plantilla QWeb com una col·lecció d'objectes `agrupaciomusical.participacions` que està disponible a la plantilla per a ser mostrada. 

## Desenvolupar el Component OWL (Lògica de Frontend)

**Objectiu:** Crear el component JavaScript mitjançant la llibreria OWL d'Odoo 19 per a fer la crida asíncrona (RPC) al controlador JSON, emmagatzemar l'estat i controlar la reactivitat.  

**Instruccions:**
1) Crea l'estructura de carpetes dins del teu mòdul: `static/src/js/`.
2) Crea el fitxer `static/src/js/actuacionsfutures_component.js`.
3) Importa les ferramentes necessàries de la llibreria d'OWL d'Odoo i registra el component en la categoria `public_components` per a fer-lo accessible des de les vistes web.  

<!-- Exemple:
```{code-block} javascript
/** @odoo-module **/

import { Component, useState, onWillStart } from "@odoo/owl";
import { registry } from "@web/core/registry";
import { rpc } from "@web/core/network/rpc";

export class ActuacionsFuturesComponent extends Component {

    static template = "agrupaciomusical.actuacionsfutures_template";

    setup() {
        this.state = useState({ actes: [] });

        onWillStart(async () => {
            this.state.actes = await rpc("/my/actuacionsfutures/json");
            console.log("Actuacions del músic carregades:", this.state.actes);
        });
    }
}

registry.category("public_components").add(
    "agrupaciomusical.ActuacionsFuturesComponent",
    ActuacionsFuturesComponent
);
``` -->


## Crear la Plantilla d'OWL i enllaçar amb QWeb
**Objectiu:** Definir la plantilla XML reactiva del component que renderitzarà les dades en bucle (`t-foreach`) i cridar el component des de la pàgina principal de la pràctica.
**Instruccions:**
1) Crea la carpeta `static/src/xml/` dins del teu mòdul.
2) Crea el fitxer `static/src/xml/actuacionsfutures_template.xml`.
3) Dissenya el llistat utilitzant la sintaxi d'OWL (`owl="1"` i l'ús obligatori de `t-key`) amb classes Bootstrap netes (`list-group`, `card`, etc.).  
4) Inyecta el component en QWeb: Obre el fitxer `views/portal_pages.xml` que vas crear al Pas 2 i afig l'etiqueta `<owl-component>` en l'espai reservat per a instanciar el component JS de forma automàtica:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<odoo>
    <template id="portal_actuacionsfutures_page" 
        name="Portal Actuacions Futures Page">
        <t t-call="portal.portal_layout">
            <div class="container mt-4">
                <h2>Les meues dades de la colla</h2>          
                <!-- Cridem el component OWL registrat mitjançant el seu nom públic -->
                <owl-component name="agrupaciomusical.ActuacionsFuturesComponent"/>              
                <a href="/my" class="btn btn-secondary mt-3">
                    Tornar al portal</a>
            </div>
        </t>
    </template>
</odoo>
```

## Declarar els Assets en el Manifest d'Odoo 19
Recorda que cal indicar a Odoo que ha de compilar i carregar els fitxers de JavaScript i XML de frontend en el bundle global del portal. Per això obre el teu fitxer `__manifest__.py` i afegeix la secció `assets` apuntant exactament cap als teus fitxers de frontend (fixa't que l'XML d'OWL es declara ací i **NO** en l'apartat `data`):  

```
'data': [
    ...
    'views/portal_pages.xml',
    'views/portal_templates.xml',
],    
'assets': {
    'web.assets_frontend': [
        'agrupaciomusical/static/src/js/actuacions.js',
        'agrupaciomusical/static/src/xml/actuacions.xml',
    ],
},
```

## Verificació Final i Proves

Abans de donar la pràctica per finalitzada, realitza les següents comprovacions en el teu entorn:
- El botó de "Les meues actuacions" apareix en la home del portal (`/my`).
- En clicar-lo, obre correctament la URL `/my/actuacionsfutures` sense errors web.
- La pàgina manté el disseny original d'Odoo gràcies al layout.
- El component asíncron funciona.
- Quan el músic seleccionat té registres creats en la base de dades, apareix el llistat d'actes; i quan no en té, es mostra correctament el bloc informatiu d'avís. 

## Bones pràctiques, trucs i errors comuns

::: {admonition} Bones pràctiques
:class: tip
- Hereta plantilles i modifica amb `xpath`; no copies la plantilla sencera.
- Prefixa els `id` de plantilles amb el teu mòdul (`agrupaciomusical.*`).
- Afig sempre els fitxers al manifest.
- Reinicia Odoo després de canvis en controladors o manifest.
- Recarrega el mòdul després de canvis en plantilles amb:
    > `docker compose exec nomservei odoo -u nomModul -d nomBd --stop-after-init`
:::

::: {admonition} Depuració ràpida
:class: info
- Activa Mode Desenvolupador → "Tècnic" → "Vistes"  per localitzar `xml_id`.
- Revisa el log si tens errors 500.
- Actualitza el mòdul i observa els canvis o possibles errors.
:::

::: {admonition} Errors típics
:class: warning
- “QWeb2: template not found”: el `xml_id` no existix o no s’ha carregat.
- 404 en `/my/actuacionsfutures`: falta el controlador o el `href`.
- Duplicació d’`id` en templates: assegura unicitat per mòdul.
:::

## Entrega

Cal lliurar un fitxer amb::

- El codi font del mòdul `agrupaciomusical` complet i comprimit en format `.zip`,
- Un document en format `.pdf` que continga:
  - Captura de pantalla de la secció d'accés en `/my` amb el nou botó integrat.
  - Captura de pantalla de la nova pàgina amb el component d'OWL mostrant dades de proves de diferents actuacions. Recorda omplir el mòdul amb actes i músics abans de fer la captura. 
  - Una breu explicació del treball realitzat. Pots realitzar modificacions addicionals per mostrar camps extra o millorar l’estil. 