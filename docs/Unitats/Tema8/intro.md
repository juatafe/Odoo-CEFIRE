
## Introducció
Odoo proporciona una base sòlida per a la gestió comptable, però per a adaptar-se a les necessitats específiques d’un país o sector, sovint cal instal·lar mòduls addicionals. A més, la versió Community d’Odoo no inclou totes les funcionalitats comptables que es troben a la versió Enterprise, per la qual cosa els mòduls addicionals són essencials per a una gestió completa. També cal assegurar-se que les dependències de Python estan correctament instal·lades per a evitar errors durant la instal·lació dels mòduls.

Anem instal·lar una sèrie de mòduls per a gestionar la comptabilitat de l’empresa amb Odoo. Aquests mòduls permeten portar un control de finances, generar informes i complir amb obligacions fiscals. El mòdul comptable bàsic d’Odoo ja inclou molta funcionalitat; per a una gestió més avançada, afegirem la localització espanyola `l10n_es` i altres mòduls relacionats.

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

:::{dropdown} Codi de l'script bash per a descarregar i copiar mòduls
:class-container: info

```bash
#!/bin/bash
wait_odoo() {
  echo "⏳ Esperant que Odoo estiga llest..."
  until docker compose exec web odoo --version >/dev/null 2>&1; do
    sleep 5
  done
}


# 1. PROTECCIÓ DELS TEUS MÒDULS PROPIS
echo "--- Salvant mòduls propis a /tmp ---"
mkdir -p /tmp/odoo_backups
# Copiem només si existeixen per evitar errors en la primera execució
[ -d "./dev_addons/escola" ] && cp -r ./dev_addons/escola /tmp/odoo_backups/
[ -d "./dev_addons/patinatge" ] && cp -r ./dev_addons/patinatge /tmp/odoo_backups/
[ -d "./dev_addons/patinatge_inscripcio" ] && cp -r ./dev_addons/patinatge_inscripcio /tmp/odoo_backups/
[ -d "./dev_addons/odoo-cpa-addons" ] && cp -r ./dev_addons/odoo-cpa-addons /tmp/odoo_backups/

# 2. NETEJA SEGURA
echo "--- Netejant dev_addons per actualitzar repositoris OCA ---"
rm -rf ./dev_addons/*
mkdir -p ./dev_addons


# 3. RESTAURACIÓ IMMEDIATA
if [ -d "/tmp/odoo_backups" ] && [ "$(ls -A /tmp/odoo_backups)" ]; then
    cp -r /tmp/odoo_backups/* ./dev_addons/
    echo "--- Mòduls propis restaurats ---"
else
    echo "--- No hi havia mòduls propis per restaurar ---"
fi


# Comprovem si unzip està instal·lat
if ! command -v unzip &> /dev/null; then
    echo "Instal·lant unzip..."
    sudo apt-get update && sudo apt-get install -y unzip
fi

mkdir -p ./dev_addons

# --- PART 1: SERVER-UX ---
echo "--- Descarregant de server-ux ---"
git clone --depth 1 --branch 16.0 https://github.com/OCA/server-ux.git /tmp/server-ux
cp -r /tmp/server-ux/base_technical_features ./dev_addons/
cp -r /tmp/server-ux/date_range ./dev_addons/
rm -rf /tmp/server-ux

# --- PART 2: L10N-SPAIN ---
echo "--- Descarregant de l10n-spain ---"
git clone --depth 1 --branch 16.0 https://github.com/OCA/l10n-spain.git /tmp/l10n-spain
MODULES_SPAIN=(
    "l10n_es_aeat" "l10n_es_aeat_mod111" "l10n_es_aeat_mod115" "l10n_es_aeat_mod123"
    "l10n_es_aeat_mod190" "l10n_es_aeat_mod216" "l10n_es_aeat_mod303" "l10n_es_aeat_mod303_oss"
    "l10n_es_aeat_mod347" "l10n_es_aeat_mod349" "l10n_es_aeat_mod369" "l10n_es_aeat_mod390"
    "l10n_es_partner" "l10n_es_account_asset" "l10n_es_account_statement_import_n43"
    "l10n_es_vat_book" "l10n_es_mis_report"
)
for MOD in "${MODULES_SPAIN[@]}"; do
    cp -r "/tmp/l10n-spain/$MOD" ./dev_addons/
done
rm -rf /tmp/l10n-spain

# --- PART 3: BANK-PAYMENT ---
echo "--- Descarregant de bank-payment ---"
git clone --depth 1 --branch 16.0 https://github.com/OCA/bank-payment.git /tmp/bank-payment
MODULES_BANK=(
    "account_banking_mandate"
    "account_banking_pain_base"
    "account_banking_sepa_credit_transfer"
    "account_banking_sepa_direct_debit"
    "account_payment_order"
    "account_payment_partner"
    "account_payment_mode"
    "account_payment_sale"
    "account_payment_purchase"
)

for MOD in "${MODULES_BANK[@]}"; do
    cp -r "/tmp/bank-payment/$MOD" ./dev_addons/
done
rm -rf /tmp/bank-payment


# --- PART 4: MIS-BUILDER & REPORTING ---
echo "--- Descarregant MIS Builder i Reporting Engine ---"
wget -q https://github.com/OCA/mis-builder/archive/refs/heads/16.0.zip -O /tmp/mis.zip
unzip -q /tmp/mis.zip -d /tmp/ && cp -r /tmp/mis-builder-16.0/mis_builder ./dev_addons/

git clone --depth 1 --branch 16.0 https://github.com/OCA/reporting-engine.git /tmp/rep
cp -r /tmp/rep/report_xlsx ./dev_addons/
cp -r /tmp/rep/report_xml ./dev_addons/
cp -r /tmp/rep/report_xlsx_helper ./dev_addons/
rm -rf /tmp/*.zip /tmp/mis-builder-16.0 /tmp/rep



# --- PART 5: REPOS RESTANTS (AFEGIT MÒDUL CRÍTIC) ---
echo "--- Descarregant eines financeres i reporting ---"
git clone --depth 1 --branch 16.0 https://github.com/OCA/account-financial-tools.git /tmp/tools
cp -r /tmp/tools/account_lock_date_update ./dev_addons/
cp -r /tmp/tools/account_chart_update ./dev_addons/
cp -r /tmp/tools/account_asset_management ./dev_addons/

git clone --depth 1 --branch 16.0 https://github.com/OCA/account-financial-reporting.git /tmp/af-rep
cp -r /tmp/af-rep/account_financial_report ./dev_addons/
cp -r /tmp/af-rep/account_tax_balance ./dev_addons/

git clone --depth 1 --branch 16.0 https://github.com/OCA/bank-statement-import.git /tmp/bs-imp
cp -r /tmp/bs-imp/account_statement_import_base ./dev_addons/
cp -r /tmp/bs-imp/account_statement_import ./dev_addons/
cp -r /tmp/bs-imp/account_statement_import_base ./dev_addons/account_statement_base

git clone --depth 1 --branch 16.0 https://github.com/OCA/account-payment.git /tmp/acc-pay
cp -r /tmp/acc-pay/account_due_list ./dev_addons/

git clone --depth 1 --branch 16.0 https://github.com/OCA/account-reconcile.git /tmp/rec

cp -r /tmp/rec/account_reconcile_oca ./dev_addons/
cp -r /tmp/rec/account_mass_reconcile ./dev_addons/
cp -r /tmp/rec/account_move_line_reconcile_manual ./dev_addons/
cp -r /tmp/rec/account_move_reconcile_forbid_cancel ./dev_addons/

rm -rf /tmp/rec

echo "--- Descarregant credit-control ---"
git clone --depth 1 --branch 16.0 https://github.com/OCA/credit-control.git /tmp/credit-control
cp -r /tmp/credit-control/account_credit_control ./dev_addons/
cp -r /tmp/credit-control/account_financial_risk ./dev_addons/
rm -rf /tmp/credit-control

echo "--- Descarregant account-financial-tools (importació extractes) ---"
git clone --depth 1 --branch 16.0 https://github.com/OCA/account-financial-tools.git /tmp/account-financial-tools

cp -r /tmp/account-financial-tools/account_statement_import_base ./dev_addons/
cp -r /tmp/account-financial-tools/account_statement_import_file ./dev_addons/

rm -rf /tmp/account-financial-tools


# AQUESTA ÉS LA PEÇA QUE FALTAVA SEGONS EL LOG
echo "--- Descarregant community-data-files (base_bank_from_iban) ---"
git clone --depth 1 --branch 16.0 https://github.com/OCA/community-data-files.git /tmp/cdf
cp -r /tmp/cdf/base_bank_from_iban ./dev_addons/

rm -rf /tmp/tools /tmp/af-rep /tmp/bs-imp /tmp/acc-pay /tmp/rec /tmp/cdf


echo "--- PRE-PAS: Desinstal·lant TPV per evitar conflictes amb el PGCE ---"
docker compose exec web odoo -d cpa -u point_of_sale --stop-after-init
docker compose restart web
wait_odoo



# --- PART 6: INSTAL·LACIÓ ESTRATÈGICA (CORREGIDA PER EVITAR RECURRÈNCIA) ---
echo "--- Netejant vistes i estats que bloquegen la instal·lació ---"
docker compose exec db psql -U odoo -d cpa -c "DELETE FROM ir_ui_view WHERE arch_db::text LIKE '%asset_count%' OR arch_db::text LIKE '%thirdparty_invoice%';"
docker compose exec db psql -U odoo -d cpa -c "UPDATE ir_module_module SET state='uninstalled' WHERE state IN ('to install', 'to upgrade', 'to remove');"

echo "--- PAS 0: Instal·lant dependència de dades IBAN ---"
docker compose exec web odoo -d cpa -i base_bank_from_iban --stop-after-init

echo "--- PAS 1: Instal·lant Fonaments (Actius i Tècnics) ---"
docker compose exec web odoo -d cpa -i base_technical_features,account_asset_management,report_xlsx,mis_builder,date_range --stop-after-init

echo "--- PAS 2: Instal·lant l'estructura de l'AEAT ---"
docker compose exec web odoo -d cpa -i l10n_es,l10n_es_aeat,l10n_es_partner --stop-after-init

docker compose restart web
wait_odoo
echo "--- PAS 3: Instal·lant mòduls funcionals finals (sense recurrències) ---"
docker compose exec web odoo -d cpa -i \
l10n_es_aeat_mod111,\
l10n_es_aeat_mod115,\
l10n_es_aeat_mod123,\
l10n_es_aeat_mod190,\
l10n_es_aeat_mod216,\
l10n_es_aeat_mod303,\
l10n_es_aeat_mod347,\
l10n_es_aeat_mod349,\
l10n_es_aeat_mod390,\
l10n_es_mis_report,\
l10n_es_account_asset,\
account_banking_sepa_direct_debit,\
account_banking_sepa_credit_transfer,\
l10n_es_account_statement_import_n43 \
--stop-after-init

docker compose restart web
wait_odoo


echo "--- CHECK ABANS DEL PAS 4 ---"
for MOD in \
account_due_list \
account_payment_order \
account_payment_partner \
account_payment_sale \
account_payment_purchase \
account_mass_reconcile \
account_move_line_reconcile_manual \
account_move_reconcile_forbid_cancel \
account_credit_control \
account_financial_risk
do
  [ -d "./dev_addons/$MOD" ] || { echo "❌ FALTA $MOD"; exit 1; }
done
echo "✔️ Tots els mòduls del PAS 4 estan presents"


docker compose restart web
wait_odoo

echo "--- PAS 4A: Conciliació base ---"
docker compose exec web odoo -d cpa -i \
account_move_line_reconcile_manual,\
account_move_reconcile_forbid_cancel,\
account_mass_reconcile \
--stop-after-init

docker compose restart web
wait_odoo

echo "--- PAS 4B: Pagaments ---"
docker compose exec web odoo -d cpa -i \
account_payment_partner,\
account_payment_order,\
account_payment_purchase,\
account_payment_sale,\
account_due_list \
--stop-after-init

docker compose restart web
wait_odoo

echo "--- PAS 4C: Risc financer ---"
docker compose exec web odoo -d cpa -i \
account_financial_risk \
--stop-after-init

docker compose restart web
wait_odoo

echo "--- PAS 4D: Credit Control (L'ÚLTIM) ---"
docker compose exec web odoo -d cpa -i \
account_credit_control \
--stop-after-init

docker compose restart web
wait_odoo


echo "--- POST-PAS: Reinstal·lant TPV ---"
docker compose exec web odoo -d cpa -i point_of_sale --stop-after-init
docker compose restart web
wait_odoo

# Afegeix això al final de tot del teu script (PAS 6)
echo "--- PAS FINAL: Instal·lant mòduls propis ---"
docker compose exec web odoo -d cpa -i escola,patinatge,patinatge_inscripcio --stop-after-init
docker compose restart web
wait_odoo

echo "--- CHECK FINAL: Estat dels mòduls ---"
docker compose exec db psql -U odoo -d cpa -c "
SELECT name, state
FROM ir_module_module
WHERE state != 'installed'
ORDER BY state, name;
"

# --- RESUM FINAL ---
echo "----------------------------------------------------"
echo "PROCÉS FINALITZAT CORRECTAMENT"
echo "----------------------------------------------------"
echo "Total mòduls en ./dev_addons: $(ls -1 ./dev_addons | wc -l)"

```
::: 

