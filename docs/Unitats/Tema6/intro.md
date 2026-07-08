## Introducció 
El frontend d’Odoo és la part de l’aplicació que els usuaris finals veuen i amb la qual interactuen.
Inclou totes les pàgines web, el portal d’usuari, la tenda en línia i altres interfícies orientades a
l’usuari que no formen part del backend administratiu d’Odoo. El frontend està dissenyat per a ser
atractiu, fàcil d’utilitzar i accessible des de qualsevol dispositiu.

## Tecnologies del frontend en Odoo 19
En Odoo 19, el desenvolupament del frontend es basa principalment en dues tecnologies:
- **QWeb**, que permet crear les pàgines web a partir de plantilles XML
- **OWL** (Odoo Web Library), que s’utilitza per a afegir funcionalitat dinàmica amb JavaScript
Ambdues es complementen i permeten crear interfícies web completes, des de pàgines simples fins a aplicacions més dinàmiques.

```{image} /_static/assets/img/T6_esquemaQWebOwl.png
:alt: Esquema QWeb vs OWL
:class: img-fluid
:align: center
:width: 40%
```

### QWeb
QWeb és el motor de plantilles utilitzat per Odoo per generar contingut HTML a partir de dades del backend. Està basat en XML i permet definir l’estructura de les pàgines web mitjançant templates reutilitzables.
S’utilitza principalment en:
- El portal d’usuari (/my)
- Les pàgines web públiques
- La tenda online
- Informes (factures, pressupostos, etc.)

El funcionament de QWeb es basa en la combinació de plantilles i dades. El backend (mitjançant un controlador) proporciona la informació necessària, i QWeb s’encarrega de representar-la en forma de pàgina web.
Per exemple, permet:
- Mostrar llistes de registres
- Substituir parts d’una plantilla existent (herència amb XPath)
- Crear noves pàgines web

En Odoo 19, QWeb continua sent la base del frontend, especialment per a la generació inicial de les pàgines.

### OWL (Odoo Web Library)
OWL és el framework JavaScript modern d’Odoo, utilitzat per a crear components dinàmics en el frontend.
A diferència de QWeb, que genera HTML des del backend, OWL funciona en el navegador i permet:
- Actualitzar la informació sense recarregar la pàgina
- Gestionar estat (dades en memòria)
- Crear components reutilitzables
- Fer crides al servidor de forma asíncrona (JSON)

OWL és especialment útil quan es necessiten interfícies interactives o actualitzades en temps real.

```{image} /_static/assets/img/T6_esquemaOWL.png
:alt: Esquema OWL
:class: img-fluid
:align: center
:width: 29%
```

### Relació entre QWeb i OWL
En Odoo 19, el frontend combina ambdues tecnologies:
- **QWeb** s’encarrega de la construcció inicial de la pàgina
- **OWL** s’utilitza per a afegir comportament dinàmic

El flux habitual és:
```bash
Controlador → QWeb (estructura) → OWL (dinàmica)
```

Per exemple:
- QWeb crea una pàgina del portal
- OWL carrega dades addicionals (com una llista d’actuacions) sense recarregar

En general, cada tecnologia s'utilitza per a coses diferents:
- **QWeb** s’utilitza per a:
    - Crear pàgines
    - Mostrar informació de forma estàtica o simple
    - Modificar el portal existent
- **OWL** s’utilitza per a:
    - Interfaces dinàmiques
    - Actualitzacions en temps real
    - Interaccions avançades amb l’usuari

En aquest capítol es treballarà amb ambdues tecnologies, començant per QWeb per a modificar el portal d’usuari i evolucionant cap a una implementació amb OWL per mostrar les actuacions de cada músic de forma dinàmica.

## QWeb en Odoo
Per a crear o modificar una vista frontend en Odoo, necessitem els següents components bàsics:
- Un **mòdul** d’Odoo
- Un **fitxer XML** amb una plantilla QWeb que heretarà o crearà la vista.
- Un **controlador** que gestione les rutes i les dades. Recorda que Odoo utilitza model vistacontrolador (MVC). El controlador és l’encarregat de gestionar les rutes i passar les dades a la vista.

