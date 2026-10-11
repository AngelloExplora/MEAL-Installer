#!/bin/bash
# gnome-layer.sh - capa GNOME de MEAL (extensiones, atajos, ajustes, favoritos).
# Portado de Omakub (MIT segun su README) a Arch: apt -> pacman, sin modificar /usr/share,
# sin borrar .desktop del sistema. Ver THIRD-PARTY-NOTICES.md y docs/DECISION-ARQUITECTURA.md.
#
# Uso: gnome-layer.sh [--dry-run] [--skip-extensions]
#   --dry-run          muestra lo que haria, sin instalar ni cambiar nada
#   --skip-extensions  solo ajustes, atajos y favoritos (no instala extensiones)
# Correr como usuario normal DENTRO de una sesion GNOME (gsettings es por usuario).

set -Eeuo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_DIR/scripts/lib/gnome.sh"

DRY=0
SKIP_EXT=0
usage() {
    cat << 'USO'
Uso: gnome-layer.sh [--dry-run] [--skip-extensions]
  --dry-run          muestra lo que haria, sin instalar ni cambiar nada
  --skip-extensions  solo ajustes, atajos y favoritos (no instala extensiones)
Correr como usuario normal DENTRO de una sesion GNOME (gsettings es por usuario).
USO
}
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY=1 ;;
        --skip-extensions) SKIP_EXT=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Opcion desconocida: $arg" >&2; usage >&2; exit 2 ;;
    esac
done

MODE=apply; [ "$DRY" -eq 1 ] && MODE=dry
run() { if [ "$DRY" -eq 1 ]; then echo "[DRY-RUN] $*"; else "$@"; fi; }
STEP_FAILS=0
step_fail() { meal_log_warn "$1"; STEP_FAILS=$((STEP_FAILS + 1)); }

D="$MEAL_GNOME_DATA_DIR"

# 1) Datos validos (siempre, tambien en --dry-run)
for f in "$D/gnome-core.tsv" "$D/gnome-extensions-settings.tsv"; do
    meal_gnome_validate_tsv "$f" || { meal_log_error "datos invalidos: $f"; exit 1; }
done

# 2) Condiciones del entorno (solo si se va a aplicar de verdad)
if [ "$DRY" -eq 0 ]; then
    [ "$EUID" -ne 0 ] || { meal_log_error "no corras esto como root: gsettings es por usuario"; exit 1; }
    case "${XDG_CURRENT_DESKTOP:-}" in *GNOME*) ;; *) meal_log_error "hace falta una sesion GNOME (XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-vacio})"; exit 1 ;; esac
    for c in gsettings pacman sudo; do
        command -v "$c" >/dev/null || { meal_log_error "falta el comando: $c"; exit 1; }
    done
fi

# 3) Paquetes (todos verificados en el repo extra de Arch)
meal_log_info "fuente monoespaciada (CaskaydiaMono Nerd Font)"
run sudo pacman -S --needed --noconfirm ttf-cascadia-mono-nerd || step_fail "no se pudo instalar ttf-cascadia-mono-nerd"

# 4) Extensiones
if [ "$SKIP_EXT" -eq 0 ]; then
    meal_log_info "gnome-extensions-cli (gext) via pipx"
    run sudo pacman -S --needed --noconfirm python-pipx python-gobject || step_fail "no se pudieron instalar python-pipx/python-gobject"
    run pipx install gnome-extensions-cli --system-site-packages || step_fail "pipx no pudo instalar gnome-extensions-cli"
    GEXT=gext
    if [ "$DRY" -eq 0 ] && ! command -v gext >/dev/null; then GEXT="$HOME/.local/bin/gext"; fi
    if [ "$DRY" -eq 0 ]; then
        echo "Para instalar extensiones GNOME Shell te pedira confirmaciones en pantalla."
        if [ -t 0 ]; then read -r -p "Enter para continuar... " _; fi
    fi
    while IFS='|' read -r uuid _; do
        case "$uuid" in ''|'#'*) continue ;; esac
        run "$GEXT" install "$uuid" || step_fail "no se pudo instalar la extension $uuid"
    done < "$D/gnome-extensions.list"
fi

# 5) Ajustes, atajos, tema, extensiones y favoritos
meal_log_info "ajustes, atajos y tema"
meal_gnome_apply_tsv "$D/gnome-core.tsv" "$MODE"
if [ "$SKIP_EXT" -eq 0 ]; then
    meal_log_info "ajustes de extensiones"
    meal_gnome_apply_tsv "$D/gnome-extensions-settings.tsv" "$MODE"
fi
meal_log_info "favoritos del dash"
meal_gnome_apply_favorites "$D/gnome-favorites.list" "$MODE"

# 6) Resumen honesto
if [ "$DRY" -eq 1 ]; then
    meal_log_info "simulacion terminada: no se cambio nada"
    exit 0
fi
echo ""
echo "Ajustes aplicados: $MEAL_GNOME_APPLIED | ajustes fallidos: $MEAL_GNOME_FAILED | pasos fallidos: $STEP_FAILS"
[ "$SKIP_EXT" -eq 0 ] && echo "Las extensiones nuevas se cargan al cerrar sesion y volver a entrar."
[ "$MEAL_GNOME_FAILED" -eq 0 ] && [ "$STEP_FAILS" -eq 0 ]
