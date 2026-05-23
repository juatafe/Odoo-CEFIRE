#!/bin/bash
# monitor.sh - Monitoratge en temps real

# Colors per a output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuració
ALERT_CPU_THRESHOLD=80
ALERT_MEM_THRESHOLD=85
CHECK_INTERVAL=30

echo -e "${BLUE}🔍 Iniciant monitoratge d'Odoo Docker${NC}"
echo "Prem Ctrl+C per aturar"
echo "===================="

while true; do
    clear
    echo -e "${BLUE}📊 MONITOR ODOO DOCKER - $(date)${NC}"
    echo "=============================================="
    
    # Verificar si hi ha contenidors actius
    if ! docker compose ps | grep -q "Up"; then
        echo -e "${RED}❌ No hi ha contenidors d'Odoo actius${NC}"
        sleep $CHECK_INTERVAL
        continue
    fi
    
    # Obtenir estadístiques
    echo "📈 Recursos dels contenidors:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    
    echo ""
    
    # Verificar alertes
    WEB_STATS=$(docker stats --no-stream --format "{{.CPUPerc}} {{.MemPerc}}" odoo_server-web-1 2>/dev/null)
    if [ ! -z "$WEB_STATS" ]; then
        CPU=$(echo $WEB_STATS | cut -d' ' -f1 | sed 's/%//')
        MEM=$(echo $WEB_STATS | cut -d' ' -f2 | sed 's/%//')
        
        # Verificar CPU
        if (( $(echo "$CPU > $ALERT_CPU_THRESHOLD" | bc -l 2>/dev/null || echo 0) )); then
            echo -e "${RED}⚠️  ALERTA: CPU alt: ${CPU}%${NC}"
        fi
        
        # Verificar memòria
        if (( $(echo "$MEM > $ALERT_MEM_THRESHOLD" | bc -l 2>/dev/null || echo 0) )); then
            echo -e "${RED}⚠️  ALERTA: Memòria alta: ${MEM}%${NC}"
        fi
    fi
    
    # Estat dels serveis
    echo "🔧 Estat dels serveis:"
    docker compose ps
    
    echo ""
    echo "🌐 Connectivitat:"
    curl -s -o /dev/null -w "Odoo Web: %{http_code}\n" http://localhost:8069 2>/dev/null || echo "Odoo Web: No accessible"
    
    echo ""
    echo -e "${YELLOW}Pròxima actualització en ${CHECK_INTERVAL}s...${NC}"
    
    sleep $CHECK_INTERVAL
done