En Odoo 19, la modificació de vistes del frontend continua basant-se principalment en QWeb, especialment quan es tracta de modificar pàgines existents com el portal d’usuari.
No obstant això, quan es requereix un comportament més dinàmic (com actualitzar informació sense recarregar la pàgina), es pot complementar amb components OWL, que permeten realitzar crides al servidor i actualitzar la interfície en temps real.
Així, podem distingir dos casos:
- Modificacions bàsiques → només amb QWeb
- Funcionalitats dinàmiques → QWeb + OWL

Abans de canviar res al frontend, identifica:
- Quin mòdul ho defineix
- Quin template QWeb s’està usant.

Alguns dels principals punts del sistema són:
- Portal d’usuari → mòdul `portal` → plantilles com `portal.portal_my_home`, `portal.portal_layout`
- Web pública → mòdul `website` → plantilles com `website.layout` i templates associats
- Tenda online → mòdul `website_sale` → plantilles com `website_sale.product`

Aquest pas és fonamental, ja que permet localitzar correctament el punt on aplicar la modificació.

:::{note} 
Els noms exactes de les plantilles poden variar segons la versió d’Odoo i els mòduls instal·lats, per això és recomanable utilitzar el mode desenvolupador per identificar-les correctament.
:::

Suposem que volem modificar la pàgina principal del portal d’usuari. Hauríem de buscar la plantilla QWeb corresponent, que en aquest cas és la plantilla del portal definida dins del mòdul `portal`
En la majoria dels casos, aquesta pàgina es genera a partir de la plantilla `portal.portal_my_home`, que és la responsable de la vista accessible des de `/my`. A partir d’aquesta plantilla base, es poden realitzar modificacions mitjançant herència, sense alterar el codi original.

La següent imatge mostra com es veu la pàgina principal del portal d’usuari per defecte:

```{image} /_static/assets/img/T6_vistaFrontMy.png
:alt: Vista frontend portal d'usuari
:class: img-fluid
:align: center
:width: 70%
```

En QWeb, les plantilles s’identifiquen amb l’atribut `id`. Aquest identificador segueix habitualment l’estructura: `nom_module.nom_template`. Per exemple, en la plantilla `portal.portal_my_home`, `portal` és el nom del mòdul i `portal_my_home` és l’identificador de la plantilla. 

Per modificar una plantilla existent, es crea una nova plantilla que hereta de l’original mitjançant l’atribut `inherit_id`.

Exemple:
```xml
<template id="portal_my_home_inherit" inherit_id="portal.portal_my_home">
    ...
</template>
``` 
Açò indica que:
- estem creant una nova plantilla (`portal_my_home_inherit`)
- que hereta el contingut de `portal.portal_my_home`
- i que podrà modificar-lo sense substituir-lo completament

Aquest mecanisme és fonamental en Odoo, ja que permet personalitzar el sistema de manera modular i segura.

Una vegada entesos aquests conceptes, es pot aplicar la modificació d’una plantilla QWeb en un cas real. En el següent apartat es mostrarà com modificar la pàgina principal del portal d’usuari pas a pas.


## Exemple pràctic: Modificar la pàgina principal del portal d’usuari
1. **Identificar la plantilla**: Com hem vist abans, la plantilla que volem modificar és la que mostra el portal. Així que partim de  `portal.portal_my_home`, i veiem que en esta plantilla no es troba l'element `h3` que volem modificar. Este element es troba en la plantilla `portal.portal_layout`. 
2. **Crear un mòdul personalitzat**: Si encara no tens un mòdul personalitzat, crea’n un nou per a les teues modificacions.
3. **Crear el fitxer XML**: Dins del teu mòdul, crea un fitxer XML per a la plantilla QWeb. Per exemple, `views/portal_templates.xml` (recorda afegir-lo al fitxer de manifest).
4. **Modificar la plantilla**: Afegeix el codi XML per a modificar la plantilla. Per exemple, per a afegir un missatge de benvinguda personalitzat:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<odoo>
    <template id="portal_my_layout_inherit" inherit_id="portal.portal_layout" name="Portal Layout - Customizations">
        <xpath expr="//div[hasclass('o_portal_wrap')]//h3" position="replace">       
            <h3 class="my-3">Benvingut al teu portal personalitzat!</h3>
        </xpath>
    </template>
