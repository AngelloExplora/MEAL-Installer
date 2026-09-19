#!/bin/bash
# pacstrap-meal.sh - instala el sistema base + perfil + escritorio elegidos
# Invocado por Calamares (modulo shellprocess "pacstrap-meal") sobre /mnt/meal-root
# (variable ROOT_MOUNT_POINT que Calamares expone a los scripts shellprocess).
#
# Variables que Calamares debe pasar (via GlobalStorage, resueltas por el
# shellprocess job): MEAL_PERFIL (ej. "desarrollo") y MEAL_ESCRITORIO (ej. "kde").
# Si no vienen definidas, se usan valores por defecto seguros.

set -Eeuo pipefail

RAIZ="${ROOT_MOUNT_POINT:-/mnt/meal-root}"
PERFIL="${MEAL_PERFIL:-basico}"
ESCRITORIO="${MEAL_ESCRITORIO:-kde}"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_DIR/scripts/lib/profiles.sh"
source "$REPO_DIR/scripts/lib/desktop.sh"

PAQUETES_PERFIL="$(meal_profile_packages "$PERFIL")"
PAQUETES_ESCRITORIO="$(meal_desktop_packages "$ESCRITORIO")"
TODOS=$(printf '%s\n%s\n' "$PAQUETES_PERFIL" "$PAQUETES_ESCRITORIO" | sort -u | tr '\n' ' ')

echo "MEAL: instalando perfil '$PERFIL' + escritorio '$ESCRITORIO' en $RAIZ"
echo "MEAL: paquetes ($(echo "$TODOS" | wc -w)): $TODOS"

pacstrap "$RAIZ" $TODOS

# Servicios a habilitar (del perfil y del escritorio)
meal_profile_load "$PERFIL"
meal_desktop_load "$ESCRITORIO"
for servicio in $MEAL_PROFILE_SERVICIOS $MEAL_DESKTOP_SERVICIOS; do
    [ -n "$servicio" ] && arch-chroot "$RAIZ" systemctl enable "$servicio"
done

echo "MEAL: pacstrap-meal.sh completado"
