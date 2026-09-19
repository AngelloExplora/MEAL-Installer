#!/bin/bash
# packages.sh - lee y consulta las listas de scripts/packages/*.list

MEAL_PACKAGES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../packages" && pwd)"

# Uso: meal_packages_by_level OBLIGATORIO
# Todos los paquetes de ese nivel, en todas las categorias, sin duplicados.
meal_packages_by_level() {
    local nivel="$1"
    grep -h "|$nivel$" "$MEAL_PACKAGES_DIR"/*.list 2>/dev/null | cut -d'|' -f1 | sort -u
}

# Uso: meal_packages_by_category base
meal_packages_by_category() {
    local categoria="$1"
    local archivo="$MEAL_PACKAGES_DIR/$categoria.list"
    [ -f "$archivo" ] || { echo "No existe la categoria: $categoria" >&2; return 1; }
    grep -v '^#' "$archivo" | grep -v '^$' | cut -d'|' -f1
}

# Uso: meal_packages_count_by_level OBLIGATORIO
meal_packages_count_by_level() {
    meal_packages_by_level "$1" | grep -c .
}
