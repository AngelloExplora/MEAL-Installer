#!/bin/bash
# test-desktop.sh - prueba del sistema de escritorios (Fase 5)
set -e
cd "$(dirname "$0")/.."
source scripts/lib/desktop.sh

echo "Escritorios disponibles:"
meal_desktop_list
echo ""

for de in $(meal_desktop_list); do
    meal_desktop_load "$de"
    echo "=== $MEAL_DESKTOP_NOMBRE ==="
    echo "  Paquetes obligatorio+recomendado: $(meal_desktop_packages "$de" | wc -l)"
    echo "  Servicios: $MEAL_DESKTOP_SERVICIOS"
    meal_desktop_packages "$de"
    echo ""
done
