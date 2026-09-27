#!/bin/bash
# test-post-install.sh - verifica el calculo de opcionales por perfil (Fase 12)
# NO abre el menu real de gum (necesita terminal grafica = Fase 14).
set -e
cd "$(dirname "$0")/.."
source scripts/lib/profiles.sh

solo_opcionales_de_categoria() {
    grep '|OPCIONAL$' "scripts/packages/$1.list" 2>/dev/null | cut -d'|' -f1
}

for perfil in $(meal_profile_list); do
    meal_profile_load "$perfil"
    echo "=== $MEAL_PROFILE_NOMBRE ==="
    if [ "$MEAL_PROFILE_CATEGORIAS_OPCIONALES" == "INTERACTIVO" ] || [ -z "$MEAL_PROFILE_CATEGORIAS_OPCIONALES" ]; then
        echo "  (sin opcionales fijos)"
        continue
    fi
    for cat in $MEAL_PROFILE_CATEGORIAS_OPCIONALES; do
        solo_opcionales_de_categoria "$cat"
    done | sort -u | sed 's/^/  - /'
done