Aquest script desa automàticament els mòduls OCA en `./dev_addons` i fa una instal·lació bàsica. Alguns no els instal·la però els deixa a punt per a que els instal·les més endavant si cal. Això és per evitar problemes de dependències i recurrències.

---
## Habilitar els menús de comptabilitat
Aquest és un pas crític. En Odoo Community, molts menús de comptabilitat romanen ocults fins i tot després d'instal·lar els mòduls si l'usuari no té els permisos adequats. 


### Configuració de l'usuari Administrador comptable

Per a tindre accés total a la comptabilitat (factures, pla comptable, informes AEAT), cal configurar l'usuari que actuarà com a administrador comptable:

- Activa el Mode desenvolupador.
  - Activa’l així:
    - Configuració → “Activar mode desenvolupador”, o
    - Afegeix `?debug=1` a l’URL de Odoo i recarrega la pàgina.
- Ves a _Configuració → Usuaris i empreses → Usuaris_.
- Selecciona l'usuari en concret.
- A la pestanya Permisos d'accés, busca la secció Accounting (o Comptabilitat).
- Selecciona l'opció Administrador de facturació (Billing Administrator).

::: {admonition} Important: Permisos Tècnics
:class: warning
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

:::{admonition} Recorda
:class: note
Després d’assignar grups a un usuari, cal tancar sessió i tornar a entrar perquè els canvis tinguen efecte.
:::
---

