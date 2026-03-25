#!/bin/bash
# test-docker-installation.sh - Verificació completa de Docker

echo "🐳 Verificant instal·lació de Docker..."

# Test 1: Docker version
echo -n "📋 Docker version: "
if docker --version >/dev/null 2>&1; then
    echo "✅ $(docker --version)"
else
    echo "❌ Docker no instal·lat correctament"
    exit 1
fi

# Test 2: Docker Compose
echo -n "🔧 Docker Compose: "
if docker compose version >/dev/null 2>&1; then
    echo "✅ $(docker compose version)"
else
    echo "❌ Docker Compose no disponible"
    exit 1
fi

# Test 3: Permisos d'usuari
echo -n "👤 Permisos d'usuari: "
if docker ps >/dev/null 2>&1; then
    echo "✅ Usuari pot executar Docker"
else
    echo "❌ Problemes de permisos"
    exit 1
fi

# Test 4: Docker daemon
echo -n "🔄 Docker daemon: "
if docker info >/dev/null 2>&1; then
    echo "✅ Docker daemon actiu"
else
    echo "❌ Docker daemon no disponible"
    exit 1
fi

# Test 5: Descàrrega d'imatge
echo -n "📥 Test de descàrrega: "
if docker pull hello-world >/dev/null 2>&1; then
    echo "✅ Descàrrega d'imatges funcional"
    docker rmi hello-world >/dev/null 2>&1
else
    echo "❌ Problemes descarregant imatges"
    exit 1
fi

echo ""
echo "🎉 Docker instal·lat i configurat correctament!"
echo "💾 Espai disponible per a imatges:"
docker system df