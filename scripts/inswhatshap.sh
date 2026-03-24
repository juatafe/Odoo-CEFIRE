#!/bin/bash

wait_odoo() {
  echo "⏳ Esperant que Odoo estiga llest..."
  until docker compose exec web odoo --version >/dev/null 2>&1; do
    sleep 5
  done
}

# 1. DESCÀRREGA (Netegem i baixem només el repositori social)
echo "--- Descarregant repositori OCA Social ---"
rm -rf /tmp/social
git clone --depth 1 --branch 16.0 https://github.com/OCA/social.git /tmp/social

# 2. COPIAT (Basat en el que veiem a la teva imatge)
echo "--- Copiant mòduls des de /tmp/social ---"
# Tots aquests estan a la llista de la teva imatge:
cp -r /tmp/social/mail_gateway ./dev_addons/
cp -r /tmp/social/mail_gateway_whatsapp ./dev_addons/

# Netegem temporal
rm -rf /tmp/social

# 3. LLIBRERIES PYTHON (Afegim la que demana el manifest: requests_toolbelt)
echo "--- Instal·lant dependències de Python ---"
docker compose exec -u root web pip install phonenumbers requests_toolbelt

# 4. DESBLOQUEJAR DB
echo "--- Netejant estats anteriors ---"
docker compose exec db psql -U odoo -d cpa -c "UPDATE ir_module_module SET state='uninstalled' WHERE state IN ('to install', 'to upgrade');"

# 5. ACTUALITZAR LLISTA I INSTAL·LAR
echo "--- Registrant mòduls nous ---"
docker compose exec web odoo -d cpa -u base --stop-after-init

echo "--- Instal·lant final ---"
# Instal·lem primer la dependència i després el de whatsapp
docker compose exec web odoo -d cpa -i mail_gateway,phone_validation --stop-after-init
docker compose exec web odoo -d cpa -i mail_gateway_whatsapp --stop-after-init

# 6. REINICI
docker compose restart web
wait_odoo

echo "----------------------------------------------------"
echo "WHATSAPP INSTAL·LAT AMB ÈXIT"
echo "----------------------------------------------------"