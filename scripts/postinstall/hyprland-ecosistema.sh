#!/bin/bash
# hyprland-ecosistema.sh - instala HyDE, Mango y DankMaterialShell
# Portatil: funciona en cualquier sistema basado en pacman (Manjaro, CachyOS,
# EndeavourOS, Arch vanilla...), no asume nada especifico de una sola distro.
#
# Hyprland y Niri NO se clonan aqui - ya vienen de los repos oficiales via
# pacman (scripts/desktop/hyprland.list y niri.list). Este script cubre
# solo lo que SI necesita instalarse por fuera de pacman:
#   - HyDE: no esta empaquetado, se clona con git
#   - Mango: esta en AUR, se instala con el ayudante de AUR que exista
#   - DankMaterialShell: tiene su propio instalador oficial

set -Eeuo pipefail

detectar_aur_helper() {
    if command -v yay &>/dev/null; then echo "yay"
    elif command -v paru &>/dev/null; then echo "paru"
    else echo ""
    fi
}

instalar_hyde() {
    echo "MEAL: instalando HyDE..."
    if [ ! -d ~/HyDE ]; then
        git clone --depth 1 https://github.com/prasanthrangan/hyprdots.git ~/HyDE
    fi
    (cd ~/HyDE/Scripts && ./install.sh)
}

instalar_mango() {
    local helper
    helper=$(detectar_aur_helper)
    if [ -z "$helper" ]; then
        echo "MEAL: no encontre yay ni paru. Instalando yay primero..."
        sudo pacman -S --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        (cd /tmp/yay && makepkg -si --noconfirm)
        helper="yay"
    fi
    echo "MEAL: instalando Mango via $helper..."
    for candidato in mango-wm-git mango-wm mangowc-git mangowc mango-git mango; do
        if "$helper" -Si "$candidato" &>/dev/null; then
            "$helper" -S --needed --noconfirm "$candidato"
            return
        fi
    done
    echo "MEAL: no encontre el paquete de Mango automaticamente. Instalalo a mano despues."
}

instalar_dms() {
    echo "MEAL: instalando DankMaterialShell..."
    curl -fsSL https://install.danklinux.com | sh
}

# Uso: hyprland-ecosistema.sh kde|hyprland|niri|mango
ESCRITORIO="${1:?Uso: $0 kde|hyprland|niri|mango}"

case "$ESCRITORIO" in
    hyprland)
        instalar_hyde
        instalar_dms
        ;;
    niri)
        instalar_dms
        ;;
    mango)
        instalar_mango
        instalar_dms
        ;;
    kde)
        echo "MEAL: KDE no necesita nada de este script."
        ;;
    *)
        echo "Escritorio desconocido: $ESCRITORIO" >&2
        exit 1
        ;;
esac