</odoo>
```

Anem a desglossar aquest codi:

L’expressió XPath indica **exactament quin element del portal volem modificar**.

```xml
<xpath expr="//div[hasclass('o_portal_wrap')]//h3"
```

- `//`  Indica que la cerca es fa **des de qualsevol punt del document XML**, no només des del node arrel immediat.

- `hasclass(...)` permet seleccionar elements que contenen una classe CSS concreta. És una expressió XPath estàndard i més robusta davant canvis en l’estructura HTML.

- `/h3`  Selecciona l’element `<h3>` que es troba **dins** d’aquest `<div>`.

Una vegada localitzat l’element, la instrucció:

```xml
position="replace"
```

Indica que **el contingut seleccionat serà reemplaçat completament** pel nou contingut que definim a la plantilla. En aquest cas, l’etiqueta `<h3>` original del portal és substituïda pel nostre missatge de benvinguda personalitzat.

:::{note} 
👉 En resum, **busquem un element concret del portal i el substituïm pel nostre contingut**, sense modificar la plantilla original.
:::

1. **Actualitzar el mòdul**: Una vegada hages fet les modificacions, actualitza el teu mòdul per a aplicar els canvis.
2. **Provar els canvis**: Accedeix al portal d’usuari per a veure els canvis aplicats.

Amb aquests passos, hauràs modificat amb èxit la pàgina principal del portal d’usuari utilitzant QWeb en Odoo com es pot observar en la següent imatge:

```{image} /_static/assets/img/T6_VistaFrontMyPersonalitzada.png
:alt: Vista frontend portal d'usuari
:class: img-fluid
:align: center
:width: 80%
```
:::{note} 
En este exemple no utilitzem controlador perquè no estem creant cap pàgina nova ni cap ruta nova. Només estem modificant una vista que Odoo ja genera i a la qual ja li passen les dades necessàries. El controlador serà necessari quan vulguem mostrar informació pròpia del nostre mòdul o crear pàgines noves. 
:::

Resulta imprescindible conéixer bé l'estructura HTML i les classes CSS que Odoo utilitza en les seves plantilles QWeb per a poder fer modificacions efectives i precises. Això ens permetrà personalitzar l’aspecte i la funcionalitat del frontend segons les necessitats específiques del nostre projecte. A la imatge següent es mostra la vista del portal d’usuari amb l'inspector d'elements del navegador obert, permetent veure l'estructura HTML i les classes CSS associades:

```{image} /_static/assets/img/T6_VistaFrontMyLayout.png
:alt: Vista frontend portal d'usuari
:class: img-fluid
:align: center
:width: 80%
```

Quan analitzem la plantilla portal.portal_my_home, podem observar que no conté tota l’estructura HTML de la pàgina, sinó que reutilitza una altra plantilla mitjançant la instrucció:
```xml
<t t-call="portal.portal_layout">
```
Açò significa que:
- `portal_layout` defineix l’estructura general (header, footer, contenidors)
- `portal_my_home` només defineix el contingut específic de la pàgina del portal

Per tant, la pàgina final que veu l’usuari és el resultat de la combinació de diverses plantilles.

:::{note} 
En Odoo, les plantilles QWeb es construeixen de manera modular mitjançant la reutilització d’altres plantilles amb t-call, la qual cosa permet separar l’estructura general del contingut específic de cada pàgina.
:::

