
## Introducció

Odoo ofereix una base sòlida per a la gestió comptable, però la versió Community no incorpora totes les funcionalitats avançades disponibles en Enterprise. Per això, quan treballem en un entorn real —com el d’un club esportiu— és imprescindible ampliar el sistema amb mòduls addicionals, especialment els de la comunitat OCA (Odoo Community Association).

En aquest capítol aprendrem a preparar correctament l’entorn comptable d’Odoo 16 Community per a complir amb la normativa espanyola. Instal·larem la localització `l10n_es`, afegirem mòduls d’informes com `l10n_es_mis_report` i integrarem eines per a generar fitxers oficials de l’AEAT. A més, abordarem un aspecte fonamental que sovint es passa per alt: la gestió adequada de les dependències de Python dins de Docker.

Però aquest tema no és només tècnic. L’objectiu real és entendre com s’estructura la comptabilitat dins d’Odoo: els diaris, el pla comptable, les factures, els informes fiscals i la relació amb el Pla General Comptable (PGC). No es tracta de convertir-se en assessor fiscal, sinó de comprendre com es classifiquen i interpreten els moviments econòmics d’una entitat.

Aquest capítol connecta directament amb el cas pràctic del club de patinatge, on la correcta configuració del sistema marcarà la diferència entre una comptabilitat funcional i un entorn ple d’errors i inconsistències.



```{danger}
Si encara no domines la instal·lació de mòduls o la gestió bàsica d’Odoo, és recomanable que revises els temes anteriors abans de continuar. Un ordre incorrecte d’instal·lació o una dependència mal gestionada pot deixar la base de dades en un estat inconsistent. Fes còpies de seguretat abans de fer canvis importants i segueix els passos amb cura.
```

::::{image} /_static/assets/img/Tema9/modul-l10n_es.png
:alt: Odoo Comptabilitat
::::

::: {admonition} Objectius del tema
:class: tip
- Entendre quins mòduls extra necessites i per a què.
- Baixar-los de repositoris OCA de forma segura (branch correcte).
- Instal·lar dependències Python i ajustar el Dockerfile.
- Verificar la instal·lació i resoldre errors comuns.
:::

---

## Requisits previs
- Odoo 16.0 (el tema usa branques 16.0 d’OCA).
- Entorn Docker en marxa (docker compose up).
- Un directori d’addons de desenvolupament (per exemple ./dev_addons) muntat al contenidor d’Odoo.
- Git i, si uses els ZIPs, unzip instal·lat.
- Permisos per reconstruir la imatge (docker compose build).

::: {admonition} Bones pràctiques
:class: note
- Treballa sempre amb `--branch 16.0` als repos OCA per evitar incompatibilitats.  
- Copia només els mòduls necessaris al teu `dev_addons` (no tot el repo).
:::

---

### Gestió de dependències de Python
Molts mòduls de l'OCA depenen de llibreries externes de Python per a realitzar càlculs complexos o generar fitxers (com l'Excel o els XML bancaris). Si aquestes llibreries no estan instal·lades, Odoo llançarà un error de "mòdul no trobat" en intentar instal·lar l'App.


Les llibreries clau que necessitarem són:

1) XlsxWriter: Per a la generació d'informes en format Excel.
2) sepaxml: Per a la creació dels fitxers de remeses bancàries SEPA.
3) python-stdnum: Per a la validació de NIFs, IBANs i altres identificadors estàndards. 

---

Caldria canviar el Dockerfile per incloure aquests paquets de Python.  
Canvia el que teníem:
```bash
FROM odoo:16.0
USER root
RUN pip install pypdf Pillow reportlab
RUN pip uninstall jinja2 markupsafe -y && \
    pip install jinja2==3.1.2 markupsafe==2.1.1 requests pandas && \
    mkdir -p /var/log/odoo && \
    chown -R odoo:odoo /var/log/odoo
COPY ./dev_addons/* /mnt/extra-addons/
USER odoo
WORKDIR /mnt/extra-addons
```

per aquest:
```bash
FROM odoo:16.0

USER root

# Instal·lem el que és segur i necessari (XlsxWriter per a Excel i sepaxml per a rebuts)
#RUN pip install pypdf Pillow reportlab XlsxWriter sepaxml python-stdnum
RUN pip install pypdf Pillow reportlab XlsxWriter sepaxml python-stdnum requests pandas==1.5.3 schwifty==2024.4.0

# El teu bloc original (mantenim requests i pandas que ja et funcionaven)
RUN pip uninstall jinja2 markupsafe -y && \
    pip install jinja2==3.1.2 markupsafe==2.1.1 requests pandas && \
    mkdir -p /var/log/odoo && \
    chown -R odoo:odoo /var/log/odoo

COPY ./dev_addons/ /mnt/extra-addons/

USER odoo
WORKDIR /mnt/extra-addons
```

