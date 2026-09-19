#!/bin/bash
# test-ui-engine.sh - prueba manual del MEAL UI Engine (Fase 2)
set -e
cd "$(dirname "$0")/.."
source scripts/lib/tui.sh

meal_header "MEAL UI Engine" "Prueba manual"

OPCION=$(meal_menu "Elige una opcion" "Probar checkbox" "Probar dialogo" "Probar progreso" "Probar animacion" "Salir")

case "$OPCION" in
    "Probar checkbox")
        meal_checkbox "Elige varias (espacio, enter)" "Uno" "Dos" "Tres"
        ;;
    "Probar dialogo")
        NOMBRE=$(meal_input "Escribe algo")
        meal_confirm "Confirmas: $NOMBRE ?" && echo "Confirmado" || echo "Cancelado"
        ;;
    "Probar progreso")
        for i in 0 25 50 75 100; do
            meal_progress_bar "$i" "Instalando"
            sleep 0.3
        done
        ;;
    "Probar animacion")
        meal_typewriter "Bienvenido a MEAL Installer 1.0"
        ;;
    *) echo "Saliendo" ;;
esac