## Creem un controlador per a una pàgina nova
En aquest apartat, crearem un controlador senzill per a una pàgina nova en el frontend d’Odoo. Això ens permetrà entendre com funcionen els controladors i com es poden utilitzar per a gestionar rutes i mostrar contingut personalitzat.

Al portal de l’usuari (/my) apareix un enllaç nou anomenat "Pàgina Personalitzada". Quan l’usuari faça clic en aquest enllaç, volem que es mostre una pàgina nova amb un missatge de benvinguda. Quan l’usuari fa clic:
    - Odoo crida un controlador
    - El controlador retorna una plantilla QWeb

Així es veu clar:
```
👉 vista XML → controlador → ruta web
```

Primer afegirem el link a la pàgina principal del portal d’usuari. Per a això, heretarem la plantilla `portal.portal_my_home` i afegirem l’enllaç. Ho farem a un fitxer XML dins del nostre mòdul personalitzat, per exemple, `views/portal_templates.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<odoo>
    <template id="portal_my_home_inherit" 
        inherit_id="portal.portal_my_home" 
        name="Portal Home - Customizations">
        <xpath expr="//div[hasclass('o_portal_my_home')]" position="inside">       
            <a href="/my/custom_page" class="btn btn-primary mt-3">Pàgina Personalitzada</a>
        </xpath>
    </template>    
</odoo>
``` 

```{image} /_static/assets/img/T6_VistaPersonalitzadaBoto.png
:alt: Vista frontend pàgina personalitzada
:class: img-fluid
:align: center
:width: 100%
```

 En fer clic en aquest botó, l’usuari serà redirigit a la ruta `/my/custom_page`. Aquesta ruta serà gestionada pel controlador que crearem a continuació. Com ara no hi ha cap controlador definit per a aquesta ruta, Odoo mostrarà una pàgina d'error 404 com es veu a la imatge següent:
```{image} /_static/assets/img/T6_VistaPersonalitzadaNoBot.png
:alt: Vista frontend pàgina personalitzada no va a cap lloc
:class: img-fluid
:align: center
:width: 80%
```
Ara, crearem el controlador que gestionarà la ruta `/my/custom_page` i retornarà la plantilla QWeb corresponent. El controlador es defineix en un fitxer Python dins del nostre mòdul personalitzat, per exemple, `controllers/main.py`:

## Estructura del controlador

Quan el scaffold crea el mòdul, et deixa això:
```bash

├── controllers/
│   ├── __init__.py
│   └── controllers.py
```

El codi que t’ha creat scaffold és només un exemple, no fa res útil per al nostre cas. El podem esborrar quasi tot i quedar-nos amb l’estructura.

```python
# -*- coding: utf-8 -*-
from odoo import http
from odoo.http import request

```
Ací simplement importem les classes i mètodes necessaris per a definir el nostre controlador. La classe `http.Controller` és la base per a crear controladors en Odoo, i `request` ens permet accedir a la informació de la petició HTTP i als serveis d’Odoo, així com renderitzar plantilles QWeb.

## Definició del controlador del portal
Ara sí: creem un controlador que gestione la ruta /my/custom_page i retorne una plantilla QWeb.

Afegim el codi complet:

```{code-block} python

# -*- coding: utf-8 -*-
from odoo import http
from odoo.http import request

class AgrupacioMusicalPortal(http.Controller):
    @http.route("/my/custom_page", type="http", auth="user", website=True)
    def custom_page(self, **kwargs):
        #**kwargs és un diccionari que conté els paràmetres que es passen a la ruta. Per exemple, si la ruta fos /my/custom_page?name=John, kwargs seria {'name': 'John'}.
        return request.render("agrupaciomusical.portal_custom_page")
```

Amb aquest codi, hem creat un controlador anomenat `AgrupacioMusicalPortal` que gestiona la ruta `/my/custom_page`. Quan un usuari autenticat accedeix a aquesta ruta, el mètode `custom_page` es crida i retorna la renderització de la plantilla QWeb `agrupaciomusical.portal_custom_page`. Aquesta plantilla serà la que es mostrarà a l’usuari quan accedisca a la ruta.


