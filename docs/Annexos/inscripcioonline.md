# Exercici pràctic: Inscripció online d’una patinadora amb signatura

```{toctree}
:maxdepth: 2
:caption: Continguts de la pràctica
:hidden:
```
❗ En aquesta pràctica guiada NO es demana implementar un sistema de signatura digital amb
validesa legal real de la signatura, certificats digitals, integració amb Autofirma o altres eines similars i segellat temporal oficial. Es tracta d’una simulació didàctica d’un flux d’inscripció amb signatura digital manual, on l’usuari final pot signar documents digitalment i pujar-los a Odoo signats.

> 👉Aquest sistema no substitueix una signatura electrònica reconeguda segons eIDAS, però permet entendre el flux tècnic complet. El sistema simula un flux real, però no pretén substituir un sistema legal. 

## 🧭 Context i propòsit
El club vol que una patinadora o el pare/mare/tutor puga inscriure’s des del web, omplint un formulari i signant documents sense anar al club ni imprimir res. Tot es fa des d’Odoo; el club rep els PDFs ja signats.

::: {admonition} Objectius d’aprenentatge
:class: tip
- Dissenyar un mòdul web amb separació frontend  i backend.
- Definir models amb estat i flux clar.
- Crear formulari web i rutes amb controladors.
- Generar PDFs amb QWeb i integrar un flux de signatura digital.
:::

::: {admonition} Resultat esperat
:class: note
- Inscripció creada i guardada en BD.
- PDFs generats i, finalment, signats.
- Flux d’estats: esborrany → pendent_signatura → signada. Altres estats (acceptada, rebutjada) queden reservats per a la gestió interna posterior del club.
:::



## 📦 Crear el model que guardarà les dades
En aquesta primera iteració definim el model que sosté tot el procés. Recorda que Odoo és un framework MVC (Model-Vista-Controlador). Ara definirem un mòdul bàsic amb el model `patinatge.inscripcio` que emmagatzema les inscripcions. 

1) Nom:
```bash
patinatge_inscripcio
```

1) Estructura mínima:
```text
patinatge_inscripcio/
├── __manifest__.py
├── models/
│   └── __init__.py
│   └── patinatge_inscripcio.py
├── controllers/
│   └── __init__.py
│   └── __main__.py
├── views/
├── report/
├── static/
│   └── src/js/
└── security/
    └── ir.model.access.csv
```

1) Manifest (resum):
- depends: `base`, `website`, `portal`
- data: vistes web i reports
- security: accessos mínims per als models


Ací aparareix el concepte de report, veurem més endavant que es tracta d’una plantilla QWeb per generar PDFs.

### Definició del model `patinatge.inscripcio`
Només hi ha una entitat en aquesta iteració: no crearem encara models de patinadora o tutor; l’objectiu és recollir dades i generar documents.
Entitat:
- `patinatge.inscripcio` ← centre del flux

Dins del model `patinatge.inscripcio`:
- Camps per a dades bàsiques (nom, edat, contacte, etc.)
- Camps per a fitxers PDF generats `fields.Binary()`(fitxa inscripció, autorització, protecció dades)
- Camp estat (selecció `fields.Selection()`): `esborrany`, `pendent_signatura`, `signada`    
- Mètodes per a canviar estat i gestionar el flux  i generar identificadors únics 


Camps mínims esperats en patinatge.inscripcio:
- nom_patinadora
- cognoms_patinadora
- data_naixement
- categoria
- nom_tutor (opcional)
- cognoms_tutor (opcional)
- dni_tutor / dni_patinadora
- email_*
- telefon_*
- estat
- pdf_original (Binary)
- pdf_signat (Binary)
- csv
- hash_signat


:::{dropdown} Codi bàsic del model `patinatge.inscripcio`
:class-container: tip
```python
from odoo import models, fields
import hashlib
import base64
import secrets

class PatinatgeInscripcio(models.Model):
    _name = 'patinatge.inscripcio'
    _description = 'Inscripció al club de patinatge'
    _rec_name = 'reference'

    reference = fields.Char(
        string='Referència',
        required=True,
        default=lambda self: self.env['ir.sequence'].next_by_code('patinatge.inscripcio')
    )
    signature_manual = fields.Binary(
        string="Signatura manual",
        help="Signatura feta amb ratolí o dit"
    )
    hash_signat = fields.Char(
        string="Hash del document signat",
        readonly=True
    )

    # 🔹 Patinadora
    nom_patinadora = fields.Char(required=True)
    cognoms_patinadora = fields.Char(required=True)
    data_naixement = fields.Date(required=True)

    categoria = fields.Selection(
        [
            ('iniciacio', 'Iniciació'),
            ('federades', 'Federades'),
        ],
        required=True
    )

    # 🔹 Contacte (quan és major d’edat)
    dni_patinadora = fields.Char()
    email_patinadora = fields.Char()
    telefon_patinadora = fields.Char()

    # 🔹 Tutor legal (quan és menor)
    nom_tutor = fields.Char()
    cognoms_tutor = fields.Char()
    dni_tutor = fields.Char()
    email_tutor = fields.Char()
    telefon_tutor = fields.Char()

    # 🔹 Estat
    estat = fields.Selection(
        [
            ('esborrany', 'Esborrany'),
            ('pendent_signatura', 'Pendent de signatura'),
            ('signada', 'Signada amb certificat'),
            ('signada_manual', 'Signada manualment'),
            ('acceptada', 'Acceptada'),
            ('rebutjada', 'Rebutjada'),
        ],
        default='esborrany',
        required=True
    )


    # 🔹 Documents
    pdf_original = fields.Binary()
    pdf_signat = fields.Binary()

    data_inscripcio = fields.Datetime(
        default=fields.Datetime.now
    )
    csv = fields.Char(
        string="CSV",
        readonly=True,
        copy=False,
        index=True
    )

    def action_acceptar(self):
        self.write({'estat': 'acceptada'}) # per a gestió interna posterior del club.

    def action_rebutjar(self):
        self.write({'estat': 'rebutjada'}) # per a gestió interna posterior del club.

    def calcular_hash_pdf(self, pdf_base64):
        pdf_bytes = base64.b64decode(pdf_base64)
        return hashlib.sha256(pdf_bytes).hexdigest()

    def generar_csv(self):
        return f"{self.reference}-{secrets.token_urlsafe(6)}"
```
:::



Beneficis:
- Control del procés
- Evitar errors i firmes duplicades


## 🌐 Formulari web (sense signatura)
Seguint el model MVC, ara crearem la vista (frontend) que mostrarà el formulari d’inscripció. Aquesta vista és una plantilla QWeb que es troba en `views/inscripcio_templates.xml`. Serà accessible des de la web pública a través de la següent ruta:
Ruta: `/inscripcio`
```{image} /_static/assets/img/Tema7/formulari-inscripcio.png
:alt: Formulari inscripció
:class: img-fluid
:width: 100%
:align: center
``` 
Funció:
- Mostrar un formulari senzill
- Enviar dades al servidor
- Preparar el flux d’inscripció

No es firma ni es generen PDFs encara. Un pas = una acció.

:::{admonition} 🧠 Per què un fitxer *_templates.xml?
:class: tip
És tracta de website (frontend), no backend. Implica que aquestes plantilles s’usen amb `request.render(...)`, no apareixen en menús d’Odoo i qualsevol persona ho pot veure des del navegador.
:::


::: {admonition} 📁 On està exactament el formulari?
:class: info
El formulari web d’inscripció no està al controlador ni als models. Està en `views/inscripcio_templates.xml`.  
Tot el que és HTML, formularis, textos i estructura visual va sempre a `views/`.
:::

