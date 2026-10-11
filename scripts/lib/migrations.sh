#!/bin/bash
# migrations.sh - migraciones versionadas para MEAL Gestor.
# Idea tomada de Omakub (MIT segun su README; ver THIRD-PARTY-NOTICES.md): scripts con numero
# creciente que se ejecutan una sola vez. Reimplementado, NO copiado, con estas diferencias:
#   - no hace git pull ni descarga nada: solo corre lo que ya esta en el disco local;
#   - el estado es una lista de IDs aplicados (no una comparacion de fechas de git);
#   - fail-closed: una migracion sin entrada en migrations/SHA256SUMS, o con hash distinto, NO se ejecuta,
#     y se verifica TODO lo pendiente antes de ejecutar la primera;
#   - cada migracion corre en un proceso aparte (bash archivo), no con source.
# LIMITES: el manifiesto vive en el mismo repo, asi que protege contra corrupcion y cambios sueltos,
# no contra un repo comprometido. Cuando exista la actualizacion de MEAL, debe verificar una etiqueta
# firmada (o un commit fijado) antes de confiar en el manifiesto. Sin bloqueo: no correr dos instancias a la vez.
# Funciones de biblioteca: no cambian opciones del shell del que las carga.

MEAL_MIG_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEAL_MIGRATIONS_DIR="${MEAL_MIGRATIONS_DIR:-$MEAL_MIG_LIB_DIR/../../migrations}"
# shellcheck source=utils.sh
source "$MEAL_MIG_LIB_DIR/utils.sh"

meal_migrations_state_dir() {
    if [ -n "${MEAL_STATE_DIR:-}" ]; then echo "$MEAL_STATE_DIR"
    elif [ "$EUID" -eq 0 ]; then echo "/var/lib/meal"
    else echo "${XDG_STATE_HOME:-$HOME/.local/state}/meal"
    fi
}

# Nombres validos: <numero>-<nombre>.sh con caracteres seguros. Ordenados por numero (no por texto).
meal_migrations_list() {
    local f b
    for f in "$MEAL_MIGRATIONS_DIR"/[0-9]*-*.sh; do
        [ -f "$f" ] || continue
        b=$(basename "$f")
        [[ "$b" =~ ^[0-9]+-[A-Za-z0-9._-]+\.sh$ ]] || continue
        echo "$b"
    done | LC_ALL=C sort -t- -k1,1n -k2,2
}

meal_migrations_pending() {
    local state b
    state="$(meal_migrations_state_dir)/applied-migrations"
    meal_migrations_list | while read -r b; do
        if [ -f "$state" ] && grep -qxF "$b" "$state"; then continue; fi
        echo "$b"
    done
}

# Uso: meal_migrations_verify nombre.sh   -> 0 ok | 1 sin entrada en el manifiesto | 2 hash distinto | 3 sin manifiesto
meal_migrations_verify() {
    local name="$1" manifest="$MEAL_MIGRATIONS_DIR/SHA256SUMS" esperado real
    [ -f "$manifest" ] || return 3
    esperado=$(awk -v f="$name" '$2 == f {print $1}' "$manifest")
    [ -n "$esperado" ] || return 1
    real=$(sha256sum "$MEAL_MIGRATIONS_DIR/$name" | awk '{print $1}')
    [ "$esperado" = "$real" ] || return 2
}

# Herramienta de mantenedor: regenera el manifiesto a partir de las migraciones actuales.
meal_migrations_manifest_update() {
    local lista
    lista=$(meal_migrations_list)
    if [ -z "$lista" ]; then : > "$MEAL_MIGRATIONS_DIR/SHA256SUMS"; return 0; fi
    ( cd "$MEAL_MIGRATIONS_DIR" && echo "$lista" | xargs sha256sum > SHA256SUMS )
}

# Uso: meal_migrations_run [--dry-run]   -> 0 ok | 1 verificacion fallida o migracion fallida
meal_migrations_run() {
    local dry=0 b rc state_dir pendientes=()
    [ "${1:-}" = "--dry-run" ] && dry=1
    while read -r b; do [ -n "$b" ] && pendientes+=("$b"); done < <(meal_migrations_pending)
    if [ "${#pendientes[@]}" -eq 0 ]; then meal_log_info "no hay migraciones pendientes"; return 0; fi

    # Paso 1: verificar TODAS antes de ejecutar alguna (fail-closed).
    for b in "${pendientes[@]}"; do
        meal_migrations_verify "$b"; rc=$?
        case "$rc" in
            0) ;;
            1) meal_log_error "$b: sin entrada en SHA256SUMS, no se ejecuta nada"; return 1 ;;
            2) meal_log_error "$b: el hash no coincide con SHA256SUMS, no se ejecuta nada"; return 1 ;;
            3) meal_log_error "falta migrations/SHA256SUMS, no se ejecuta nada"; return 1 ;;
        esac
    done

    # Paso 2: ejecutar en orden; al primer fallo se detiene y NO se marca como aplicada.
    state_dir="$(meal_migrations_state_dir)"
    for b in "${pendientes[@]}"; do
        if [ "$dry" -eq 1 ]; then echo "[DRY-RUN] ejecutaria migracion: $b"; continue; fi
        meal_log_info "aplicando $b"
        if bash "$MEAL_MIGRATIONS_DIR/$b"; then
            mkdir -p "$state_dir" && echo "$b" >> "$state_dir/applied-migrations"
        else
            meal_log_error "$b fallo; se detiene (no se marca como aplicada)"
            return 1
        fi
    done
}