Caldrà fer un build nou de la imatge Docker després de modificar el Dockerfile:
```bash
docker compose build 
```
Després de fer això, ja podràs instal·lar els mòduls sense problemes de dependències.

---

## Instal·lació dels mòduls necessaris
No instal·les res encara. Observa els passos per a instal·lar mòduls de l’OCA de forma segura i més tard ho faràs tot d’una vegada amb un script bash.
### Descarregar i copiar mòduls
Els mòduls d’OCA estan organitzats en repositoris grans que contenen molts mòduls relacionats. Per exemple, el repositori `l10n-spain` conté tots els mòduls relacionats amb la localització espanyola. No obstant això, no és recomanable clonar tot el repositori dins del teu directori d’addons, ja que això pot generar conflictes i augmentar la mida del teu entorn de desenvolupament.

Posem per cas que volem poc a poc instal·lar un mòdul. Per exemple, instal·larem el mòdul `base_technical_features` (OCA server-ux). Proporciona utilitats tècniques útils també en context comptable. Executa aquests passos DINS del teu directori de desenvolupament (p. ex. ./dev_addons):

```bash
# 1. Clona el repo sencer en un directori temporal
git clone --depth 1 --branch 16.0 https://github.com/OCA/server-ux.git /tmp/server-ux

# 2. Copia només la carpeta que t'interessa al teu dev_addons
cp -r /tmp/server-ux/base_technical_features .

# 3. Esborra el temporal
rm -rf /tmp/server-ux
```

Perquè aparega el nou mòdul caldrà reiniciar el servidor d’Odoo i actualitzar la llista de mòduls . Un volta fet això, anirem a l’apartat d’Apps dins d’Odoo i farem clic a “_Update Apps List_”. Després, busquem “_Base Technical Features_” i l’instal·lem.
:::{image} /_static/assets/img/Tema9/instalar-base-technical.png
:alt: Instal·lar mòdul Base Technical Features
:::

Un mòdul útil que podem instal·lar és el `l10n_es_mis_reports`, que proporciona informes específics per a la comptabilitat espanyola. Per instal·lar aquest mòdul:

```bash
# 1. Clona el repo sencer en un directori temporal
git clone --depth 1 --branch 16.0 https://github.com/OCA/l10n-spain.git /tmp/l10n-spain 
# 2. Copia només la carpeta que t'interessa al teu dev_addons
cp -r /tmp/l10n-spain/l10n_es_mis_report .
# 3. Esborra el temporal
rm -rf /tmp/l10n-spain
```

Però alguns mòduls poden requerir que altres estiguen instal·lats, en aquest cas assegura’t que `mis-builder` està instal·lat (dependència de `l10n_es_mis_report`):
```bash
# 1. Clona el repo sencer en un directori temporal
git clone --depth 1 --branch 16.0 https://github.com/OCA/mis-builder.git /tmp/mis-builder
# 2. Copia només la carpeta que t'interessa al teu dev_addons
cp -r /tmp/mis-builder/mis_builder .
# 3. Esborra el temporal
rm -rf /tmp/mis-builder
```
:::{image} /_static/assets/img/Tema9/mis-builder-instal.png
:alt: Instal·lar mòdul l10n_es_mis_reports
:::

Aquest mòdul també depèn del mòdul `report_xlsx`; instal·la’l igualment:

```bash
# 1. Clona el repo sencer en un directori temporal
git clone --depth 1 --branch 16.0 https://github.com/OCA/reporting-engine.git /tmp/rep
# 2. Copia els mòduls necessaris al teu dev_addons
cp -r /tmp/rep/report_xlsx ./dev_addons/
cp -r /tmp/rep/report_xml ./dev_addons/
cp -r /tmp/rep/report_xlsx_helper ./dev_addons/
# 3. Neteja temporals
rm -rf /tmp/rep
```
Un vegada instal·lats, podreu accedir a informes comptables d’Espanya. El que ocorre és que primer cal afegir el vostre usuari al grup que permet accedir a dits informes. Més endavant veurem com fer-ho.

---
### Script bash per a instal·lació massiva
Com que hem de copiar molts mòduls, és millor automatitzar el procés amb un script bash. A més un usuari novell podria cometre errors en copiar i enganxar els passos manuals. S'ha preparat un script que descarrega i copia tots els mòduls necessaris per a la comptabilitat espanyola. Almenys el més bàsic que necessitarem per a gestionar la comptabilitat amb Odoo Community i el cas concret d'un club esportiu.

