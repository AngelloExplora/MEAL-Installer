#!/bin/bash
# install.sh - MEAL Shell (estilo Dank Linux: curl -fsSL <url>/install.sh | sh)

set -Eeuo pipefail

detectar_aur_helper() {
    if command -v yay &>/dev/null; then echo "yay"
    elif command -v paru &>/dev/null; then echo "paru"
    else echo ""
    fi
}

HELPER=$(detectar_aur_helper)
if [ -z "$HELPER" ]; then
    echo "MEAL Shell: no encontre yay ni paru. Instalando yay primero..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/meal-yay
    (cd /tmp/meal-yay && makepkg -si --noconfirm)
    HELPER="yay"
fi

# quickshell-git ANTES que cualquier otra cosa - evita que otro instalador
# (como DMS) arrastre la version de repo y genere conflicto de versiones.
echo "MEAL Shell: instalando quickshell-git..."
"$HELPER" -S --needed --noconfirm quickshell-git

echo "MEAL Shell: instalando dependencias de Qt..."
sudo pacman -S --needed --noconfirm qt6-svg qt6-imageformats qt6-multimedia qt5compat

DESTINO="$HOME/.config/quickshell"
mkdir -p "$DESTINO"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$REPO_DIR/shell.qml" "$DESTINO/shell.qml"

echo ""
echo "MEAL Shell instalado en $DESTINO"
echo "Agrega el autostart segun tu compositor:"
echo "  Hyprland: exec-once = quickshell"
echo "  Niri:     spawn-at-startup \"quickshell\""
echo "  Mango:    pgrep -x quickshell >/dev/null || quickshell &"
