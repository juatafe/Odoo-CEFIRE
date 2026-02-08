# Implantació de sistemes ERP-CRM en una empresa

```{toctree}
:maxdepth: 2
:caption: Continguts del Tema 3
:hidden:

Practica_MailHog_Odoo
explicascript
```

## Context i objectius

Als temes anteriors hem après:  
- **Tema 1:** què és un ERP/CRM i per què són importants per a la gestió empresarial.  
- **Tema 2:** com instal·lar i configurar Odoo en diferents entorns i gestionar les bases de dades.  

Ara farem un pas més: veurem **com implantar un ERP dins d’una empresa real**.  
Ens centrarem en l’ús de la interfície web, la instal·lació de mòduls i la configuració inicial de l’empresa.

:::{admonition} Objectius del tema
:class: note
- Accedir a la part web d’Odoo amb un usuari administrador.  
- Instal·lar mòduls propis i externs de manera ordenada.  
- Comprendre que **no s’han de modificar mòduls natius** sinó heretar-los en espais separats.  
- Configurar les dades bàsiques de l’empresa: logo, icona, correu i pla comptable.  
:::

---

## Accés a la interfície web

Per accedir a Odoo, només cal obrir el navegador i escriure l’adreça del servidor on està instal·lat Odoo. Per exemple:

```{code-block} bash
http://IP_servidor:8069
```

Aquesta URL et portarà a la **pantalla inicial d’Odoo**, on podràs veure el formulari d’inici de sessió:

```{image} /_static/assets/img/Tema3/img1_T3.png
:alt: Pantalla inicial d’Odoo
:width: 100%
:align: center
```
Cal iniciar sessió amb l’usuari administrador que has configurat durant la instal·lació d’Odoo. Aquest usuari té permisos per gestionar la plataforma i serà el punt de partida per afegir nous usuaris i configurar l’empresa.

:::{admonition} Accés i gestió de bases de dades
:class: note
A la pantalla inicial d’Odoo, només pots iniciar sessió en una base de dades ja creada.  
Per gestionar bases de dades (crear, duplicar o eliminar), cal accedir directament a la URL següent:

```{code-block} bash
http://localhost:8069/web/database/manager
```
```{image} /_static/assets/img/Tema3/manager.png
:alt: Gestió de les bases de dades
:width: 100%
:align: center
```

:::tip
Aquesta opció és útil si necessites crear, duplicar o eliminar bases de dades.
:::
:::

### Pantalla inicial “Discussió”

Quan inicies sessió per primera vegada amb l’usuari **Administrador**, Odoo et mostra el mòdul **Discussió**.  
Aquesta pantalla és la bústia d’entrada de notificacions i missatgeria interna entre usuaris.

```{image} /_static/assets/img/Tema3/discussio.png
:alt: Pantalla inicial Discussió
:width: 100%
:align: center
```
En aquesta interfície pots veure:

  - *Bústia d’entrada, Destacat i Historial* → per gestionar els missatges.
  - *Canals* (com el canal general), on participen diversos usuaris.
  - *Missatges directes* (com OdooBot o altres usuaris individuals).
  
:::{note}
OdooBot és un usuari virtual que apareix per defecte i que serveix per donar-te missatges d’ajuda, consells o notificacions internes del sistema.
És útil per rebre recordatoris o proves, però no és un usuari real.
:::
A la part central apareixen els missatges rebuts. Si encara no hi ha activitat, la bústia es mostra buida.


**Un cop dins d’Odoo:**  
Per accedir a la resta d’aplicacions i configuracions, fes clic a la icona dels 9 quadrets (app switcher) situada a la part superior esquerra.
Des d’allí veuràs el menú principal amb tots els mòduls disponibles i podràs:

  - Accedir a la configuració de l’empresa **(Configuració > Configuració General > Empreses)**.
  - Instal·lar mòduls nous des del menú **Aplicacions**.
  - Gestionar dades bàsiques i paràmetres generals.


```{image} /_static/assets/img/Tema3/mycompany.png
:alt: Administració d'Odoo
:width: 100%
:align: center
```

Aquesta interfície web permet controlar totes les funcionalitats d’Odoo de manera centralitzada i intuïtiva.

---


## Instal·lació de mòduls

### Mòduls propis
Odoo porta de sèrie aplicacions com **CRM, Vendes, Inventari, Facturació**.  
Aquests es poden activar directament des del menú **Aplicacions**.

```{image} /_static/assets/img/Tema3/img5_T3.png
:alt: Llista de mòduls d’Odoo
:width: 100%
:align: center
```

### Mòduls externs
També podem afegir-ne de nous desenvolupats per la comunitat (OCA) o per empreses especialitzades.  

Bones pràctiques:  
- **No tocar els mòduls natius**: sempre que vulguem canviar alguna cosa, s’ha de fer mitjançant un mòdul nou que herete funcionalitat.  
- Guardar els mòduls externs en una carpeta separada, com `extra-addons` o `dev-addons`.  
- Afegir la ruta d’aquesta carpeta al fitxer `odoo.conf`.  

