# 🛼 Pràctica Tema 7 · Portal de patinadores

## Context de la pràctica
El club de patinatge vol que les patinadores puguen consultar les seues dades des del portal d’usuari, sense entrar al backend d’Odoo. Ja tenim:
- Un mòdul `patinatge`
- Un portal (`/my`)
- Nocions de QWeb i de controladors

Ara posarem tot a treballar junt, pas a pas i amb validacions.

::: {admonition} Objectius d’aprenentatge
:class: tip
- Heretar i modificar plantilles QWeb del portal.
- Crear un controlador web amb rutes pròpies.
- Connectar el controlador amb models d’Odoo.
- Renderitzar dades en QWeb (t-foreach).
- Preparar el manifest i provar canvis de forma segura.
:::

::: {admonition} Requisits previs
:class: note
- Mòdul `patinatge` instal·lat.
- Almenys un model relacionat (per ex. `patinatge.patinadora`) amb algunes dades.
- Usuaris amb accés al portal (aplicació Portal).  
No calen permisos especials encara (Tema 8).
:::

---

## 1 Afegir un enllaç nou al portal (link a “Les meues dades”)

Objectiu: afegir un botó al portal d’usuari `/my` amb el text “🛼 Les meues dades de patinatge”.

Instruccions:
1) Crea el fitxer `views/portal_templates.xml` (si no existeix).
2) Hereta la plantilla `portal.portal_my_home`.
3) Afig un enllaç dins del bloc principal del portal usant `xpath` amb `hasclass` i `inside`. Utilitza bootstrap per a l’estil del botó. btn i btn-primary són classes útils i mt-2 afegeix marge superior.
4) L’enllaç ha de portar a `/my/patinatge`.

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
  <template id="portal_my_home_patinatge" inherit_id="portal.portal_my_home" name="Portal Home (patinatge)">
    <xpath expr="//div[hasclass('o_portal_my_home')]" position="inside">
      <a class="btn btn-primary mt-2"
         href="/my/patinatge">🛼 Les meues dades de patinatge</a>
    </xpath>
  </template>
</odoo>
``` -->


Actualitza el manifest per a carregar el fitxer:
```python
'data': [
    # ...altres fitxers...
    'views/portal_templates.xml',
],
```

Verificació:
- Actualitza el mòdul (`-u patinatge`) i obri `/my`.  
- Ha d’aparéixer el botó. En clicar, veuràs un 404 (encara no hi ha controlador): correcte.
  
```{image} /_static/assets/img/Tema7/vista-person-patina.png
:alt: Vista frontend pàgina personalitzada amb botó
:class: img-fluid
:align: center
:width: 100%
```

---

## 2  Crear la ruta amb un controlador

Objectiu: que la ruta `/my/patinatge` ja no done error.

Instruccions:
1) Obri/crea `controllers/controllers.py`.
2) Crea una classe amb una funció decorada amb `@http.route`.
3) Per ara, retorna una plantilla buida.

Exemple (Python):
```python
from odoo import http
from odoo.http import request

class PatinatgePortal(http.Controller):

    @http.route('/my/patinatge', type='http', auth='user', website=True)
    def portal_patinatge(self, **kw):
        # De moment, sense dades
        return request.render('patinatge.portal_patinatge_page', {})
```

Verificació:
- Actualitza el mòdul.
- Torna a clicar el botó al portal → ja no ha de donar 404 (fins que creem la plantilla, pot donar 500 si no existix la vista).

```{image} /_static/assets/img/Tema7/vista-personalitzada-no-error.png
:alt: Vista frontend pàgina personalitzada sense error
:class: img-fluid
:align: center
:width: 100%
```


---

## 3  Crear la plantilla QWeb bàsica

Objectiu: mostrar una pàgina nova del portal integrada amb el layout.

Instruccions:
1) Crea `views/portal_pages.xml`.
2) Usa `t-call="portal.portal_layout"` per a integrar el layout del portal. `t-call` no és una etiqueta estàndard XML, és una funció específica, com un “hereta” en QWeb. Li diguem a Odoo que volem usar la plantilla base del portal. Això inclou l’encapçalament, el peu de pàgina i l’estil.
3) Mostra un títol h2, un text i un botó per a tornar a `/my`.

<!-- Exemple (QWeb):
```xml
<odoo>
  <template id="portal_patinatge_page" name="Portal Patinatge Page">
    <t t-call="portal.portal_layout">
      <div class="container mt-4">
        <h2>Les meues dades de patinatge</h2>
        <p class="text-muted">Aquesta és una pàgina de prova del portal.</p>
        <a class="btn btn-secondary mt-2" href="/my">Tornar al portal</a>
      </div>
    </t>
  </template>
</odoo>
``` -->


Verificació:
- Actualitza el mòdul i obri `/my/patinatge` → ja has de vore la pàgina.

```{image} /_static/assets/img/Tema7/vista-personalitzada-basica.png
:alt: Vista frontend pàgina personalitzada bàsica
:class: img-fluid
:align: center
:width: 100%
``` 

---

## 4  Connectar el controlador amb el model

Objectiu: llegir dades reals de `patinatge.patinadora` i passar-les a la plantilla.

Instruccions:
- Fes una `search` i passa els registres al `render`.

Exemple (Python):
```python
@http.route('/my/patinatge', type='http', auth='user', website=True)
def portal_patinatge(self, **kw):
    Patinadora = request.env['patinatge.patinadora'].sudo()
    patinadores = Patinadora.search([], limit=50, order='name asc')
    values = {
        'patinadores': patinadores,
    }
    return request.render('patinatge.portal_patinatge_page', values)