### 🔁 Què passa realment quan l’usuari entra a `/inscripcio`?
Quan una patinadora o un tutor accedeix a `/inscripcio`, Odoo executa el controlador que cridarà a la plantilla QWeb per mostrar el formulari. El controlador és molt senzill:
```python
from odoo import http
from odoo.http import request

class PatinatgeInscripcioController(http.Controller):

    @http.route('/inscripcio', type='http', auth='public', website=True)
    def formulari_inscripcio(self, **kw):
        return request.render(
            'patinatge_inscripcio.formulari_inscripcio',
            {}
        )

```

Explicació del controlador:
- Defineix una ruta pública (`auth='public'`): no cal login; qualsevol família hi pot accedir.
- No toca la base de dades: no es crea cap inscripció ni es valida res.
- Renderitza una plantilla QWeb: busca `formulari_inscripcio` en `views/inscripcio_templates.xml`, la carrega, l’embolica amb `website.layout` i la mostra al navegador.

::: {admonition} Estructura dels controladors (important)
:class: info
En Odoo, **un controlador és una classe que hereta de `http.Controller`**.  
Les rutes web (`@http.route`) **no són controladors per si soles**, sinó **mètodes dins d’aquesta classe**. Com que ja tenim una classe `PatinatgeInscripcioController`, no cal crear-ne una altra per altre controlador. Realment, només cal una classe per mòdul per gestionar totes les rutes.

Bones pràctiques:
- Centralitza el controlador en `controllers/main.py`
- Crea mètodes per a cada ruta dins d’aquesta classe
- Importa el fitxer en `controllers/__init__.py`
- Sense l’import, **Odoo no registra cap ruta**
:::

#### 🔗 Com s’utilitza la plantilla?
El controlador fa:
```python
return request.render('patinatge_inscripcio.formulari_inscripcio', {})
```
On:
- `patinatge_inscripcio` → nom del mòdul
- `formulari_inscripcio` → `id` del `<template>`

Odoo busca el template en `views/`, el renderitza i l’embolica amb `website.layout`.

### 🧠 Per què no fem res més en aquest pas?
- L’usuari encara pot equivocar-se, no ha acceptat res ni ha signat.
- Per això, en este pas NO creem registres, NO validem DNI seriosament, NO generem PDFs.
- Tot això es fa quan l’usuari envia el formulari (PAS 4). Un pas = una acció. Mostrar ≠ guardar.

::: {admonition} Errors que evitem
:class: warning
- Crear la inscripció només per entrar al formulari.
- Validacions “fortes” en JS.
- Barrejar lògica de negoci amb HTML.
:::




### 📄 Estructura bàsica del fitxer `inscripcio_templates.xml`
```xml
<odoo>
  <template id="formulari_inscripcio">
    <t t-call="website.layout">
      ...
    </t>
  </template>
</odoo>
```


#### 🧾 Contingut de `inscripcio_templates.xml`
Dins de la plantilla `formulari_inscripcio`, hi ha:

1) Capçalera i layout del web
  La plantilla va dins d’`<odoo>` i crida `website.layout` per tindre capçalera i peu del lloc.
```xml
<template id="formulari_inscripcio">
  <t t-call="website.layout">
    <!-- contingut -->
  </t>
</template>
```
Traducció ràpida:
- `<odoo>` → contenidor
- `<template>` → pàgina web
- `t-call="website.layout"` → capçalera + peu del web

::: {admonition} Idea clau MVC (vista)
:class: tip
La vista QWeb “pinta”, el layout dona estil i estructura. Després “envia” però no valida, no guarda en BD i no canvia estats. El cervell és el backend.
:::


1) Formulari HTML i seguretat CSRF
  El formulari té acció directa cap al controlador de POST: `/inscripcio/enviar`. S'utilitza Token CSRF per evitar enviaments maliciosos.
```html
<form action="/inscripcio/enviar" method="post">
  <input type="hidden" name="csrf_token" t-att-value="request.csrf_token()"/>
  <!-- camps -->
</form>
```
::: {admonition} Idea clau
:class: tip
Tot el que s’envia va al backend, on es valida de veritat.
:::


1) Bloc “Dades de la patinadora”
- Camps bàsics: nom, cognoms, data de naixement, categoria (select).
- `required="required"` és ajuda visual; la validació real és backend.
- `t-att-value="data.get(...)"` repinta valors si hi ha errors.
```html
<input name="nom_patinadora" required="required" t-att-value="data.get('nom_patinadora') if data else ''"/>
<input name="cognoms_patinadora" required="required" t-att-value="data.get('cognoms_patinadora') if data else ''"/>
<input name="data_naixement" type="date" required="required" t-att-value="data.get('data_naixement') if data else ''"/>
<select name="categoria" required="required">
  <option value="iniciacio" t-att-selected="data.get('categoria') == 'iniciacio' if data else False">Iniciació</option>
  <option value="federades" t-att-selected="data.get('categoria') == 'federades' if data else False">Federades</option>
</select>
```
::: {admonition} Idea clau
:class: tip
Els “name” han de coincidir amb el que espera el controlador.
:::

1) Bloc “Contacte” (només majors d’edat)
- DNI, email i telèfon de la patinadora quan és major.
- Inicialment ocult; el JS l’activa en funció de l’edat real.
```html
<div id="bloc_contacte" style="display:none;">
  <input name="dni_contacte" t-att-value="data.get('dni_contacte') if data else ''"/>
  <input name="email_contacte" type="email" t-att-value="data.get('email_contacte') if data else ''"/>
  <input name="telefon_contacte" t-att-value="data.get('telefon_contacte') if data else ''"/>
</div>
```
::: {admonition} Idea clau
:class: tip
El JS ajuda a mostrar/ocultar, però la decisió final és del backend.
:::

1) Bloc “Tutor legal” (només menors d’edat)
- Nom, cognoms, DNI, email i telèfon del tutor/a.
- També ocult fins que el JS detecta menor d’edat.
```html
<div id="bloc_tutor" style="display:none;">
  <input name="nom_tutor" t-att-value="data.get('nom_tutor') if data else ''"/>
  <input name="cognoms_tutor" t-att-value="data.get('cognoms_tutor') if data else ''"/>
  <input name="dni_tutor" t-att-value="data.get('dni_tutor') if data else ''"/>
  <input name="email_tutor" type="email" t-att-value="data.get('email_tutor') if data else ''"/>
  <input name="telefon_tutor" t-att-value="data.get('telefon_tutor') if data else ''"/>
</div>
```
::: {admonition} Idea clau
:class: tip
El backend torna a comprovar menor/major i valida DNI.
:::

1) Gestió d’errors (feedback a l’usuari)
  Si el backend troba un error (p. ex. DNI invàlid), la vista mostra un missatge i conserva les dades.
```xml
<t t-if="error">
  <div class="alert alert-danger"><t t-esc="error"/></div>
</t>
```
::: {admonition} Idea clau
:class: tip
Millor experiència; no es perd el que ja s’ha escrit.
:::

1) Botó d’enviament
  Envia el formulari al controlador; no guarda res en la vista.
```html
<button type="submit" class="btn btn-primary mt-3">Enviar inscripció</button>
```
::: {admonition} Idea clau
:class: tip
“Enviar” → PAS 4 (validació i creació). Mostrar ≠ guardar.
:::

1) JavaScript d’ajuda visual
Aquest JavaScript no és el cervell del sistema. És només un ajudant perquè l’usuari no es perda mentre ompli el formulari. Calcula edat, mostra el bloc correcte (contacte o tutor) i ajusta “required”. El codi va al final del fitxer inscripcio_templates.xml, dins d’una etiqueta `<script>...</script>`. 