:::{admonition} Exemple amb Docker
:class: note
En `docker-compose.yml` podem muntar una carpeta local de mòduls:  

```{code-block} yaml
  web:
    image: odoo:16.0
    volumes:
      - ./extra-addons:/mnt/extra-addons
```

Així cada vegada que afegim o modifiquem un mòdul, es veurà reflectit dins del contenidor sense alterar els natius.  
:::

---

## Configuració bàsica de l’empresa

Un cop tenim la base de dades, cal configurar els paràmetres generals de l’empresa.  

| **Element** | **Exemple** |
|-------------|-------------|
| Nom i logo  | “Ajuntament de Tavernes” amb logotip corporatiu |
| Icona web (favicon) | Arxiu `.ico` per personalitzar la pestanya del navegador |
| Adreça i dades fiscals | Carrer Major, CIF, telèfon, correu electrònic |
| Servidor de correu | SMTP per enviar notificacions des d’Odoo |
| Pla comptable | Mòdul de localització `l10n_es` (PGC2008) descarregable des d’Aplicacions |

:::{admonition} Pas important
:class: warning
El mòdul de **localització del país** (en el nostre cas `l10n_es`) és imprescindible per tindre impostos i pla comptable correctes.  
Sense això, Odoo no estarà preparat per a facturar correctament.

Cal advertir que un **ajuntament no té la mateixa comptabilitat que una empresa**: el seu pla comptable és diferent i pot canviar segons la legislació vigent.  
Aquesta anàlisi i adaptació requereix una complexitat que s’escapa del propòsit del curs.  
Per tant, treballarem amb el **pla comptable espanyol per a empreses** per simplificar els exemples.
:::

---
### Creació i reconfiguració del Website

Quan instal·lem el mòdul **Website**, Odoo llança un **assistent inicial** que ens guia per a crear la web de l’empresa. Aquest *wizard* et permet:

- Seleccionar un **tema visual** (plantilla).  
- Triar colors i tipografia corporativa.  
- Generar una primera pàgina editable amb el **Website Builder**.

```{image} /_static/assets/img/Tema3/assitent.png
:alt: Assistent de selecció de tema en Website
:width: 100%
:align: center
```
*Pantalla de l’assistent inicial per a seleccionar un tema i crear la web.*

:::{admonition} Tornar a llançar el wizard
:class: tip
Encara que l’assistent només apareix la primera vegada, hi ha diverses maneres de repetir-lo o simular-lo:


1. **Crear una web nova**  
   - A partir d’Odoo 16 pots tindre més d’una web per base de dades.  
   - Menú: **Webs > Configuració > Webs > Crear**.  
   - En crear-ne una de nova, s’activa de nou l’assistent de selecció de tema.

2. **Reinstal·lar el mòdul Website**  
   - Només recomanat en entorns de prova.  
   - Desinstal·lar i tornar a instal·lar el mòdul fa que el wizard es mostre com si fóra la primera vegada.  
   - ⚠️ Aquesta acció elimina també les pàgines i configuracions prèvies de la web.
:::

:::{admonition} Recomanació docent
:class: warning
Per a practicar a classe, és més segur **crear una web nova**, en lloc de reinstal·lar el mòdul.  
La reinstal·lació pot provocar pèrdua de dades i només és viable en una base de dades de proves.
:::


---

## Annex: Casos pràctics per a analitzar

Encara que **no crearem mòduls** en aquest punt del curs, és important entendre com Odoo pot donar resposta a necessitats reals d’una organització.  

### A. Digitalització d’expedients en paper
Molts ajuntaments tenen **estanteries plenes d’expedients vius en paper** que ocupen molt d’espai i resulten difícils de consultar.  
Un projecte pilot podria consistir en:  
- Assignar un **número d’expedient** únic.  
- Digitalitzar i indexar documents.  
- Consultar-los via Odoo de forma segura.  
- Reduir espai físic i millorar l’accessibilitat.

### B. Gestió d’una responsabilitat patrimonial
Quan un veí reclama una **responsabilitat patrimonial** (per exemple, danys en un vehicle per mal estat d’un carrer), cal obrir un **expedient complet**.  
Odoo podria donar suport al procés mitjançant un mòdul de gestió d’expedients que permeta:  
- Iniciar la reclamació amb dades del sol·licitant.  
- Requerir documentació i informes tècnics.  
- Assignar tasques a diferents rols (TAG, policia, tècnics).  
- Tindre un flux de validació i resolució.

:::{admonition} Exemple interactiu
:class: tip
Consulta l’exemple de flux al fitxer <a href="ResponsabilitatPatrimonial.html" target="_blank" rel="noopener noreferrer">ResponsabilitatPatrimonial</a>.
:::
