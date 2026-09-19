#!/bin/bash
# test-profiles.sh - prueba del sistema de perfiles (Fase 4)
set -e
cd "$(dirname "$0")/.."
source scripts/lib/profiles.sh

echo "Perfiles disponibles:"
meal_profile_list
echo ""

for perfil in $(meal_profile_list); do
    meal_profile_load "$perfil"
    echo "=== $MEAL_PROFILE_NOMBRE ==="
    echo "  $MEAL_PROFILE_DESCRIPCION"
    echo "  Paquetes: $(meal_profile_packages "$perfil" | wc -l)"
    echo "  Servicios: ${MEAL_PROFILE_SERVICIOS:-ninguno}"
    echo ""
done
