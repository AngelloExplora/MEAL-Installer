#!/bin/bash
# verify-packages.sh - comprueba contra el pacman REAL que cada paquete que usa el repo existe.
# Uso, en Arch (por ejemplo Arch en WSL) con las bases sincronizadas (pacman -Syu como root):
#     bash tests/wsl/verify-packages.sh        # solo muestra problemas y el resumen
#     bash tests/wsl/verify-packages.sh -v     # muestra tambien cada paquete OK
# Fuentes: scripts/packages/*.list, scripts/desktop/*.list (salvo gnome-extensions/favorites),
#          archiso/packages.x86_64 y las lineas "pacman -S <paquetes>" de los scripts.
# Los paquetes de AUR NO se pueden comprobar con pacman: apareceran como FALTA (revisalos a mano).
# Codigos de salida: 0 todo existe | 1 faltan paquetes | 2 entorno no valido (sin pacman / sin sincronizar)

set -u
cd "$(dirname "$0")/../.." || exit 1
VERBOSE=0; [ "${1:-}" = "-v" ] && VERBOSE=1

command -v pacman >/dev/null 2>&1 || { echo "ERROR: no hay pacman. Esto necesita un Arch real (por ejemplo: wsl --install archlinux)." >&2; exit 2; }
pacman -Sl core >/dev/null 2>&1 || { echo "ERROR: bases de datos sin sincronizar. Corre 'pacman -Syu' (como root) y vuelve a intentar." >&2; exit 2; }

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

ok=0; grupo=0; falta=0; faltan=()
for n in $(printf '%s\n' "${!FILES[@]}" | LC_ALL=C sort); do
    if repo=$(pacman -Si "$n" 2>/dev/null | awk -F' *: *' '/^Repository/ {print $2; exit}') && [ -n "$repo" ]; then
        ok=$((ok + 1)); [ "$VERBOSE" -eq 1 ] && printf 'OK     %-34s [%s]\n' "$n" "$repo"
    elif [ -n "$(pacman -Sg "$n" 2>/dev/null)" ]; then
        grupo=$((grupo + 1)); [ "$VERBOSE" -eq 1 ] && printf 'GRUPO  %-34s\n' "$n"
    else
        falta=$((falta + 1)); faltan+=("$n")
        printf 'FALTA  %-34s usado en: %s\n' "$n" "${FILES[$n]}"
    fi
done

echo ""
echo "Paquetes distintos revisados: $((ok + grupo + falta)) | existen: $ok | grupos: $grupo | FALTAN: $falta"
if [ "$falta" -gt 0 ]; then
    echo "Un FALTA puede ser: paquete de AUR, repo [multilib] desactivado (steam, wine, lib32-*), o un nombre mal escrito."
    exit 1
fi