L'escript el que fa és:
1. Protegir els teus mòduls propis (escola, patinatge, etc.) fent una còpia de seguretat temporal.
2. Netejar el directori `dev_addons` per evitar conflictes.
3. Restaurar els teus mòduls propis.
4. Descarregar i copiar els mòduls OCA necessaris.
5. Instal·lar els mòduls en l'ordre correcte per evitar errors de dependències i recurrències.
6. Mostrar un resum final.


```{tip}

**Script d'instal·lació massiva de mòduls OCA per a comptabilitat espanyola**

**Descarregar :** [comptabilitat.sh](../../_static/scripts/comptabilitat.sh)

Aquest script desa automàticament els mòduls OCA en `./dev_addons` i fa una instal·lació bàsica. Alguns no els instal·la però els deixa a punt per a que els instal·les més endavant si cal. Això és per evitar problemes de dependències i recurrències.

```

## Habilitar els menús de comptabilitat
Aquest és un pas crític. En Odoo Community, molts menús de comptabilitat romanen ocults fins i tot després d'instal·lar els mòduls si l'usuari no té els permisos adequats. 


### Configuració de l'usuari Administrador comptable

Per a tindre accés total a la comptabilitat (factures, pla comptable, informes AEAT), cal configurar l'usuari que actuarà com a administrador comptable:

1. Activa el Mode desenvolupador.
   Pots fer-ho de dues maneres:
      - Configuració → “Activar mode desenvolupador”
      - Afegeix `?debug=1` a l’URL de Odoo i recarrega la pàgina.
1. Ves a _Configuració → Usuaris i empreses → Usuaris_.
1. Selecciona l'usuari en concret.
1. A la pestanya Permisos d'accés, busca la secció Accounting (o Comptabilitat).
1. Selecciona l'opció Administrador de facturació (Billing Administrator).

:::{caution} 
**Important: Permisos Tècnics**

A més del rol anterior, per a veure el Pla Comptable i opcions avançades, Caldrà activar el mode desenvolupador i anar a _Configuració → Usuaris i empreses → Grups_, buscar i assignar aquests grups a l'usuari:
- _Tècnic / Mostra les funcions comptables completes_
- _Tècnic / Mostra el menú d'ingressos recurrents_ 
- _Tècnic / Comptabilitat analítica_

Cal fer logout i login perquè tinga efecte
:::

:::{image} /_static/assets/img/Tema9/habilitarCompatibilitat.png
:alt: Habilitar grups de comptabilitat
:width: 100%
:class: center-img
:::

:::{image} /_static/assets/img/Tema9/habilitarCompatibilitat2.png
:alt: Habilitar grups de comptabilitat
:width: 100%
:class: center-img
:::

```{caution}

Després d’assignar grups a un usuari, cal tancar sessió i tornar a entrar perquè els canvis tinguen efecte.
```


## Verificació i diagnòstic ràpid
En entrar en facturació, si tot ha anat bé, hauríem de vore el pla comptable, els diaris i altres menús relacionats amb la comptabilitat sense errors. 

:::{image} /_static/assets/img/Tema9/menu-facturacio.png
:alt: Pla comptable OK
:width: 100%
:class: center-img
:::




:::{dropdown} Diagnòstic ràpid d'errors comuns
:class-container: tip

### Diagrama de dependències de la Comptabilitat Espanyola

Aquest diagrama mostra l'ordre lògic de càrrega. Els mòduls de la base han d'estar presents i instal·lats perquè els mòduls superiors puguen estendre les seues funcionalitats sense errors de "camp inexistent".

```{image} /_static/assets/img/Tema9/diagrama-mermaid.png
:alt: Diagrama de dependències de la comptabilitat espanyola
:width: 100%
:class: center-img

```


#### Explicació de les capes de dependència

```{eval-rst}
.. list-table::
   :widths: 30 70
   :header-rows: 1

   * - Capa
     - Mòduls i Funció
   * - **1. Fonaments** (Infraestructura)
     - * **base_technical_features**: Activa opcions ocultes del sistema.
       * **report_xlsx**: Necessari per a exportar informes a Excel.
       * **date_range**: Permet definir períodes (trimestres/anys) per als informes fiscals.
   * - **2. Financera Base** (Actius)
     - * **account_asset_management**: **CRÍTIC.** Gestiona béns d'inversió. Evita l'error del camp ``asset_count`` en les factures.
   * - **3. Localització** (País)
     - * **l10n_es**: Carrega el PGCE (Pla Comptable) i els impostos (IVA).
       * **l10n_es_partner**: Camps específics per a empreses espanyoles (CNAE, IBAN corregit).
   * - **4. Reporting i AEAT**
     - * **mis_builder**: El motor que dibuixa els informes financers.
       * **l10n_es_mis_report**: Plantilles oficials de Balanç i Pèrdues i Guanys.
       * **l10n_es_aeat_modXXX**: Mòduls per a generar els fitxers oficials per a la seu de l'AEAT.
```

