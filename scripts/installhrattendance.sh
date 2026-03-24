#!/bin/bash

wait_odoo() {
  echo "⏳ Esperant que Odoo estiga llest..."
  until docker compose exec web odoo --version >/dev/null 2>&1; do
    sleep 5
  done
}

# 1. DESCÀRREGA (Bajamos el repositorio de asistencias de la OCA)
echo "--- Descarregant repositori OCA HR-Attendance ---"
rm -rf /tmp/hr-attendance
git clone --depth 1 --branch 16.0 https://github.com/OCA/hr-attendance.git /tmp/hr-attendance

# 2. COPIAT (Copiamos el módulo específico de geolocalización)
echo "--- Copiant mòdul hr_attendance_geolocation ---"
cp -r /tmp/hr-attendance/hr_attendance_geolocation ./dev_addons/

# Limpiamos temporal
rm -rf /tmp/hr-attendance

# 3. LLIBRERIES PYTHON (Este módulo no suele pedir extras, pero aseguramos dependencias básicas)
echo "--- Instal·lant dependències (si calen) ---"
# Generalmente usa librerías estándar de Odoo para coordenadas

# 4. DESBLOQUEJAR DB
echo "--- Netejant estats anteriors ---"
docker compose exec db psql -U odoo -d cpa -c "UPDATE ir_module_module SET state='uninstalled' WHERE state IN ('to install', 'to upgrade');"

# 5. ACTUALITZAR LLISTA I INSTAL·LAR
echo "--- Registrant mòduls nous ---"
docker compose exec web odoo -d cpa -u base --stop-after-init

echo "--- Instal·lant hr_attendance_geolocation ---"
# Instalamos primero el módulo base de asistencias y luego el de geolocalización
docker compose exec web odoo -d cpa -i hr_attendance --stop-after-init
docker compose exec web odoo -d cpa -i hr_attendance_geolocation --stop-after-init

# 6. REINICI
docker compose restart web
wait_odoo

echo "----------------------------------------------------"
echo "GEOLOCALITZACIÓ INSTAL·LADA AMB ÈXIT"
echo "----------------------------------------------------"