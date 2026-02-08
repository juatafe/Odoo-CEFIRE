#!/bin/bash
# diagnostic.sh - Diagnòstic del sistema Docker

echo "🔍 DIAGNÒSTIC DOCKER ODOO"
echo "========================="

echo "📊 Estat dels contenidors:"
docker compose ps 2>/dev/null || echo "Docker Compose no disponible o no hi ha projecte actiu"

echo -e "\n💾 Ús de recursos:"
docker stats --no-stream 2>/dev/null || echo "No hi ha contenidors en execució"

echo -e "\n💿 Espai en disc:"
docker system df 2>/dev/null || echo "Docker no disponible"

echo -e "\n🌐 Connectivitat (si hi ha contenidors actius):"
if docker compose ps | grep -q "Up"; then
    docker compose exec web nc -zv db 5432 2>/dev/null && echo "✅ Connexió BD: OK" || echo "❌ Connexió BD: FALLA"
else
    echo "No hi ha contenidors actius per verificar"
fi

echo -e "\n📋 Logs recents:"
if docker compose ps | grep -q "Up"; then
    docker compose logs --tail=5 web 2>/dev/null | grep -E "(ERROR|CRITICAL)" || echo "No hi ha errors recents"
else
    echo "No hi ha contenidors actius"
fi

echo -e "\n🐳 Informació de Docker:"
echo "  Versió: $(docker --version 2>/dev/null || echo 'No disponible')"
echo "  Compose: $(docker compose version 2>/dev/null || echo 'No disponible')"

echo -e "\n✅ Diagnòstic completat!"