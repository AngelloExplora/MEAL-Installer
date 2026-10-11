#!/bin/bash
# gnome.sh - motor para aplicar la capa GNOME de MEAL.
# Datos derivados de Omakub (MIT segun su README) - ver THIRD-PARTY-NOTICES.md.
# Funciones de biblioteca: no cambian opciones del shell (set -e/-u) del que las carga.

MEAL_GNOME_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEAL_GNOME_DATA_DIR="${MEAL_GNOME_DATA_DIR:-$MEAL_GNOME_LIB_DIR/../desktop}"
MEAL_GNOME_EXT_DIR="${MEAL_GNOME_EXT_DIR:-$HOME/.local/share/gnome-shell/extensions}"
MEAL_GNOME_APPLIED=0
MEAL_GNOME_FAILED=0

# shellcheck source=utils.sh
source "$MEAL_GNOME_LIB_DIR/utils.sh"

# Uso: meal_gnome_validate_tsv archivo.tsv
# Revisa formato (4 columnas con tab), uuid con '@' y duplicados. Devuelve 1 si hay errores.
meal_gnome_validate_tsv() {
    local file="$1" n=0 errors=0 ext schema key value id
    local -A seen=()
    [ -f "$file" ] || { meal_log_error "no existe: $file"; return 1; }
    while IFS=$'\t' read -r ext schema key value || [ -n "$ext" ]; do
        n=$((n + 1))
        case "$ext" in ''|'#'*) continue ;; esac
        if [ -z "$schema" ] || [ -z "$key" ] || [ -z "$value" ]; then
            meal_log_error "$file:$n: linea mal formada (se esperan 4 columnas separadas por tab)"
            errors=$((errors + 1)); continue
        fi
        if [ "$ext" != "-" ] && [[ "$ext" != *@* ]]; then
            meal_log_error "$file:$n: '$ext' no parece un UUID de extension (falta '@')"
            errors=$((errors + 1))
        fi
        id="$ext|$schema|$key"
        if [ -n "${seen[$id]:-}" ]; then
            meal_log_error "$file:$n: duplicado: $schema $key ($ext)"
            errors=$((errors + 1))
        fi
        seen[$id]=1
    done < "$file"
    [ "$errors" -eq 0 ]
}

# Uso: meal_gnome_apply_tsv archivo.tsv [apply|dry]
# Aplica linea por linea. Un fallo se cuenta y se informa, pero no detiene el resto
# (las claves cambian entre versiones de GNOME). Resultado final en MEAL_GNOME_APPLIED/FAILED.
meal_gnome_apply_tsv() {
    local file="$1" mode="${2:-apply}" ext schema key value dir out
    while IFS=$'\t' read -r ext schema key value || [ -n "$ext" ]; do
        case "$ext" in ''|'#'*) continue ;; esac
        if [ "$mode" = "dry" ]; then
            if [ "$ext" = "-" ]; then
                echo "[DRY-RUN] gsettings set $schema $key $value"
            else
                echo "[DRY-RUN] (esquema de $ext) gsettings set $schema $key $value"
            fi
            continue
        fi
        if [ "$ext" = "-" ]; then
            if out=$(gsettings set "$schema" "$key" "$value" 2>&1); then
                MEAL_GNOME_APPLIED=$((MEAL_GNOME_APPLIED + 1))
            else
                meal_log_warn "no se pudo aplicar $schema $key: $out"
                MEAL_GNOME_FAILED=$((MEAL_GNOME_FAILED + 1))
            fi
            continue
        fi
        dir="$MEAL_GNOME_EXT_DIR/$ext/schemas"
        if [ ! -d "$dir" ]; then
            meal_log_warn "extension no instalada ($ext): falta $dir"
            MEAL_GNOME_FAILED=$((MEAL_GNOME_FAILED + 1)); continue
        fi
        if [ ! -f "$dir/gschemas.compiled" ]; then
            if ! out=$(glib-compile-schemas "$dir" 2>&1); then
                meal_log_warn "no se pudieron compilar los esquemas de $ext: $out"
                MEAL_GNOME_FAILED=$((MEAL_GNOME_FAILED + 1)); continue
            fi
        fi
        if out=$(GSETTINGS_SCHEMA_DIR="$dir" gsettings set "$schema" "$key" "$value" 2>&1); then
            MEAL_GNOME_APPLIED=$((MEAL_GNOME_APPLIED + 1))
        else
            meal_log_warn "no se pudo aplicar $schema $key ($ext): $out"
            MEAL_GNOME_FAILED=$((MEAL_GNOME_FAILED + 1))
        fi
    done < "$file"
}

# Uso: meal_gnome_favorites_list archivo.list
# Imprime la lista GVariant con solo las apps cuyo .desktop existe. '@as []' si ninguna.
# (Corrige un caso borde de Omakub: con cero apps su printf generaba [''].)
meal_gnome_favorites_list() {
    local file="$1" id d list="" dirs
    read -r -a dirs <<< "${MEAL_DESKTOP_DIRS:-/var/lib/flatpak/exports/share/applications /usr/share/applications /usr/local/share/applications $HOME/.local/share/applications}"
    while read -r id; do
        case "$id" in ''|'#'*) continue ;; esac
        for d in "${dirs[@]}"; do
            if [ -f "$d/$id" ]; then list="${list}'${id}',"; break; fi
        done
    done < "$file"
    if [ -z "$list" ]; then echo "@as []"; else echo "[${list%,}]"; fi
}

# Uso: meal_gnome_apply_favorites archivo.list [apply|dry]
# Si no hay ninguna app instalada NO toca los favoritos (para no vaciar los de fabrica).
meal_gnome_apply_favorites() {
    local file="$1" mode="${2:-apply}" list out
    list=$(meal_gnome_favorites_list "$file")
    if [ "$list" = "@as []" ] && [ "$mode" != "dry" ]; then
        meal_log_info "ninguna app favorita instalada, se dejan los favoritos como estan"
        return 0
    fi
    if [ "$mode" = "dry" ]; then
        echo "[DRY-RUN] gsettings set org.gnome.shell favorite-apps $list"
        return 0
    fi
    if out=$(gsettings set org.gnome.shell favorite-apps "$list" 2>&1); then
        MEAL_GNOME_APPLIED=$((MEAL_GNOME_APPLIED + 1))
    else
        meal_log_warn "no se pudo aplicar favorite-apps: $out"
        MEAL_GNOME_FAILED=$((MEAL_GNOME_FAILED + 1))
    fi
}