Podem incrustar el codi directament o referenciar un fitxer extern a `static/src/js/`. Sempre que siga senzill, el posem directament però si és molt llarg, millor en un fitxer extern. Per a fer-ho cal `/nom_modul/static/src/js/fitxer.js` i després referenciar-lo, com per exemple, en aquest cas:
```xml
<t t-call="website.layout">
    ...
    <script type="text/javascript"
            src="/patinatge_inscripcio/static/src/js/inscripcio_form.js">
    </script>
</t>
```
Però recorda que si està incrustat cal escapar caràcters especials (com `<`, `>`, `&`) amb entitats HTML (`&lt;`, `&gt;`, `&amp;`) o utilitzar CDATA:
```xml    
<script type="text/javascript">
<![CDATA[
    // codi JS ací dins sense preocupar-se d’escapar
]]></script>
```



::: {admonition} 🔍 Explicació detallada JavaScript
:class: info

<details>
<summary>Fes clic per veure l’explicació pas a pas</summary>

 8.1) Esperar que el HTML estiga carregat

```javascript
document.addEventListener("DOMContentLoaded", function () {
    // tot el JS va ací dins
});
  ```
Què fa açò?

Espera que el navegador haja carregat tot el HTML.

Evita errors típics de “no trobe l’element”.

👉 Si intentàrem accedir als camps abans, el navegador diria:
“xe, això encara no existix”.

  8.2) Agafar els elements importants del formulari

Ara identifiquem què volem controlar:

```javascript
const dataInput = document.getElementById("data_naixement");
const blocTutor = document.getElementById("bloc_tutor");
const blocContacte = document.getElementById("bloc_contacte");
```


Què estem fent?

dataInput: el camp de data de naixement.

blocTutor: el bloc amb les dades del tutor/a.

blocContacte: el bloc amb les dades de contacte de la patinadora.

👉 Açò només funciona si els id del HTML coincidixen exactament.
Si un id està mal escrit, el JS no farà res (i no sempre avisa).


  8.3) Preparar els inputs per marcar required

Ara volem poder dir:

“aquests camps són obligatoris”

“aquests no”
```javascript
const tutorInputs = blocTutor.querySelectorAll("input");
const contacteInputs = blocContacte.querySelectorAll("input");
``` 

Què fa açò?

Agafa tots els <input> dins de cada bloc.

Ens permet marcar o desmarcar required en grup.

👉 Açò evita anar camp per camp com un boig.



  8.4) Funció central: `aplicarEdat()`

Ara ve el tros important, però tranquilitat, anem a poc a poc.
```javascript
function aplicarEdat() {
    if (!dataInput.value) return;
```


Primer filtre:

Si no hi ha data de naixement → no fem res. Evita errors quan el camp està buit.

  8.5) Convertir la data i comprovar que és vàlida

```javascript
const dataNaix = new Date(dataInput.value);
if (isNaN(dataNaix)) return;
```

Per què açò?

Convertim el text (YYYY-MM-DD) en una data real. Si per algun motiu no és una data vàlida → parem. Mai confies cegament en el que ve del navegador.


  8.6) Calcular l’edat aproximada
```javascript
const hui = new Date();
let edat = hui.getFullYear() - dataNaix.getFullYear();
const m = hui.getMonth() - dataNaix.getMonth();

if (m < 0 || (m === 0 && hui.getDate() < dataNaix.getDate())) {
    edat--;
}
```

Què fa exactament?

Resta anys.

Ajusta si encara no ha complit anys enguany.

👉 Açò evita errors típics de “té 18… però encara no”.

⚠️ Important:
Aquesta edat és orientativa.
La decisió legal es torna a calcular en backend al PAS 4.


  8.7) Decisió visual: menor o major d’edat

Ara només decidim què es veu al formulari.

👶 Si és menor d’edat
```javascript
if (edat < 18) {
    blocTutor.style.display = "block";
    blocContacte.style.display = "none";

    tutorInputs.forEach(i => i.required = true);
    contacteInputs.forEach(i => i.required = false);
}

```

Mostra el bloc del tutor.

Oculta el bloc de contacte.

Marca com obligatoris els camps del tutor.

🧑 Si és major d’edat
```javascript
else {
    blocTutor.style.display = "none";
    blocContacte.style.display = "block";

    tutorInputs.forEach(i => i.required = false);
    contacteInputs.forEach(i => i.required = true);
}
```


Mostra contacte.

Oculta tutor.

Ajusta required.

👉 Açò és només UX, no una decisió legal definitiva.


  8.8) Reactivar la funció quan canvia la data
  ```javascript
dataInput.addEventListener("change", aplicarEdat);
```

Què passa ací?

Cada vegada que l’usuari canvia la data es recalcula l’edat i s’actualitza la UI. Sense recarregar la pàgina. Tot fluid.


  8.9) Executar-ho també en carregar la pàgina
  ```javascript
aplicarEdat();
```

Per què és clau açò?

Si tornem al formulari per un error (DNI incorrecte, per exemple), el backend repinta les dades, però el JS ha de tornar a mostrar el bloc correcte.

👉 Sense aquesta línia, la UI podria quedar desquadrada.

  8.10) Resum final

Este JS només ajuda a la UI: mostra/oculta blocs i marca “required” segons l’edat. La lògica real (edat, decisions, validacions) es fa en backend.

> És ajuda visual per a l’usuari. El servidor recalcularà l’edat i la validarà igualment.

Què fa / què no fa:
- Fa: mostrar/ocultar blocs i marcar `required` en el navegador.
- No fa: guardar res en BD, validar DNI de veritat, decidir de forma definitiva tutor vs patinadora, ni canviar estats.

Depuració ràpida:
- Comprova que els IDs dels elements del HTML coincidixen (`data_naixement`, `bloc_tutor`, `bloc_contacte`).
- Revisa el format de la data (type="date" envia “YYYY-MM-DD”).
- Usa la consola del navegador per detectar errors de JS.
```javascript
document.addEventListener("DOMContentLoaded", function () {
    console.log("Hola món");
});
```

</details> 
::: 


::: {admonition} Què fa / què no fa la plantilla
:class: warning
Fa: pinta el formulari, mostra errors, repinta dades, ajuda visual amb JS.  
No fa: crear registres, validar de veritat, generar PDFs, canviar estats.  
Això ho fan el controlador (POST `/inscripcio/enviar`) i el model (`patinatge.inscripcio`).
:::

:::{image} /_static/assets/img/Tema7/formulari-inscripcio2.png
:alt: Formulari inscripció
:class: img-fluid
:width: 100%
:align: center
:::


## 🧾 Enviar el formulari: validació i creació de la inscripció
Quan es polsa “Enviar inscripció”, el formulari envia les dades a `/inscripcio/enviar`. 
```xml
<form action="/inscripcio/enviar" method="post">
```

Ara mana el backend però necessitem un controlador que reba la ruta corresponent i faça les validacions i creacions. Aquest controlador és un mètode dins de la classe `PatinatgeInscripcioController` que ja tenim. La ruta és:

```python
@http.route('/inscripcio/enviar', type='http', auth='public', methods=['POST'], website=True)
def enviar_inscripcio(self, **post):
    ...
```

::: {admonition} Idea clau (backend)
:class: tip
Tot el que ve del navegador es comprova en servidor: validacions, decisions d’estat i generació de PDFs.
:::

### 🔢 1 Calcular l’edat real (en servidor)
Una de les comprobacions es l'edad de la patinadora que si és menor cal que signe el tutor legal. No es confia en el JS del navegador. Per tant afegim al métode el cálcul de l’edat real:

```python
from datetime import date

data_naix = post.get('data_naixement')
edat = (date.today() - date.fromisoformat(data_naix)).days // 365
```
Per què ací i no en JS?
- El JS es pot manipular.
- La lògica crítica (menor/major) és sempre de servidor.
- Si és menor → firma el tutor; si és major → firma la patinadora.

