#!/bin/bash
# ==========================================================
# MEAL - Bienvenida de primer arranque
# Se muestra una sola vez por usuario.
# ==========================================================

MARCADOR="$HOME/.meal-bienvenida-mostrada"

if command -v gum &>/dev/null; then
    gum style --border double --padding "1 4" --border-foreground 212 --align center \
        "🍽️  Te damos la bienvenida a" "\"MEAL — Rama Manjaro\"" "" "Presiona Super + M para ver el menú"
else
    echo "🍽️  Te damos la bienvenida a \"MEAL — Rama Manjaro\""
    echo "Presiona Super + M para ver el menú"
fi

read -n 1 -s -r -p "Presiona cualquier tecla para continuar..."
echo ""
touch "$MARCADOR"
