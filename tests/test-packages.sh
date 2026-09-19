#!/bin/bash
# test-packages.sh - prueba ligera del sistema de paquetes (Fase 3)
set -e
cd "$(dirname "$0")/.."
source scripts/lib/packages.sh

echo "OBLIGATORIO ($(meal_packages_count_by_level OBLIGATORIO) paquetes):"
meal_packages_by_level OBLIGATORIO

echo ""
echo "RECOMENDADO ($(meal_packages_count_by_level RECOMENDADO) paquetes):"
meal_packages_by_level RECOMENDADO

echo ""
echo "Categoria 'graficos':"
meal_packages_by_category graficos