### 🔎 2 Validació del DNI/NIE
Utilitzem una funció de validació (ja definida en el controlador fora de la classe):
```python
dni = post.get('dni')
if not validar_dni_nie(dni):
    return request.render(
        'patinatge_inscripcio.formulari_inscripcio',
        {'error': 'El DNI/NIE no és vàlid.', 'data': post}
    )
```
- Es valida el DNI del tutor (si menor) o el de la patinadora (si major).
- Si és incorrecte: no es crea res, es torna al formulari, es mostra un error i es conserven les dades.

::: {admonition} Funció de validació DNI/NIE
:class: info
```python
def validar_dni_nie(dni):
    if not dni:
        return False
    dni = dni.upper().strip()
    lletres = "TRWAGMYFPDXBNJZSQVHLCKE"
    if len(dni) != 9:
        return False
    if dni[0] in "XYZ":
        dni = dni.replace('X', '0').replace('Y', '1').replace('Z', '2')
    num = dni[:-1]
    return num.isdigit() and dni[-1] == lletres[int(num) % 23]
```

És una funció bàsica que comprova la validesa del DNI/NIE segons les regles oficials espanyoles.
:::



### 📝 3 Crear la inscripció (si tot és correcte)
Si les dades són vàlides, es crea la inscripció amb tots els camps i l’estat `pendent_signatura`:
```python
vals = {
    # mapatge segur dels camps del formulari → camps del model
    # 'nom': post.get('nom'), ...
    'estat': 'pendent_signatura',
}
inscripcio = request.env['patinatge.inscripcio'].sudo().create(vals)
```
En aquest moment:
- S’escriu la informació.
- L’estat passa a `pendent_signatura`.
- Encara no hi ha PDFs signats ni patinadora definitiva (és un procés).

### 📄 4 Generar el PDF inicial (QWeb)
Gerem el PDF amb les dades introduïdes i l’estructura oficial del club. En aquest punt del flux apareix un concepte clau en Odoo: **el report QWeb**. Un report QWeb **no és una vista web** i **no es mostra al navegador**.  
És una plantilla que transforma dades d’un model en un **document PDF**. Per aconseguir-ho necessitem una plantilla QWeb en `report/report_inscripcio.xml` que defineix el format del PDF. Després, des del controlador, generem el PDF i el guardem en un camp Binary (`pdf_original`):
```python
pdf_bytes, _ = request.env.ref(
    'patinatge_inscripcio.report_inscripcio'
)._render_qweb_pdf([inscripcio.id])

# guardar en un Binary (base64)
inscripcio.write({'pdf_original': base64.b64encode(pdf_bytes)})
```
El PDF:
- Conté les dades introduïdes.
- Té l’estructura oficial del club.
- No està signat (guardat com `pdf_original`).
- Servirà de base per a la signatura.

Els reports QWeb sempre van dins de la carpeta `report/`:

```bash
patinatge_inscripcio/
├── report/
│   ├── inscripcio_report.xml
│   └── report_inscripcio.xml
```

Cada fitxer té una funció clara:
- **inscripcio_report.xml** → defineix l’acció del report
- **report_inscripcio.xml** → defineix el contingut del PDF

📌 Acció del report (`inscripcio_report.xml`)

Aquest fitxer registra el report dins d’Odoo perquè es puga generar un PDF a partir del model.

- Associa el report al model `patinatge.inscripcio`
- Indica que el resultat serà un **PDF**
- Enllaça amb la plantilla QWeb real del document

Aquest report **no genera el PDF per si mateix**: només diu a Odoo *com* i *amb què* s’ha de generar.
```xml
<?xml version="1.0" encoding="utf-8"?>
<odoo>

    <!-- ACCIÓ D’INFORME -->
    <record id="action_report_inscripcio" model="ir.actions.report">
        <field name="name">Full d’inscripció</field>
        <field name="model">patinatge.inscripcio</field>
        <field name="report_type">qweb-pdf</field>
        <field name="report_name">patinatge_inscripcio.report_inscripcio</field>
        <field name="report_file">patinatge_inscripcio.report_inscripcio</field>
    </record>

</odoo>
```

:::{admonition} 📄 Report QWeb: `report_inscripcio.xml`
:class: tip

Aquest fitxer defineix la plantilla QWeb que genera el PDF d’inscripció. No és una vista web, sinó un report pensat per a PDF. És la plantilla QWeb que defineix **l’aspecte del PDF**.

**Què és aquest report**
- Plantilla QWeb
- S’utilitza #amb ir.actions.report
- Rep registres (`docs`) i genera PDFs

**Estructura bàsica**
```xml
<odoo>
  <template id="report_inscripcio">
    <t t-call="web.external_layout">
      <main>
        ...
      </main>
    </t>
  </template>
</odoo>
```

**Iteració dels registres**
```xml
<t t-foreach="docs" t-as="doc">
```

**Tutor legal (condicional)**
```xml
<t t-if="doc.nom_tutor">
```

**Codi complet**
```xml
<?xml version="1.0" encoding="utf-8"?>
<odoo>

    <template id="report_inscripcio">
        <t t-call="web.external_layout">
            <main style="margin-left: 2.2cm;">

                <t t-foreach="docs" t-as="doc">
                    <div class="page" style="margin-left: 2.2cm;">

                        <h2 style="text-align:center;">
                            Full d’inscripció al Club de Patinatge
                        </h2>

                        <p>
                            <strong>Referència:</strong>
                            <span t-esc="doc.reference"/>
                        </p>

                        <h3>Dades de la patinadora</h3>
                        <ul>
                            <li><strong>Nom:</strong> <span t-esc="doc.nom_patinadora"/></li>
                            <li><strong>Cognoms:</strong> <span t-esc="doc.cognoms_patinadora"/></li>
                            <li><strong>Data naixement:</strong> <span t-esc="doc.data_naixement"/></li>
                            <li><strong>Categoria:</strong> <span t-esc="doc.categoria"/></li>
                        </ul>

                        <t t-if="doc.nom_tutor">
                            <h3>Dades del tutor legal</h3>
                            <ul>
                                <li><strong>Nom:</strong> <span t-esc="doc.nom_tutor"/></li>
                                <li><strong>Cognoms:</strong> <span t-esc="doc.cognoms_tutor"/></li>
                                <li><strong>DNI:</strong> <span t-esc="doc.dni_tutor"/></li>
                                <li><strong>Email:</strong> <span t-esc="doc.email_tutor"/></li>
                                <li><strong>Telèfon:</strong> <span t-esc="doc.telefon_tutor"/></li>
                            </ul>
                        </t>

                        <p style="margin-top:40px;">
                            Signatura:
                        </p>

                        <div style="margin-top:60px;">
                            _______________________________
                        </div>

                    </div>
                </t>

            </main>
        </t>
    </template>

</odoo>
```

:::

❌ Errors habituals

- Pensar que un report és una vista web
- Intentar mostrar-lo amb `request.render`
- Generar el PDF abans de validar dades
- Barrejar HTML de website amb reports

Si fas això… Odoo et mirarà malament 😅



### ✍️ 5 Passar a la pantalla de signatura
Finalment, es redirigeix l’usuari a la vista de signatura:
```python
return request.render(
    'patinatge_inscripcio.inscripcio_signar',
    {'inscripcio': inscripcio}
)
```
A partir d’ací:
- L’usuari ja no edita dades.
- Només pot signar o pujar el PDF signat amb Autofirma.
- El procés avança d’estat (no torna arrere).

