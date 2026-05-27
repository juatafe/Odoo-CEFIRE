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
git clone --depth 1 --branch 19.0 https://github.com/OCA/server-ux.git /tmp/server-ux
cp -r /tmp/server-ux/base_technical_features ./dev_addons/
cp -r /tmp/server-ux/date_range ./dev_addons/
rm -rf /tmp/server-ux

# --- PART 2: L10N-SPAIN ---
echo "--- Descarregant de l10n-spain ---"
git clone --depth 1 --branch 19.0 https://github.com/OCA/l10n-spain.git /tmp/l10n-spain
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
git clone --depth 1 --branch 19.0 https://github.com/OCA/bank-payment.git /tmp/bank-payment
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
wget -q https://github.com/OCA/mis-builder/archive/refs/heads/19.0.zip -O /tmp/mis.zip
unzip -q /tmp/mis.zip -d /tmp/ && cp -r /tmp/mis-builder-19.0/mis_builder ./dev_addons/

git clone --depth 1 --branch 19.0 https://github.com/OCA/reporting-engine.git /tmp/rep
cp -r /tmp/rep/report_xlsx ./dev_addons/
cp -r /tmp/rep/report_xml ./dev_addons/
cp -r /tmp/rep/report_xlsx_helper ./dev_addons/
rm -rf /tmp/*.zip /tmp/mis-builder-19.0 /tmp/rep



# --- PART 5: REPOS RESTANTS (AFEGIT MÒDUL CRÍTIC) ---
echo "--- Descarregant eines financeres i reporting ---"
git clone --depth 1 --branch 19.0 https://github.com/OCA/account-financial-tools.git /tmp/tools
cp -r /tmp/tools/account_lock_date_update ./dev_addons/
cp -r /tmp/tools/account_chart_update ./dev_addons/
cp -r /tmp/tools/account_asset_management ./dev_addons/

git clone --depth 1 --branch 19.0 https://github.com/OCA/account-financial-reporting.git /tmp/af-rep
cp -r /tmp/af-rep/account_financial_report ./dev_addons/
cp -r /tmp/af-rep/account_tax_balance ./dev_addons/

git clone --depth 1 --branch 19.0 https://github.com/OCA/bank-statement-import.git /tmp/bs-imp
cp -r /tmp/bs-imp/account_statement_import_base ./dev_addons/
cp -r /tmp/bs-imp/account_statement_import ./dev_addons/
cp -r /tmp/bs-imp/account_statement_import_base ./dev_addons/account_statement_base

git clone --depth 1 --branch 19.0 https://github.com/OCA/account-payment.git /tmp/acc-pay
cp -r /tmp/acc-pay/account_due_list ./dev_addons/

git clone --depth 1 --branch 19.0 https://github.com/OCA/account-reconcile.git /tmp/rec

cp -r /tmp/rec/account_reconcile_oca ./dev_addons/
cp -r /tmp/rec/account_mass_reconcile ./dev_addons/
cp -r /tmp/rec/account_move_line_reconcile_manual ./dev_addons/
cp -r /tmp/rec/account_move_reconcile_forbid_cancel ./dev_addons/

rm -rf /tmp/rec

echo "--- Descarregant credit-control ---"
git clone --depth 1 --branch 19.0 https://github.com/OCA/credit-control.git /tmp/credit-control
cp -r /tmp/credit-control/account_credit_control ./dev_addons/
cp -r /tmp/credit-control/account_financial_risk ./dev_addons/
rm -rf /tmp/credit-control

echo "--- Descarregant account-financial-tools (importació extractes) ---"
git clone --depth 1 --branch 19.0 https://github.com/OCA/account-financial-tools.git /tmp/account-financial-tools

cp -r /tmp/account-financial-tools/account_statement_import_base ./dev_addons/
cp -r /tmp/account-financial-tools/account_statement_import_file ./dev_addons/

rm -rf /tmp/account-financial-tools


# AQUESTA ÉS LA PEÇA QUE FALTAVA SEGONS EL LOG
echo "--- Descarregant community-data-files (base_bank_from_iban) ---"
git clone --depth 1 --branch 19.0 https://github.com/OCA/community-data-files.git /tmp/cdf
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