---

``` {tip}

Si intentes instal·lar un mòdul de la **Capa 4** sense haver passat per la **Capa 2**, Odoo intentarà instal·lar les dependències automàticament, però de vegades l'ordre de càrrega de les vistes falla (especialment en el frontend). L'script que hem proporcionat assegura que "pugem l'escala" graó a graó per evitar corrompre la base de dades.
```
---
### Actualitzar llista d’apps i instal·lar
Tot i executar l'script alguns mòduls poden no estar instal·lats correctament. Per assegurar que tots els mòduls estan instal·lats correctament es pot fer el següent:
- Apps → Update Apps List → busca i instal·la els mòduls copiats. De moment instal·la, si no estan ja,  `base_technical_features`, `l10n_es`, `mis_builder`,`l10n_es_mis_report`, `l10n_es_aeat`,`l10n_es_aeat_111` i`l10n_es_aeat_303`.
  
```{image} /_static/assets/img/Tema9/aeat-moduls.png
:alt: Actualitzar llista d'apps
```

```{image} /_static/assets/img/Tema9/l10n-install.png
:alt: Instal·lar mòduls l10n_es
```

- Alternativa CLI:
```bash
docker compose exec web odoo -d cpa -u base --stop-after-init
docker compose exec web odoo -d cpa -i l10n_es,mis_builder,l10n_es_mis_report,report_xlsx --stop-after-init
```
---
### Errors típics i solucions
- ModuleNotFoundError: instal·la el paquet Python i refés la imatge si cal.
- Versió de branch incorrecta: clona sempre amb `--branch 16.0`.
- Mòdul no apareix a Apps: revisa que `dev_addons` estiga a l’addons_path del contenidor i fes “Update Apps List”.

#### Resolució d'errors comuns: El camp "asset_count"
En instal·lar la localització espanyola (`l10n_es_aeat`) en Odoo Community, pots trobar un error de JavaScript (Uncaught Promise) que bloqueja el menú de Facturació. L’error indica que falta el camp `asset_count`.

Per què passa?
- El mòdul de l’AEAT intenta mostrar a la factura un botó d’immobilitzat (actius).
- Si `account_asset_management` no està instal·lat i actualitzat abans de carregar la vista, Odoo trenca amb el camp inexistent.

Com evitar-ho (ordre correcte a Apps):
1) Instal·lar `account_asset_management`.  
2) Instal·lar `l10n_es_aeat`.

Com solucionar-ho si ja ha “petat”:
1) Netejar la vista corrupta a la base de dades
- Entra a psql dins del contenidor:
```bash
docker compose exec db psql -U odoo -d cpa
```
- I executa la neteja:
```sql
DELETE FROM ir_ui_view WHERE arch_db::text LIKE '%asset_count%';
```

2) Forçar la instal·lació/actualització des de la terminal
```bash
docker compose exec web odoo -d cpa -i account_asset_management -u l10n_es_aeat --stop-after-init
docker compose restart web
```

3) Regenerar els assets del frontend
- Entra a Odoo amb `?debug=assets` a l’URL.  
- Obri la icona de debug (“bestioleta”) i selecciona “Regenerate Assets Bundles”.

``` {caution}
Aquest problema apareix quan la vista fa referència a camps d’un mòdul que encara no existeix. L’ordre d’instal·lació és clau.
```

``` {tip}
Si tornes a vore l’error, repeteix el pas de neteja i assegura l’ordre: primer `account_asset_management`, després `l10n_es_aeat`.
```


:::




## Resum
En aquest tema hem après a:
- Quins mòduls OCA són essencials per a la comptabilitat espanyola.
- Com descarregar-los de manera segura i copiar-los al teu entorn.
- Com gestionar les dependències de Python necessàries.
- Com instal·lar els mòduls en l’ordre correcte per evitar errors.
- Com solucionar problemes comuns, com l’error del camp `asset_count`.
Amb aquests coneixements, estàs preparat per a gestionar la comptabilitat de la teva organització amb Odoo Community de manera efectiva i complint amb les normatives locals.