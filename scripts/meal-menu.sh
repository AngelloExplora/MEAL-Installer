#!/bin/bash
# ==========================================================
# MEAL - Menú principal
# Estilo inspirado en Omarchy, sin ser Omarchy.
# ==========================================================

set -e

if ! command -v gum &>/dev/null; then
    echo "❌ Falta 'gum'. Instálalo con: sudo pacman -S gum"
    exit 1
fi

# Lista de herramientas: "paquete(s)|Descripción corta"
TOOLS=(
    "git|Control de versiones"
    "docker docker-compose|Contenedores"
    "lazygit|Cliente TUI para git"
    "neovim|Editor de texto"
    "tmux|Multiplexor de terminal"
    "ripgrep|Búsqueda de texto rápida (rg)"
    "fd|Buscador de archivos moderno"
    "bat|cat con resaltado de sintaxis"
    "eza|ls moderno"
    "nodejs npm|JavaScript / Node"
    "python python-pip|Python"
    "btop|Monitor de sistema"
)

ATAJOS_MD="$(dirname "$0")/../docs/atajos-de-teclado.md"
[ -f "$ATAJOS_MD" ] || ATAJOS_MD="/usr/local/share/meal/atajos-de-teclado.md"

instalar_herramientas() {
    LABELS=()
    for t in "${TOOLS[@]}"; do
        LABELS+=("${t#*|}")
    done

    SELECCION=$(printf '%s\n' "${LABELS[@]}" | gum choose --no-limit --header="Espacio para elegir, Enter para confirmar")
    [ -z "$SELECCION" ] && return

    PAQUETES=""
    while IFS= read -r sel; do
        for t in "${TOOLS[@]}"; do
            if [ "${t#*|}" == "$sel" ]; then
                PAQUETES="$PAQUETES ${t%%|*}"
            fi
        done
    done <<< "$SELECCION"

    gum confirm "¿Instalar:$PAQUETES ?" && sudo pacman -S --needed $PAQUETES
    gum style --foreground 212 "✅ Listo."
}

ver_atajos() {
    if [ -f "$ATAJOS_MD" ]; then
        gum pager < "$ATAJOS_MD"
    else
        echo "No encontré el archivo de atajos de teclado."
    fi
}

while true; do
    OPCION=$(gum choose \
        "🛠️  Instalar herramientas de programador" \
        "⌨️  Ver atajos de teclado" \
        "🚪 Salir" \
        --header="=== MEAL — Menú principal ===")

    case "$OPCION" in
        "🛠️  Instalar herramientas de programador") instalar_herramientas ;;
        "⌨️  Ver atajos de teclado") ver_atajos ;;
        "🚪 Salir"|"") exit 0 ;;
    esac
done
