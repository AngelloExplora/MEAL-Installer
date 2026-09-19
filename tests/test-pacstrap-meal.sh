#!/bin/bash
# test-pacstrap-meal.sh - dry-run de la logica de pacstrap-meal.sh (Fase 6)
# NO ejecuta pacstrap de verdad (requiere Arch real + particion montada = Fase 14).
# Solo verifica que la resolucion de paquetes/servicios es correcta.
set -e
cd "$(dirname "$0")/.."
source scripts/lib/profiles.sh
source scripts/lib/desktop.sh

PERFIL="${1:-desarrollo}"
ESCRITORIO="${2:-kde}"

PAQUETES_PERFIL="$(meal_profile_packages "$PERFIL")"
PAQUETES_ESCRITORIO="$(meal_desktop_packages "$ESCRITORIO")"
TODOS=$(printf '%s\n%s\n' "$PAQUETES_PERFIL" "$PAQUETES_ESCRITORIO" | sort -u)

echo "[DRY-RUN] perfil=$PERFIL escritorio=$ESCRITORIO"
echo "[DRY-RUN] pacstrap instalaria $(echo "$TODOS" | wc -w) paquetes:"
echo "$TODOS"

meal_profile_load "$PERFIL"
meal_desktop_load "$ESCRITORIO"
echo ""
echo "[DRY-RUN] servicios a habilitar: $MEAL_PROFILE_SERVICIOS $MEAL_DESKTOP_SERVICIOS"
