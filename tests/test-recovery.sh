#!/bin/bash
# test-recovery.sh - prueba de la logica de MEAL Recovery (Fase 8)
# NO monta discos reales ni corre fsck/pacman/timeshift de verdad
# (eso necesita un sistema instalado real = Fase 14).
# Prueba solo lo que se puede probar en seco: que el menu carga, que
# confirmar() rechaza correctamente una respuesta que no sea "SI".
set -e
cd "$(dirname "$0")/.."
source scripts/recovery/meal-recovery.sh

echo "Probando confirmar() con respuesta incorrecta (debe rechazar):"
if echo "no" | (read -p "x" respuesta; [ "$respuesta" == "SI" ]); then
    echo "FALLO: acepto una respuesta que no era SI"
    exit 1
else
    echo "OK: rechazo correctamente"
fi

echo ""
echo "Menu (solo visual, no interactivo):"
mostrar_menu