:::{dropdown} Codi complet ruta del controlador d’enviament
:icon: code
:class-container: tip
```python
    @http.route('/inscripcio/enviar', type='http', auth='public', methods=['POST'], website=True)
    def enviar_inscripcio(self, **post):

        data_naix = post.get('data_naixement')
        edat = (date.today() - date.fromisoformat(data_naix)).days // 365

        # 🔎 Validació DNI
        if edat < 18:
            dni = post.get('dni_tutor')
            if not validar_dni_nie(dni):
                return request.render(
                    'patinatge_inscripcio.formulari_inscripcio',
                    {'error': 'El DNI/NIE del tutor no és vàlid', 'data': post}
                )
        else:
            dni = post.get('dni_contacte')
            if not validar_dni_nie(dni):
                return request.render(
                    'patinatge_inscripcio.formulari_inscripcio',
                    {'error': 'El teu DNI/NIE no és vàlid', 'data': post}
                )

        # 📝 Crear inscripció
        vals = {
            'nom_patinadora': post.get('nom_patinadora'),
            'cognoms_patinadora': post.get('cognoms_patinadora'),
            'data_naixement': data_naix,
            'categoria': post.get('categoria'),
            'estat': 'pendent_signatura',
        }

        if edat < 18:
            vals.update({
                'nom_tutor': post.get('nom_tutor'),
                'cognoms_tutor': post.get('cognoms_tutor'),
                'dni_tutor': post.get('dni_tutor'),
                'email_tutor': post.get('email_tutor'),
                'telefon_tutor': post.get('telefon_tutor'),
            })
        else:
            vals.update({
                'dni_patinadora': post.get('dni_contacte'),
                'email_patinadora': post.get('email_contacte'),
                'telefon_patinadora': post.get('telefon_contacte'),
            })

        inscripcio = request.env['patinatge.inscripcio'].sudo().create(vals)

        # 📄 Generar PDF
        report = request.env.ref('patinatge_inscripcio.action_report_inscripcio').sudo()
        pdf_content, _ = request.env['ir.actions.report'].sudo()._render_qweb_pdf(
            'patinatge_inscripcio.report_inscripcio',
            [inscripcio.id]
        )


        inscripcio.write({
            'pdf_original': base64.b64encode(pdf_content),
        })

        return request.render(
            'patinatge_inscripcio.inscripcio_signar',
            {'inscripcio': inscripcio}
        )
```
:::


::: {admonition} Vista signatura  `inscripcio_signar.xml`
:class: info
Aquest fitxer **NO és backend**.  
És una **vista QWeb de website**: pinta informació, captura accions de l’usuari i envia dades al servidor.
La lògica real (validacions, estats, PDFs finals) està en el **controlador** i el **model**.
:::

:::{image} /_static/assets/img/Tema7/formulari-inscripcio4.png
:alt: Vista signatura inscripció
:class: img-fluid
:width: 100%
:align: center
:::

:::{dropdown} codi complet de la vista de signatura
:icon: code
:class-container: tip
```xml
<?xml version="1.0" encoding="utf-8"?>
<odoo>

<template id="inscripcio_signar" name="Inscripció quasi acabada">
    <t t-call="website.layout">
        <div class="container mt-5">

            <h2>Inscripció quasi acabada 🛼</h2>
            <p>
                Ja hem generat el full d’inscripció.
                <strong>Revisa’l i signa’l</strong> per completar el procés.
            </p>

            <h4>Full d’inscripció (previsualització)</h4>

            <div style="border:1px solid #ccc; height:700px;">
                <iframe
                    t-att-src="'/inscripcio/pdf/%s#navpanes=0&amp;toolbar=1&amp;scrollbar=1' % inscripcio.id"
                    width="100%"
                    height="100%"
                    style="border:none;">
                </iframe>
            </div>

            <h4 class="mt-4">Signatura manual</h4>

            <canvas id="signature-pad"
                    width="500"
                    height="200"
                    style="border:1px solid #ccc;"></canvas>

            <br/>
            <button type="button"
                    class="btn btn-secondary mt-2"
                    onclick="clearCanvas()">
                🧹 Esborrar
            </button>

            <div class="mt-3">
                <a t-att-href="'/inscripcio/pdf/%s' % inscripcio.id"
                   class="btn btn-secondary"
                   target="_blank">
                    📄 Descarregar PDF
                </a>
            </div>

            <hr/>

            <div class="alert alert-info">
                <ul class="mb-0">
                    <li>Signa manualment amb el ratolí i envia'l directament</li>
                </ul>
            </div>

            <!-- 🔐 FORMULARI DE PUJADA -->
            <form id="form-signatura"
                  action="/inscripcio/pujar_signat"
                  method="post"
                  enctype="multipart/form-data">
                <!-- 🔐 CSRF TOKEN (OBLIGATORI) -->
                <input type="hidden"
                        name="csrf_token"
                        t-att-value="request.csrf_token()"/>
                <input type="hidden"
                       name="inscripcio_id"
                       t-att-value="inscripcio.id"/>

                <!-- 🔴 SIGNATURA MANUAL (BASE64) -->
                <input type="hidden"
                       name="signature_data"
                       id="signature_data"/>

                <input type="file"
                       name="pdf_signat"
                       accept="application/pdf"/>

                <br/><br/>
                <button class="btn btn-success">
                    ⬆️ Signar
                </button>


            </form>

        </div>

        <!-- 🎨 CANVAS SIGNATURA -->
        <script>
            const canvas = document.getElementById('signature-pad');
            const ctx = canvas.getContext('2d');
            let drawing = false;
            let hasDrawn = false;   

            canvas.addEventListener('mousedown', () =&gt; drawing = true);
            canvas.addEventListener('mouseup', () =&gt; {
                drawing = false;
                ctx.beginPath();
            });
            canvas.addEventListener('mousemove', draw);

            function draw(e) {
                if (!drawing) return;
                hasDrawn = true; 
                ctx.lineWidth = 2;
                ctx.lineCap = 'round';
                ctx.strokeStyle = '#000';
                ctx.lineTo(e.offsetX, e.offsetY);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(e.offsetX, e.offsetY);
            }

            function clearCanvas() {
                ctx.clearRect(0, 0, canvas.width, canvas.height);
                hasDrawn = false;
            }
        </script>

        <!-- 📤 CAPTURA DE SIGNATURA EN ENVIAR -->
        <script>
            document.getElementById('form-signatura').addEventListener('submit', function () {
                if (hasDrawn) {
                    document.getElementById('signature_data').value =
                        canvas.toDataURL('image/png');
                } else {
                    document.getElementById('signature_data').value = '';
                }
            });
        </script>


    </t>
</template>

</odoo>
```


#### 🧭 Quin és l’objectiu d’aquesta vista?

Quan l’usuari arriba ací:
- ✅ la inscripció **ja està creada**
- ✅ el PDF inicial **ja existeix**
- 🔄 l’estat és `pendent_signatura`

Aquesta pàgina serveix per a:
- Revisar el document,
- Signar-lo (manualment o pujar-lo signat),
- Enviar la signatura al backend.



#### 🧱 Estructura general de la plantilla i codi pas a pas
Anem a veure l’estructura bàsica i els punts clau així com el codi complet de cada part.
```xml
<template id="inscripcio_signar">
  <t t-call="website.layout">
    <!-- contingut -->
  </t>
</template>
```

Claus:
- `website.layout` aporta capçalera i peu.
- La vista **no toca la BD**.
- Tot el que s’envia va al controlador `/inscripcio/pujar_signat`.



**📄 Previsualització del PDF d’inscripció**
```html
<iframe
  t-att-src="'/inscripcio/pdf/%s#navpanes=0&amp;toolbar=1&amp;scrollbar=1' % inscripcio.id"
  width="100%"
  height="100%"
  style="border:none;">
</iframe>
```

Què està passant ací?
- El PDF ja existeix quan arribem a aquesta vista.
- Es carrega dins d’un iframe per a:
  - revisar-lo,
  - comprovar les dades,
  - evitar descàrregues innecessàries.

Detall important:
- `t-att-src` construeix dinàmicament la URL amb l’id de la inscripció.
- El PDF no es torna a generar ací. La vista només el mostra.

::: {admonition} Idea clau MVC
:class: tip
La vista pinta; el controlador treballa.  
Servir el PDF en un iframe és “vista”. Decidir quin PDF enviar és “controlador”. El contingut ve del “model”.
:::