```
El `request.env` és una manera segura d’accedir als models d’Odoo des d’un controlador web i amb .search() busquem tots els registres sense filtres. L’ús de `sudo()` és només temporal i didàctic. En el Tema 8 veurem com substituir-ho per permisos i regles adequades. Ara ens permet accedir als registres sense restriccions de permisos, cosa que és útil en aquest context de portal on els usuaris poden no tenir permisos complets. El resultat de la cerca es passa a la plantilla QWeb mitjançant el diccionari `values`. Una col·lecció d'objectes patinatge.patinadora està ara disponible a la plantilla per a ser mostrada. És el que anomenem recordset d’Odoo.

Verificació:
- No falla la ruta.
- El diccionari `values` s’usa en la plantilla.

---

## 5 Mostrar les dades en QWeb

Anem a llistar patinadores en la pàgina del portal. Cal utilitzar `t-foreach` que serveix per a iterar el recordset passat des del controlador. Li passem el recordset `patinadores` i mostrem els camps bàsics: nom, grup i nivell.

```bash
CONTROLADOR
│
│  patinadores = search([])
│
▼
QWEB
│
│ t-if="not patinadores"
│
│ t-foreach="patinadores" → p
│
└── p.name
    p.grup_id
    p.nivell
```


Instruccions:
- Usa `t-foreach` per a iterar les patinadores i mostra camps bàsics.

Exemple (QWeb):
```xml
<odoo>
  <template id="portal_patinatge_page" name="Portal Patinatge Page">
    <t t-call="portal.portal_layout">
      <div class="container mt-4">
        <h2>Les meues dades de patinatge</h2>

        <t t-if="not patinadores">
          <div class="alert alert-info">Encara no hi ha patinadores registrades.</div>
        </t>
        <t t-else="">
          <table class="table table-sm table-striped">
            <thead>
              <tr>
                <th>Nom</th>
                <th>Grup</th>
                <th>Categoria/Nivell</th>
              </tr>
            </thead>
            <tbody>
              <tr t-foreach="patinadores" t-as="p">
                <td><t t-esc="p.name"/></td>
                <td><t t-esc="p.grup_id.display_name"/></td>
                <td><t t-esc="p.nivell or ''"/></td>
              </tr>
            </tbody>
          </table>
        </t>

        <a class="btn btn-secondary mt-2" href="/my">Tornar al portal</a>
      </div>
    </t>
  </template>
</odoo>
```
:::{admonition} Pista
:class: note
Les classes CSS que apareixen en aquesta plantilla (`container`, `mt-4`, `alert`, `table`, `btn`, etc.) **no són de QWeb ni del mòdul**, sinó que pertanyen a **Bootstrap**, el framework d’estils que Odoo utilitza per defecte al frontend.

En concret:

* `container` centra el contingut i limita l’amplada de la pàgina.
* `mt-4`, `mt-2` afegeixen marge superior (*margin-top*).
* `alert alert-info` mostra un missatge informatiu amb format visual destacat.
* `table table-sm table-striped` dona estil a la taula (compacta i amb files alternes).
* `btn btn-secondary` aplica l’estil de botó secundari.

Gràcies a Bootstrap, podem donar un **aspecte net i coherent** a la pàgina sense escriure CSS propi.
::: 

Verificació:
- Veus una taula amb dades (si n’hi ha).
- No s’exposen dades sensibles.

```{image} /_static/assets/img/Tema7/vista-personalitzada-NOdades.png
:alt: Vista frontend pàgina personalitzada sense dades
:class: img-fluid
:align: center
:width: 100%
``` 


---

## 6  Proves i comprovacions

Checklist:
- El botó apareix a `/my`.
- La ruta `/my/patinatge` carrega.
- La pàgina mostra contingut i, si n’hi ha, dades del model.
- El disseny respecta el layout del portal.

::: {admonition} Recorda: açò és frontend (QWeb), no backend
:class: note
- Estàs renderitzant plantilles al website/portal.
- La seguretat real de dades la controlarem en Tema 8 (regles i permisos).
:::

---

## 7 Bones pràctiques, trucs i errors comuns

::: {admonition} Bones pràctiques
:class: tip
- Hereta plantilles i modifica amb `xpath`; no copies la plantilla sencera.
- Prefixa els `id` de plantilles amb el teu mòdul (`patinatge.*`).
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
- 404 en `/my/patinatge`: falta el controlador o el `href`.
- Duplicació d’`id` en templates: assegura unicitat per mòdul.
:::

---

## 8 Entrega

Cal entregar:

- El mòdul `patinatge` complet en format `.zip`,
- Un pdf amb:
  - Captures de:
    - El botó a `/my`
    - La pàgina `/my/patinatge` amb dades. Recorda omplir el mòdul amb algunes patinadores abans de fer la captura. 
  - Una breu explicació del treball realitzat. Pots realitzar modificacions addicionals per mostrar camps extra o millorar l’estil. 

