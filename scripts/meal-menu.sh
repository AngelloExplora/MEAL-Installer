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

ver_manual_github() {
    URL="https://github.com/AngelloExplora/MEAL-Installer/blob/main/docs/MANUAL.md"
    gum style --foreground 212 "Abriendo el manual en GitHub..."
    xdg-open "$URL" 2>/dev/null || echo "Ábrelo manualmente: $URL"
}

buscar_actualizaciones() {
    gum spin --title "Buscando actualizaciones..." -- sleep 1
    PENDIENTES=""

    PAC_UPD=$(pacman -Qu 2>/dev/null | grep -E '^(hyprland|sway|niri) ' || true)
    [ -n "$PAC_UPD" ] && PENDIENTES="$PENDIENTES\n$PAC_UPD"

    if command -v yay &>/dev/null; then
        YAY_UPD=$(yay -Qu 2>/dev/null | grep -i mango || true)
        [ -n "$YAY_UPD" ] && PENDIENTES="$PENDIENTES\n$YAY_UPD"
    fi

    if [ -d ~/HyDE ]; then
        (cd ~/HyDE && git fetch -q 2>/dev/null)
        if [ -d ~/HyDE ] && ! git -C ~/HyDE diff --quiet HEAD origin/HEAD 2>/dev/null; then
            PENDIENTES="$PENDIENTES\nHyDE tiene cambios nuevos en su repositorio"
        fi
    fi

    if [ -z "$PENDIENTES" ]; then
        gum style --foreground 212 "✅ Todo actualizado."
        return
    fi

    gum style --border rounded --padding "1 2" --border-foreground 214 \
        "⚠️  Hay actualizaciones disponibles:" "$(echo -e "$PENDIENTES")"

    if gum confirm "Actualizar ahora"; then
        [ -n "$PAC_UPD" ] && sudo pacman -Syu --noconfirm
        if command -v yay &>/dev/null && [ -n "${YAY_UPD:-}" ]; then
            yay -Syu --noconfirm
        fi
        if [ -d ~/HyDE ]; then
            (cd ~/HyDE && git pull -q && ./Scripts/install.sh)
        fi
        gum style --foreground 212 "✅ Actualizado."
    fi
}

while true; do
    OPCION=$(gum choose \
        "🛠️  Instalar herramientas de programador" \
        "⌨️  Ver atajos de teclado" \
        "📖 Ver manual completo (GitHub)" \
        "🔄 Buscar actualizaciones" \
        "🚪 Salir" \
        --header="=== MEAL — Menú principal ===")

    case "$OPCION" in
        "🛠️  Instalar herramientas de programador") instalar_herramientas ;;
        "⌨️  Ver atajos de teclado") ver_atajos ;;
        "📖 Ver manual completo (GitHub)") ver_manual_github ;;
        "🔄 Buscar actualizaciones") buscar_actualizaciones ;;
        "🚪 Salir"|"") exit 0 ;;
    esac
done