**✍️ Zona de signatura manual (canvas)**
```html
<canvas id="signature-pad"
        width="500"
        height="200"
        style="border:1px solid #ccc;">
</canvas>
```

Aquesta part permet:
- Signar amb el ratolí (o tàctil).
- No dependre de programes externs.
- Capturar la signatura com una imatge.

Important:
- El canvas no envia res per si mateix.  
- És JavaScript qui després:
  - detecta si s’ha dibuixat,
  - converteix la signatura a Base64,
  - la col·loca dins d’un input hidden.


**🧹 Botó d’esborrar**
```html
<button type="button"
        class="btn btn-secondary mt-2"
        onclick="clearCanvas()">
  🧹 Esborrar
</button>
```

Funció:
- Neteja el canvas.
- No toca dades del servidor.
- És pur frontend.


**📥 Descarregar el PDF**
```html
<a t-att-href="'/inscripcio/pdf/%s' % inscripcio.id"
   class="btn btn-secondary"
   target="_blank">
  📄 Descarregar PDF
</a>
```

Aquesta opció permet:
- Descarregar el document,
- Imprimir-lo,
- Signar-lo fora del sistema.

👉 Dona flexibilitat a l’usuari i prepara l’alternativa de pujada de PDF signat.


**📤 Formulari únic d’enviament**
```html
<form id="form-signatura"
      action="/inscripcio/pujar_signat"
      method="post"
      enctype="multipart/form-data">
```

Punt clau:
- Tant la signatura manual com el PDF pujat s’envien al mateix endpoint.
- No hi ha dos formularis ni dos controladors: hi ha un únic flux.



**🔐 Camps ocults del formulari**
```html
<input type="hidden"
       name="csrf_token"
       t-att-value="request.csrf_token()"/>
```
Protecció CSRF obligatòria en website. Odoo valida que el formulari és legítim.

```html
<input type="hidden"
       name="inscripcio_id"
       t-att-value="inscripcio.id"/>
```
Indica quina inscripció s’està signant. Evita ambigüitats al backend.

```html
<input type="hidden"
       name="signature_data"
       id="signature_data"/>
```
Ací s’injecta la signatura manual en Base64 si existeix. Si no s’ha dibuixat res, s’envia buit.


**📎 Pujada opcional del PDF signat**
```html
<input type="file"
       name="pdf_signat"
       accept="application/pdf"/>
```

Aquest camp:
- És opcional.
- Serveix si l’usuari ha signat el document fora.
- Va al mateix formulari i al mateix controlador.

👉 La diferència no està en la vista, està en què arriba al servidor.


**🧠 Lògica JavaScript**
- Controla el dibuix al canvas.
- Detecta si hi ha signatura (`hasDrawn`).
- En enviar el formulari:
  - si hi ha dibuix → `signature_data` conté la imatge,
  - si no → queda buit.
- El backend decidirà què fer.

::: {admonition} ✅ Idea clau 
:class: important
La vista no pren decisions: només recull dades.  
Qui valida i guarda és el controlador i el model.  
Açò és arquitectura MVC neta i coherent.
:::

Aquesta part del codi no parla amb Odoo, no toca la base de dades i no pren decisions de negoci.  
Només s’encarrega de capturar una signatura dibuixada per l’usuari.

**1 Inicialització del canvas**
Iniciem variables clau que controlen el dibuix:
```javascript
const canvas = document.getElementById('signature-pad');
const ctx = canvas.getContext('2d');
let drawing = false;
let hasDrawn = false;
```
Què estem fent ací?
- canvas → selecciona l’element `<canvas>` del HTML.
- ctx → obté el context 2D, que és el que permet dibuixar línies.
- drawing → indica si l’usuari està dibuixant en eixe moment.
- hasDrawn → serveix per saber si s’ha signat o no.

👉 Idea clau: no importa com de bonica siga la firma, només importa si existeix.

**2 Detectar quan comença i acaba el dibuix**
Els esdeveniments `mousedown` i `mouseup` controlen l’inici i la fi del dibuix:
```javascript
canvas.addEventListener('mousedown', () => drawing = true);

canvas.addEventListener('mouseup', () => {
  drawing = false;
  ctx.beginPath();
});
```
Quan l’usuari prem el ratolí:
- comença el dibuix,
- `drawing` passa a `true`.

Quan solta el ratolí:
- s’acaba el dibuix,
- es reinicia el traçat.

👉 Açò evita que les línies se’n vagen de mare.

**3 Dibuixar mentre es mou el ratolí**
Per a dibuixar, escoltem l’esdeveniment `mousemove`:
```javascript
canvas.addEventListener('mousemove', draw);

function draw(e) {
  if (!drawing) return;          // si no està dibuixant, no fem res
  hasDrawn = true;               // ja existeix una signatura

  ctx.lineWidth = 2;
  ctx.lineCap = 'round';
  ctx.strokeStyle = '#000';

  ctx.lineTo(e.offsetX, e.offsetY);
  ctx.stroke();

  ctx.beginPath();
  ctx.moveTo(e.offsetX, e.offsetY);  // preparem el següent segment
}
```
Què passa ací?
- S’eviten “ratlles fantasmes” si no s’està dibuixant.
- En el primer moviment marquem que ja hi ha signatura.
- Es defineix l’estil i es dibuixen segments curts i continus.

**4 Esborrar la signatura**
```javascript
function clearCanvas() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  hasDrawn = false;
}
```
Quan l’usuari prem 🧹 Esborrar:
- El canvas es neteja completament.
- Es torna a indicar que no hi ha signatura.

👉 Important: esborrar també afecta les dades que s’enviaran.

**5 Captura de la signatura en enviar el formulari**
```javascript
document.getElementById('form-signatura')
  .addEventListener('submit', function () {
    if (hasDrawn) {
      document.getElementById('signature_data').value =
        canvas.toDataURL('image/png');     // imatge PNG en Base64
    } else {
      document.getElementById('signature_data').value = ''; // camp buit
    }
  });
```
Aquest codi no s’executa en dibuixar, només quan l’usuari prem ⬆️ Signar.

Si hi ha signatura:
- El canvas es converteix en PNG,
- Es codifica en Base64,
- Es guarda dins d’un `<input hidden>`.

Si no hi ha signatura:
- S’envia el camp buit, la vista no bloqueja res. El formulari s’envia igualment; el backend decidirà què fer.

