#!/bin/bash
# profiles.sh - lee scripts/profiles/*.conf y arma la lista de paquetes de cada uno

MEAL_PROFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../profiles" && pwd)"
MEAL_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$MEAL_LIB_DIR/packages.sh"

# Uso: meal_profile_list
meal_profile_list() {
    for f in "$MEAL_PROFILES_DIR"/*.conf; do
        basename "$f" .conf
    done
}

# Uso: meal_profile_load nombre-archivo (sin .conf)
# Carga las variables MEAL_PROFILE_* del perfil pedido.
meal_profile_load() {
    local perfil="$1"
    local archivo="$MEAL_PROFILES_DIR/$perfil.conf"
    [ -f "$archivo" ] || { echo "No existe el perfil: $perfil" >&2; return 1; }
    source "$archivo"
}

# Uso: meal_profile_packages nombre-archivo
# OBLIGATORIO + RECOMENDADO + categorias opcionales del perfil, sin duplicados.
meal_profile_packages() {
    local perfil="$1"
    meal_profile_load "$perfil" || return 1

    { meal_packages_by_level OBLIGATORIO
      meal_packages_by_level RECOMENDADO
      if [ "$MEAL_PROFILE_CATEGORIAS_OPCIONALES" != "INTERACTIVO" ]; then
          for cat in $MEAL_PROFILE_CATEGORIAS_OPCIONALES; do
              meal_packages_by_category "$cat"
          done
      fi
    } | sort -u
}

# Uso: meal_profile_size_mb nombre-archivo
# Requiere pacman con bases de datos sincronizadas - correr en Arch/Manjaro real, no en este sandbox.
meal_profile_size_mb() {
    local perfil="$1"
    local total_kb=0 linea numero unidad kb
    for pkg in $(meal_profile_packages "$perfil"); do
        linea=$(pacman -Si "$pkg" 2>/dev/null | awk -F': ' '/^Installed Size/ {print $2}')
        [ -z "$linea" ] && continue
        numero=$(echo "$linea" | awk '{print $1}')
        unidad=$(echo "$linea" | awk '{print $2}')
        case "$unidad" in
            MiB) kb=$(echo "$numero * 1024" | bc) ;;
            GiB) kb=$(echo "$numero * 1024 * 1024" | bc) ;;
            KiB) kb=$numero ;;
            *) kb=0 ;;
        esac
        total_kb=$(echo "$total_kb + $kb" | bc)
    done
    echo "$total_kb / 1024" | bc
}
