#!/bin/bash
# desktop.sh - lee scripts/desktop/*.list y *.conf
# Generico: sirve igual para KDE, Hyprland, GNOME o XFCE (Fase 5/9/10/11), sin repetir logica.

MEAL_DESKTOP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../desktop" && pwd)"

# Uso: meal_desktop_list
meal_desktop_list() {
    for f in "$MEAL_DESKTOP_DIR"/*.conf; do
        basename "$f" .conf
    done
}

# Uso: meal_desktop_load kde
meal_desktop_load() {
    local de="$1"
    local archivo="$MEAL_DESKTOP_DIR/$de.conf"
    [ -f "$archivo" ] || { echo "No existe el escritorio: $de" >&2; return 1; }
    source "$archivo"
}

# Uso: meal_desktop_packages_by_level kde OBLIGATORIO
meal_desktop_packages_by_level() {
    local de="$1" nivel="$2"
    grep "|$nivel$" "$MEAL_DESKTOP_DIR/$de.list" 2>/dev/null | cut -d'|' -f1
}

# Uso: meal_desktop_packages kde
# OBLIGATORIO + RECOMENDADO (lo que se instala por defecto). Lo OPCIONAL queda para
# el checklist post-instalacion (Fase 12), no se fuerza durante Calamares.
meal_desktop_packages() {
    local de="$1"
    { meal_desktop_packages_by_level "$de" OBLIGATORIO
      meal_desktop_packages_by_level "$de" RECOMENDADO
    } | sort -u
}