:::{admonition} Explicació del codi
:class: note
Anem a desglossar aquest codi:

`class AgrupacioMusicalPortal(http.Controller):`  Definim una nova classe anomenada `AgrupacioMusicalPortal` que hereta de `http.Controller`. Aquesta classe contindrà els nostres mètodes de controlador.

`@http.route('/my/custom_page', type='http', auth='user', website=True)`  Aquest és un decorador que defineix una ruta web. Els paràmetres són:
    - `'/my/custom_page'`: La ruta que volem gestionar.
    - `type='http'`: Indica que aquesta ruta és una sol·licitud HTTP normal.
    - `auth='user'`: Indica que l’usuari ha d’estar autenticat per a accedir a aquesta ruta.
    - `website=True`: Indica que aquesta ruta és per al frontend del lloc web.

`def custom_page(self, **kwargs):`  Definim un mètode anomenat `custom_page` que s’executarà quan un usuari accedisca a la ruta `/my/custom_page`.

`return request.render('agrupaciomusical.portal_custom_page')`  Aquest mètode retorna la renderització d’una plantilla QWeb anomenada `agrupaciomusical.portal_custom_page`. Aquesta plantilla serà la que es mostrarà a l’usuari quan accedisca a la ruta. 

`agrupaciomusical` és el nom del nostre mòdul personalitzat i `portal_custom_page` és l’identificador de la plantilla QWeb que crearem a continuació.
:::

## Creació de la plantilla QWeb per a la pàgina personalitzada
Ara que tenim el controlador definit, necessitem crear la plantilla QWeb que es mostrarà quan l’usuari accedisca a la ruta `/my/custom_page`. Crearem aquesta plantilla afegint-la al fitxer XML dins del nostre mòdul personalitzat, per exemple, `views/portal_templates.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<odoo>
    <template id="portal_custom_page" name="Custom Page">
    <t t-call="portal.portal_layout">
        <div class="container mt-5">
            <h1>Pàgina Personalitzada</h1>
            <p>Benvingut a la teua pàgina personalitzada al portal d'usuari!</p>
            <a href="/my" class="btn btn-secondary">
                Tornar al portal
            </a>
        </div>
    </t>
    </template>    
</odoo>
```
Anem a desglossar aquest codi: 
- `<template id="portal_custom_page" name="Custom Page">`  Definim una nova plantilla QWeb amb l’identificador `portal_custom_page` i el nom `Custom Page`.
- `<t t-call="portal.portal_layout">`  Aquesta línia indica que la nostra plantilla utilitzarà el disseny base del portal d’usuari definit en la plantilla `portal.portal_layout`. Això ens permet mantenir la coherència visual amb la resta del portal.
- `<div class="container mt-5">`  Creem un contenidor amb una classe CSS per a afegir marges superiors.
- `<h1>Pàgina Personalitzada</h1>`  Afegim un títol a la pàgina.
- `<p>Benvingut a la teua pàgina personalitzada al portal d'usuari!</p>`  Afegim un paràgraf de benvinguda.
- `<a href="/my" class="btn btn-secondary">Tornar al portal</a>`  Afegim un botó que permet a l’usuari tornar al portal d’usuari.     
- `</t>`  Tanquem la crida al disseny base del portal.
- `</template>`  Tanquem la definició de la plantilla.

Recorda que ara no sols cal actualitzar el mòdul perquè els canvis tinguen efecte, sinó que també has de reiniciar el servidor d’Odoo per a assegurar-te que el nou controlador i la nova plantilla QWeb es carreguen correctament. Sempre que modifiques codi python, és necessari reiniciar el servidor perquè els canvis es reflecteixen.
```{image} /_static/assets/img/T6_VistaPersonalitzadaCustom.png
:alt: Vista frontend pàgina personalitzada
:class: img-fluid
:align: center
:width: 80%
``` 