## Verificació i diagnòstic ràpid
En entrar en facturació, si tot ha anat bé, hauríem de vore el pla comptable, els diaris i altres menús relacionats amb la comptabilitat sense errors. 

:::{image} /_static/assets/img/Tema9/menu-facturacio.png
:alt: Pla comptable OK
:width: 100%
:class: center-img
:::


---

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

``` {admonition} Consell per a l'alumne
:class: tip

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

``` {admonition} Recorda
:class: note
Aquest problema apareix quan la vista fa referència a camps d’un mòdul que encara no existeix. L’ordre d’instal·lació és clau.
```

``` {admonition} Consell ràpid
:class: tip
Si tornes a vore l’error, repeteix el pas de neteja i assegura l’ordre: primer `account_asset_management`, després `l10n_es_aeat`.
```


:::
---



## Resum
En aquest tema hem après a:
- Quins mòduls OCA són essencials per a la comptabilitat espanyola.
- Com descarregar-los de manera segura i copiar-los al teu entorn.
- Com gestionar les dependències de Python necessàries.
- Com instal·lar els mòduls en l’ordre correcte per evitar errors.
- Com solucionar problemes comuns, com l’error del camp `asset_count`.
Amb aquests coneixements, estàs preparat per a gestionar la comptabilitat de la teva organització amb Odoo Community de manera efectiva i complint amb les normatives locals.