En la part del controlador, veurem com es processa aquesta informació. S'ha optat per incloure tant la signatura manual com la pujada del PDF signat en un únic formulari i ruta per simplificar el flux. La signatura manual es captura en Base64 i s'envia juntament amb el PDF pujat (si n'hi ha) al mateix endpoint. El que es fa és incrustar la signatura al PDF original i generar el PDF final signat amb la signatura manual al marge o el PDF pujat. També es calcula el hash i s'imprimeix al PDF junt amb un CSV de verificació. Al final, redirigim a una pàgina d'èxit on es mostra que la inscripció està completada i es pot descarregar el PDF signat.

:::{dropdown} Codi de la ruta del controlador per a pujar la signatura
:icon: code
:class-container: tip
```python
    @http.route('/inscripcio/pujar_signat', type='http', auth='public', methods=['POST'], website=True)
    def pujar_pdf_signat(self, **post):
        inscripcio = request.env['patinatge.inscripcio'].sudo().browse(
            int(post.get('inscripcio_id'))
        )

        if not inscripcio:
            return request.not_found()

        pdf = post.get('pdf_signat')
        signature_data = post.get('signature_data')

        vals = {}
        if not inscripcio.csv:
            inscripcio.write({'csv': inscripcio.generar_csv()})

        # 🖊️ OPCIÓ 1: Signatura manual (ratolí)
        if signature_data:
            try:
                header, encoded = signature_data.split(',', 1)
                if encoded:
                    # 1. PDF provisional
                    pdf_signat_temp = aplicar_signatura_al_pdf(
                        inscripcio.pdf_original,
                        encoded,
                        inscripcio.reference,
                        "TEMP",
                        inscripcio.csv
                    )

                    # 2. hash
                    hash_pdf = inscripcio.calcular_hash_pdf(pdf_signat_temp)

                    # 3. PDF definitiu amb hash imprés
                    pdf_signat = aplicar_signatura_al_pdf(
                        inscripcio.pdf_original,
                        encoded,
                        inscripcio.reference,
                        hash_pdf,
                        inscripcio.csv
                    )

                    vals.update({
                        'signature_manual': encoded,
                        'pdf_signat': pdf_signat,
                        'estat': 'signada_manual',
                        'hash_signat': hash_pdf,
                    })

            except Exception as e:
                raise  # MENTRE PROVES, QUE PETE I ES VEJA
      

        # ❌ CAS ÚNIC QUE NO AVANÇA
        if not vals:
            return request.render(
                'patinatge_inscripcio.inscripcio_signar',
                {
                    'inscripcio': inscripcio,
                    'error': 'Cal signar el document o pujar-lo signat per continuar.'
                }
            )

        # ✅ EN TOTS ELS ALTRES CASOS → AVANCEM
    
        inscripcio.write(vals)

        return request.render(
            'patinatge_inscripcio.inscripcio_ok',
            {'inscripcio': inscripcio}
        )

def aplicar_signatura_al_pdf(pdf_base64, signatura_base64, referencia, hash_pdf,csv):
    """
    Incrusta una signatura (PNG base64) al PDF original (base64)
    i retorna el PDF signat en base64
    """

    # 🔹 1. Decode PDF original
    pdf_bytes = base64.b64decode(pdf_base64)
    pdf_reader = PdfReader(io.BytesIO(pdf_bytes))
    pdf_writer = PdfWriter()
    
    # 🔹 2. Decode signatura PNG
    signatura_bytes = base64.b64decode(signatura_base64)
    #signatura_img = Image.open(io.BytesIO(signatura_bytes))
    img = Image.open(io.BytesIO(signatura_bytes))
    if img.mode in ("RGBA", "LA"):
        fondo = Image.new("RGB", img.size, (255, 255, 255))
        fondo.paste(img, mask=img.split()[-1])
        signatura_img = fondo
    else:
        signatura_img = img

    signatura_img = signatura_img.convert("RGBA")
    base_url = request.env['ir.config_parameter'].sudo().get_param('web.base.url')
    url_verificacio = f"{base_url}/verificar/{csv}"



    # 🔹 3. Crear PDF temporal amb la signatura
    packet = io.BytesIO()
    c = canvas.Canvas(packet, pagesize=A4)
    

  
    # 📍 POSICIÓ DE LA SIGNATURA (ajustable)
    #x = 100      # des de l’esquerra
    #y = 120      # des de baix
    #width = 200  # amplada firma
    #height = 80  # altura firma

    #c.drawInlineImage(signatura_img, x, y, width, height)
    c.saveState()
    # 🧱 Línia vertical separadora
    c.setStrokeColorRGB(0.12, 0.31, 0.85)
    c.setLineWidth(1)

    # línia vertical del marge
    c.line(
        2.2 * cm,   # just on acaba el marge
        4 * cm,    # comença prop de la firma
        2.2 * cm,
        26  * cm     # quasi tota la pàgina
    )
    # 🏛️ Franja superior esquerra
    c.translate(1 * cm, 18* cm)
    c.rotate(90)

    # 🟦 Text institucional
    c.setFont("Helvetica", 7)
    c.setFillColorRGB(0.12, 0.31, 0.85)
    c.drawString(0, 5, "Signat manualment")
    c.drawString(0, -5, datetime.now().strftime("%d/%m/%Y %H:%M"))
    c.drawString(0, -15, f"Ref: {referencia}")


    # 🖊️ Firma → A LA DRETA DEL TEXT
    c.drawInlineImage(
        signatura_img,
        70,          # ← DESPLAÇAMENT A LA DRETA (CLAU)
        -25,         # alineada amb el text
        width=4 * cm,
        height=1.4 * cm
    )

    c.restoreState()
    # 🔹 TEXT LEGAL I VERIFICACIÓ (BAIX DE TOT)
    c.setFont("Helvetica", 7)
    c.setFillColorRGB(0.4, 0.4, 0.4)  # gris elegant

    y_base = 1.4 * cm  # marge inferior base

    c.drawString(
        3 * cm,
        y_base + 36,
        "Document signat manualment. La integritat del document està garantida mitjançant hash criptogràfic."
    )

    c.drawString(
        3 * cm,
        y_base + 24,
        f"Referència: {referencia} · Data: {datetime.now().strftime('%d/%m/%Y %H:%M')}"
    )

    c.setFont("Helvetica", 6)
    c.drawString(
        3 * cm,
        y_base + 12,
        f"Hash SHA-256: {hash_pdf}"
    )

    # 🔗 Enllaç de verificació
    c.setFont("Helvetica", 7)
    c.setFillColorRGB(0.12, 0.31, 0.85)  # blau enllaç

    c.drawString(
        3 * cm,
        y_base,
        url_verificacio
    )

    c.linkURL(
        url_verificacio,
        (
            3 * cm,
            y_base - 2,
            18 * cm,
            y_base + 8
        ),
        relative=0
    )


    c.save()
    packet.seek(0)
    signatura_pdf = PdfReader(packet)

    # 🔹 4. Superposar la signatura a la primera pàgina
    base_page = pdf_reader.pages[0]
    base_page.merge_page(signatura_pdf.pages[0])

    pdf_writer.add_page(base_page)

    # 🔹 5. Afegir la resta de pàgines (si n’hi ha)
    for page in pdf_reader.pages[1:]:
        pdf_writer.add_page(page)

    # 🔹 6. Retornar PDF final en base64
    output = io.BytesIO()
    pdf_writer.write(output)

    return base64.b64encode(output.getvalue())


```
:::



## 🏁 Missatge final
Missatge humà i clar:
“Inscripció completada correctament 🎉. Gràcies per confiar en el club.”
:::{image} /_static/assets/img/Tema7/formulari-inscripcio5.png
:alt: Missatge final inscripció
:class: img-fluid
:width: 100%
:align: center
::: 
A `patinatge_inscripcio/views/inscripcio_ok.xml` tenim la plantilla que mostra aquest missatge.
:::{dropdown} Codi complet de la vista d’èxit `inscripcio_ok.xml`
:icon: code
:class-container: tip
```xml
<?xml version="1.0" encoding="utf-8"?>
<odoo>

<template id="inscripcio_ok" name="Inscripció enviada correctament">
    <t t-call="website.layout">
        <div class="container mt-5 text-center">

            <h2 class="text-success">
                ✅ Inscripció enviada correctament
            </h2>

            <p class="mt-3">
                Hem rebut la teua sol·licitud.
                Aquest és el <strong>justificant de la inscripció</strong>.
            </p>

            <div class="alert alert-light mt-4">
                <p class="mb-2">
                    Què vols fer ara?
                </p>

                <div class="d-flex justify-content-center gap-3 flex-wrap">

                    <!-- 👀 VEURE -->
                    <a t-att-href="'/inscripcio/pdf/%s' % inscripcio.id"
                       class="btn btn-outline-primary"
                       target="_blank">
                        👀 Veure el justificant
                    </a>

                    <!-- 📄 DESCARREGAR -->
                    <a t-att-href="'/inscripcio/pdf/%s' % inscripcio.id"
                       class="btn btn-outline-secondary"
                       download="download">
                        📄 Descarregar PDF
                    </a>

                    <!-- 🖨️ IMPRIMIR -->
                    <a t-att-href="'/inscripcio/pdf/%s' % inscripcio.id"
                       class="btn btn-outline-dark"
                       target="_blank"
                       onclick="setTimeout(() => window.print(), 500)">
                        🖨️ Imprimir
                    </a>

                </div>
            </div>

            <p class="mt-4 text-muted">
                Si tens qualsevol dubte, el club es posarà en contacte amb tu.
            </p>

            <a href="/" class="btn btn-link mt-3">
                ⬅ Tornar a l’inici
            </a>
            <p>
            <strong>Codi segur de verificació (CSV):</strong>
            <span t-out="inscripcio.csv"/>
            </p>

            <p>
            Pots verificar aquest document en qualsevol moment a:
            <br/>
            <a t-att-href="'/verificar/%s' % inscripcio.csv">
                <span t-out="'/verificar/%s' % inscripcio.csv"/>
            </a>
            </p>

        </div>
    </t>
</template>

</odoo>
```
::: 


S'ha creat un flux complet d’inscripció amb, a més es pot verificar la signatura i la integritat del document signat. Al link http://localhost:8069/verificar/INS-2025-0094-JVVruk8b es pot comprovar la validesa del document signat mitjançant el codi segur de verificació (CSV). Al peu de pàgina del PDF signat també es mostra aquest codi i l'enllaç de verificació. Així si s'imprimeix el document signat, es pot verificar en qualsevol moment la seva autenticitat i integritat.

Per a poder veure el pdf signat i verificar-lo, s'ha creat una nova ruta al controlador que rep el CSV com a paràmetre i busca l'inscripció corresponent. Si la troba, genera una pàgina web que mostra l'estat de la verificació (si el document és vàlid o no) i permet descarregar el PDF signat.
```python
    # 🔹 Ruta per a VEURE el PDF (iframe / justificant)
    @http.route('/inscripcio/pdf/<int:inscripcio_id>', type='http', auth='public', website=True)
    def veure_pdf_inscripcio(self, inscripcio_id, **kw):
        inscripcio = request.env['patinatge.inscripcio'].sudo().browse(inscripcio_id)

        if not inscripcio:
            return request.not_found()

        # 👉 PRIORITAT: PDF SIGNAT
        pdf_bin = inscripcio.pdf_signat or inscripcio.pdf_original

        if not pdf_bin:
            return request.not_found()

        pdf = base64.b64decode(pdf_bin)

        headers = [
            ('Content-Type', 'application/pdf'),
            ('Content-Disposition', 'inline; filename="inscripcio.pdf"'),
            ('Content-Length', str(len(pdf))),
        ]
        return request.make_response(pdf, headers=headers)

```
Ací no obrim cap vista QWeb, només servim el PDF directament perquè l’iframe el puga mostrar.

La verificació tot i que té una ruta determinada pel CSV, es pot fer des de qualsevol lloc. Per exemple, des de la pàgina d’inici del website o des d’un correu electrònic enviat a l’usuari. Això permet que qualsevol persona amb el CSV pugui comprovar la validesa del document signat.

```python
    @http.route('/verificar/<string:csv>', type='http', auth='public', website=True)
    def verificar_document(self, csv, **kw):
        inscripcio = request.env['patinatge.inscripcio'].sudo().search(
            [('csv', '=', csv)],
            limit=1
        )

        if not inscripcio:
            return request.render('patinatge_inscripcio.verificacio_error')

        return request.render(
            'patinatge_inscripcio.verificacio_ok',
            {'inscripcio': inscripcio}
        )

```
Aquesta ruta busca l’inscripció pel CSV i comprova que el PDF signat no hagi estat modificat comparant el hash. Després mostra un missatge clar a l’usuari.
El resultat es mostra en una vista QWeb senzilla   `views/verificacio_ok.xml` que indica si el document és vàlid o no.

:::{dropdown} Codi complet de la vista de verificació `verificacio_ok.xml`
:icon: code
:class-container: tip
```xml
<?xml version="1.0" encoding="utf-8"?>
<odoo>
  <template id="verificacio_ok" name="Verificació correcta">
    <t t-call="website.layout">
      <div class="container mt-5 mb-5">
        <h2 class="text-success">✔ Document verificat correctament</h2>

        <p>
          Aquest document correspon a la inscripció amb referència:
          <strong t-out="inscripcio.reference"/>
        </p>

        <ul>
          <li>
            Estat:
            <strong t-out="inscripcio.estat"/>
          </li>
          <li>
            Data d’inscripció:
            <span t-out="inscripcio.data_inscripcio"/>
          </li>
          <li>
            CSV:
            <code t-out="inscripcio.csv"/>
          </li>
        </ul>

        <a
          t-att-href="'/inscripcio/pdf/%s' % inscripcio.id"
          class="btn btn-primary mt-3"
          target="_blank"
        >
          📄 Veure document signat
        </a>
      </div>
    </t>
  </template>
</odoo>
```
:::


Cal també tenir una vista per a l’error de verificació `views/verificacio_error.xml` que mostra un missatge clar quan el CSV no és vàlid o no es troba cap inscripció associada.
:::{dropdown} Codi complet de la vista d’error de verificació `verificacio_error.xml`
:icon: code
:class-container: tip
```xml
<?xml version="1.0" encoding="utf-8"?>
<odoo>

    <template id="verificacio_error" name="Error de verificació del document">
        <t t-call="website.layout">
            <div class="container mt-5 text-center">

                <h2 class="text-danger">
                    ❌ No s’ha pogut verificar el document
                </h2>

                <p class="mt-3">
                    El codi segur de verificació (<strong>CSV</strong>) introduït
                    <strong>no és vàlid</strong> o <strong>no correspon a cap inscripció</strong>.
                </p>

                <div class="alert alert-warning mt-4 text-start">
                    <p class="mb-2">
                        Això pot passar per diversos motius:
                    </p>
                    <ul class="mb-0">
                        <li>El codi s’ha copiat incorrectament.</li>
                        <li>El document no existeix o ha sigut revocat.</li>
                        <li>El CSV no pertany a aquest club.</li>
                    </ul>
                </div>

                <p class="mt-4">
                    Comprova el codi i torna-ho a intentar.
                </p>

                <div class="d-flex justify-content-center gap-3 mt-4 flex-wrap">
                    <a href="/" class="btn btn-outline-primary">
                        ⬅ Tornar a l’inici
                    </a>
                </div>

                <p class="mt-5 text-muted">
                    Si el problema persisteix, posa’t en contacte amb el club.
                </p>

            </div>
        </t>
    </template>

</odoo>

```
:::



## 📌 Resum 
- No tot és Python, ni tot és frontend.
- Cada part té el seu lloc: web per a persones, controlador per a lògica interna i model per a dades.
- Estat i flux són claus per no perdre’t.

::: {admonition} Bones pràctiques
:class: tip
- Separa fitxers per responsabilitat: `controllers/`, `views/`, `report/`, `static/`.
- Defineix estats i transicions des del principi.
- Prova pas a pas: formulari → validació → PDFs → signatura.
:::

Comprova que tot funciona si:

- ☑️ Pots entrar a /inscripcio
- ☑️ Enviar dades vàlides crea una inscripció
- ☑️ Es genera un PDF original
- ☑️ Pots signar amb el canvas
- ☑️ Es genera el PDF signat
- ☑️ El PDF mostra hash i CSV
- ☑️ /verificar/<csv> retorna document vàlid
- ☑️ El PDF es pot descarregar i imprimir

::: {admonition} Depuració
:class: info
- Mode desenvolupador per a vistes QWeb.
- Logs per errors 500.
- Actualitza el mòdul:
  - `docker compose down && docker compose up -d`
  - `docker compose exec web odoo -u patinatge_inscripcio -d cpa --stop-after-init`.
:::

Aquesta pràctica reprodueix un flux complet real utilitzat en entorns professionals, adaptat amb finalitats didàctiques i formatives.