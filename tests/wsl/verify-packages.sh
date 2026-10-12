#!/bin/bash
# verify-packages.sh - comprueba que cada paquete que usa el repo existe en los repos de Arch.
# Dos formas de consultar (elige sola, o fuerza con MEAL_VERIFY_BACKEND=pacman|db):
#   pacman : en un Arch real con las bases sincronizadas (pacman -Syu como root)
#   db     : en CUALQUIER distro (Kali, Ubuntu...): baja core.db/extra.db/multilib.db del mirror de Arch
#            (necesita curl y python3) y los lee sin pacman. Variables: MEAL_ARCH_MIRROR, MEAL_ARCH_DB_DIR,
#            MEAL_ARCH_NO_DOWNLOAD=1 (usar los .db ya descargados).
# Uso:  bash tests/wsl/verify-packages.sh [-v] [--list]
#   -v      muestra tambien los paquetes que estan bien
#   --list  solo imprime los nombres de paquetes que se revisarian y sale
# Fuentes: scripts/packages/*.list, scripts/desktop/*.list (salvo gnome-extensions/favorites),
#          archiso/packages.x86_64 y las lineas "pacman -S <paquetes>" de los scripts.
# Los paquetes de AUR no estan en los repos oficiales: apareceran como FALTA (revisalos a mano).
# Salida: 0 todo bien | 1 hay FALTA o MULTILIB | 2 entorno no valido

set -u
cd "$(dirname "$0")/../.." || exit 1
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERBOSE=0; LIST_ONLY=0
for a in "$@"; do
    case "$a" in
        -v) VERBOSE=1 ;;
        --list) LIST_ONLY=1 ;;
        -h|--help) sed -n '2,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Opcion desconocida: $a" >&2; exit 2 ;;
    esac
done