Amb aquests passos, hem creat un controlador senzill que gestiona una ruta nova en el frontend d’Odoo i retorna una plantilla QWeb personalitzada. Això ens permet mostrar contingut específic als usuaris quan accedeixen a aquesta ruta. Queda clar, per tant, com funciona el frontend en Odoo, QWeb defineix què es mostra, el controlador decideix quan i com, i la ruta connecta l’usuari amb la pàgina. 

## OWL (Odoo Web Library)
En els apartats anteriors s’ha treballat amb QWeb per a generar pàgines del frontend. Aquest enfocament permet crear i modificar vistes, però té una limitació: el contingut es genera en el servidor i cal recarregar la pàgina per actualitzar-lo.
Per a superar aquesta limitació, Odoo 19 incorpora `OWL (Odoo Web Library)`, un framework JavaScript que permet crear components dinàmics executats en el navegador.
A diferència de QWeb:
- QWeb genera el HTML des del servidor
- OWL permet actualitzar la informació sense recarregar la pàgina

OWL s’utilitza quan es necessita:
- mostrar dades dinàmiques
- actualitzar informació sense recarregar
- crear interfícies més interactives

## Exemple pràctic: Mostrar actuacions amb OWL
En els apartats anteriors hem utilitzat QWeb per a generar pàgines del frontend. Aquest enfocament permet crear i modificar vistes, però presenta una limitació: el contingut es genera en el servidor i, si les dades canvien, és necessari recarregar la pàgina per a veure els canvis.

Ara anem a utilitzar la tecnologia de OWL per a carregar i mostrar una llista d’actuacions en el portal d’usuari de manera dinàmica.
Aquest exemple és introdutori i té com a finalitat comprendre:
- Com fer una crida al servidor des del navegador
- Com gestionar dades amb OWL
- Com mostrar la informació en una plantilla

### Preparar la pàgina amb QWeb
El primer pas és preparar el portal (QWeb), i per això tenim que crear una nova plantilla que herete de la plantilla `portal.portal_my_home` al igual que hem fet en els apartats d'abans. Actualitza el fitxer `views/portal_templates.xml` i afig el següent codi:

```xml
<template id="portal_actuacions_page">
    <t t-call="portal.portal_layout">
        <div class="container mt-4">
            <h2>Actuacions</h2>
                <owl-component name="agrupaciomusical.ActuacionsComponent"/>
        </div>
    </t>
</template>
```
També hem d'afegir el botó per a accedir a esta nova plantilla:
```xml
    <template id="portal_my_home_inherit" inherit_id="portal.portal_my_home" name="Portal Home - Customizations">
        <xpath expr="//div[hasclass('o_portal_my_home')]" position="inside">       
            <a href="/my/actuacions" class="btn btn-primary mt-3">Actuacions</a>
        </xpath>
    </template>
```
L’etiqueta `<owl-component>` permet inserir un component OWL dins de QWeb.

### Crear una pàgina del portal
A continuació, definim una ruta en el controlador per a que retorne la pàgina específica del portal on s'integrarà el component OWL.
Per això hem d'editar el fitxer `controllers/controllers.py` i afegir el codi:
```{code-block} python
    @http.route('/my/actuacions', type='http', auth='user', website=True)
    def portal_actuacions(self, **kw):        
        return request.render('agrupaciomusical.portal_actuacions_page', {})
```

Este codi és el mateix de l'apartat 6.7 on hem definit el controlador del portal, però per a la nova pàgina on visualitzarem les actuacions. Així que també hem de tenir en compte no oblidar-nos dels imports i de la definició de la classe.


### Crear el component OWL
Ara és quan definim el component OWL que gestionarà les dades en el navegador. Per això cal crear un nou fitxer en `static/src/js/` anomenat `actuacions.js` amb el codi següent:

```{code-block} javascript
/** @odoo-module **/

import { Component, useState, onWillStart } from "@odoo/owl";
import { registry } from "@web/core/registry";
import { rpc } from "@web/core/network/rpc";

export class ActuacionsComponent extends Component {

    static template = "agrupaciomusical.actuacions_template";

    setup() {
        this.state = useState({ actes: [] });

        onWillStart(async () => {
            this.state.actes = await rpc("/my/actuacions/json");
            console.log("Actes carregats:",this.state.actes);
        });
    }
}
registry.category("public_components").add("agrupaciomusical.ActuacionsComponent",ActuacionsComponent);
```
Aquest component:
- crea un estat (state) per guardar les dades
- realitza una crida al servidor amb rpc
- guarda les dades per a mostrar-les en la interfície

A més, perquè Odoo puga utilitzar el component en el frontend, cal registrar-lo en la categoria adequada, i això estem fent-ho amb la línia 
```{code-block} javascript
registry.category("public_components").add(
    "agrupaciomusical.ActuacionsComponent",
    ActuacionsComponent
);
```
Aquest pas és imprescindible perquè:
- Odoo gestione el cicle de vida del component
- Es puga utilitzar amb `<owl-component>`

### Crear la plantilla OWL
Per a crear la plantilla OWL hem de crear un nou fitxer xml en `static/src/xml` al que li posarem de nom `actuacions.xml`. En el xml d'aquest fitxer recorreguem les dades amb `t-foreach` i mostrem el nom, la data i l'hora de cada actuació, o un missatge si no hi han dades.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<templates xml:space="preserve">
    <t t-name="agrupaciomusical.actuacions_template" owl="1">
        <div class="card">
            <div class="card-header">
                <h3>Actuacions</h3>
            </div>
            <div class="card-body">
                <t t-if="state.actes.length">
                    <ul class="list-group">
                        <t t-foreach="state.actes" 
                           t-as="acte" 
                           t-key="acte.id">
                            <li class="list-group-item">
                                <strong>
                                    <t t-esc="acte.name"/>
                                </strong>
                                <br/>
                                <t t-esc="acte.data"/>
                                 - 
                                <t t-esc="acte.hora"/>                                
                            </li>
                        </t>
                    </ul>
                </t>
                <t t-else="">
                    <p>
                        No hi ha actuacions disponibles
                    </p>
                </t>
            </div>
        </div>
    </t>
</templates>
```

### Crear el controlador JSON
Finalmente definim una ruta que retorne dades en format JSON. Per això tornem a editar el fitxer `controllers/controllers.py` per a afegir el codi:
```{code-block} python
    @http.route('/my/actuacions/json', type='json', auth='user')
    def actuacions_json(self):
        actes = request.env['agrupaciomusical.acte'].search([])

        return [
            {
                'id': acte.id,
                'name': acte.name,
                'data': acte.data.strftime('%d/%m/%Y') 
                    if acte.data else '',
                'hora': acte.hora_inici.strftime('%H:%M') 
                    if acte.hora_inici else '',                
            }
            for acte in actes
        ]
```
### Configuració dels assets
I con fins ara, no hi ha que oblidar afegir estos nous fitxers al manifest. En este cas per a indicar a Odoo que carrege els fitxers JavaScript i XML cal afegir una entrada `assets` com es mostra a continuació:
```
'assets': {
    'web.assets_frontend': [
        'agrupaciomusical/static/src/js/actuacions.js',
        'agrupaciomusical/static/src/xml/actuacions.xml',
    ],
},
```
Quan executem el portal i accedim a la pàgina de les actuacions podem veure totes les actucions que tenim creades:
```{image} /_static/assets/img/T6_PaginaActuacions.png
:alt: Pàgina actuacions inicial
:class: img-fluid
:align: center
:width: 80%
```

**FINAL**
Ara és el moment de realitzar la tasca [Portal de la colla](../../Annexos/Tema6_prac8_portalcolla.md) per a posar en pràctica tot el que hem vist en aquest capítol i assolir els coneixements.