collect() {
    local f n
    for f in scripts/packages/*.list scripts/desktop/*.list; do
        case "$(basename "$f")" in gnome-extensions.list|gnome-favorites.list) continue ;; esac
        grep -v '^[[:space:]]*#' "$f" | grep -v '^[[:space:]]*$' | cut -d'|' -f1 | while read -r n; do printf '%s\t%s\n' "$n" "$f"; done
    done
    grep -v '^[[:space:]]*#' archiso/packages.x86_64 | grep -v '^[[:space:]]*$' | while read -r n; do printf '%s\t%s\n' "$n" archiso/packages.x86_64; done
    # lineas "pacman -S ..." (no -Sy/-Syu: exige espacio justo despues de -S). Se ignoran opciones y variables.
    grep -rnH --include='*.sh' -E 'pacman -S[[:space:]]' scripts archiso 2>/dev/null | while IFS=: read -r f _ rest; do
        local tok
        for tok in ${rest#*pacman -S }; do
            [[ "$tok" =~ ^[a-z0-9][a-z0-9@._+-]*$ ]] && printf '%s\t%s\n' "$tok" "$f"
        done
    done
}

declare -A FILES=()
while IFS=$'\t' read -r n f; do
    [ -n "$n" ] || continue
    case " ${FILES[$n]:-} " in *" $f "*) ;; *) FILES[$n]="${FILES[$n]:-}$f " ;; esac
done < <(collect)

mapfile -t NAMES < <(printf '%s\n' "${!FILES[@]}" | LC_ALL=C sort)
if [ "$LIST_ONLY" -eq 1 ]; then printf '%s\n' "${NAMES[@]}"; exit 0; fi

check_pacman() {
    command -v pacman >/dev/null 2>&1 || { echo "ERROR: no hay pacman (usa MEAL_VERIFY_BACKEND=db o un Arch real)." >&2; exit 2; }
    pacman -Sl core >/dev/null 2>&1 || { echo "ERROR: bases de datos sin sincronizar. Corre 'pacman -Syu' (como root) y reintenta." >&2; exit 2; }
    local n repo
    for n in "$@"; do
        if repo=$(pacman -Si "$n" 2>/dev/null | awk -F' *: *' '/^Repository/ {print $2; exit}') && [ -n "$repo" ]; then
            if [ "$repo" = multilib ]; then printf 'MULTILIB\t%s\t%s\n' "$n" "$repo"; else printf 'OK\t%s\t%s\n' "$n" "$repo"; fi
        elif [ -n "$(pacman -Sg "$n" 2>/dev/null)" ]; then
            printf 'GRUPO\t%s\t-\n' "$n"
        else
            printf 'FALTA\t%s\t-\n' "$n"
        fi
    done
}

check_db() {
    command -v python3 >/dev/null 2>&1 || { echo "ERROR: falta python3." >&2; exit 2; }
    local dir="${MEAL_ARCH_DB_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/meal/arch-db}"
    local mirror="${MEAL_ARCH_MIRROR:-https://geo.mirror.pkgbuild.com}" repo
    mkdir -p "$dir"
    if [ -z "${MEAL_ARCH_NO_DOWNLOAD:-}" ]; then
        command -v curl >/dev/null 2>&1 || { echo "ERROR: falta curl." >&2; exit 2; }
        for repo in core extra multilib; do
            echo "Descargando $repo.db de $mirror ..." >&2
            curl -fsSL --retry 2 -o "$dir/$repo.db.part" "$mirror/$repo/os/x86_64/$repo.db" \
                || { echo "ERROR: no pude bajar $repo.db (sin internet o mirror bloqueado). Prueba MEAL_ARCH_MIRROR=<otro mirror>." >&2; exit 2; }
            mv "$dir/$repo.db.part" "$dir/$repo.db"
        done
    fi
    printf '%s\n' "$@" | python3 "$AQUI/arch_db_lookup.py" "$dir" core extra multilib
}

BACKEND="${MEAL_VERIFY_BACKEND:-auto}"
if [ "$BACKEND" = auto ]; then
    if command -v pacman >/dev/null 2>&1; then BACKEND=pacman; else BACKEND=db; fi
fi
case "$BACKEND" in
    pacman) RESULTADOS=$(check_pacman "${NAMES[@]}") || exit 2 ;;
    db)     RESULTADOS=$(check_db "${NAMES[@]}") || exit 2 ;;
    *)      echo "MEAL_VERIFY_BACKEND debe ser auto, pacman o db" >&2; exit 2 ;;
esac
echo "Metodo de consulta: $BACKEND"

ok=0; grupo=0; falta=0; multilib=0
while IFS=$'\t' read -r st n detalle; do
    [ -n "$st" ] || continue
    case "$st" in
        OK|PROVIDE) ok=$((ok + 1)); [ "$VERBOSE" -eq 1 ] && printf '%-8s %-34s [%s]\n' "$st" "$n" "$detalle" ;;
        GRUPO)      grupo=$((grupo + 1)); [ "$VERBOSE" -eq 1 ] && printf 'GRUPO    %-34s\n' "$n" ;;
        MULTILIB)   multilib=$((multilib + 1))
                    printf 'MULTILIB %-34s usado en: %s\n         -> esta en [multilib]: hay que activarlo en el pacman.conf que usen pacstrap y archiso\n' "$n" "${FILES[$n]}" ;;
        FALTA)      falta=$((falta + 1)); printf 'FALTA  %-34s usado en: %s\n' "$n" "${FILES[$n]}" ;;
    esac
done <<< "$RESULTADOS"

echo ""
echo "Paquetes distintos revisados: $((ok + grupo + falta + multilib)) | existen: $ok | grupos: $grupo | en multilib: $multilib | FALTAN: $falta"
if [ $((falta + multilib)) -gt 0 ]; then
    echo "Un FALTA puede ser: paquete de AUR, o un nombre mal escrito. MULTILIB: existe pero el repo no esta activo en nuestros pacman.conf."
    exit 1
fi
