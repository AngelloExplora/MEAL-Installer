#!/bin/bash
# ==========================================================
# MEAL - Mezcla Explosiva Arch Linux
# Instalador maestro para Manjaro (usuario único: USER)
# Automático: solo pide la contraseña de sudo UNA vez.
#
# NOTA: Omarchy NO está incluido aquí. Desde su rediseño,
# Omarchy solo se instala desde su propio ISO (formatea el
# disco entero) — ya no existe un install.sh para correr
# sobre un Manjaro/Arch existente. Si lo quieres probar,
# necesita su propia VM dedicada, instalada desde
# https://omarchy.org directamente.
# ==========================================================
# Corre esto YA como el usuario que va a tener todo instalado
# (recomendado: renombrado o creado como "USER").
#
# NUNCA correr con sudo por delante ni como root.
# ==========================================================

set -e

if [ "$EUID" -eq 0 ]; then
    echo "❌ No corras esto como root. Ejecútalo como tu usuario normal."
    exit 1
fi

echo "======================================================"
echo " MEAL - Instalador para Manjaro"
echo "======================================================"
echo ""
echo "Va a pedir tu contraseña de sudo UNA sola vez."
echo "Todo lo demás corre solo, sin más preguntas."
echo ""

# ---------- 0. Pedir sudo una sola vez y mantenerlo vivo ----------
sudo -v
( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT

# ---------- 1. Prerrequisitos comunes ----------
echo "==> Instalando prerrequisitos base..."
sudo pacman -S --needed --noconfirm git base-devel timeshift
sudo pacman -S --needed --noconfirm hyprland xdg-desktop-portal-hyprland

echo "==> Sacando snapshot de Timeshift antes de continuar..."
sudo timeshift --create --comments "antes de MEAL" || echo "   ⚠️  Timeshift no pudo crear snapshot, continuando de todas formas."

mkdir -p ~/meal-build
cd ~/meal-build

# ---------- 2. HyDE en config aislada ----------
echo ""
echo "==> [1/3] HyDE (aislado en ~/.config-hyde)"
echo "   ⚠️  HyDE modifica GRUB/SDDM globalmente sin importar el usuario."
export XDG_CONFIG_HOME="$HOME/.config-hyde"
mkdir -p "$XDG_CONFIG_HOME"
if [ ! -d ~/HyDE ]; then
    git clone --depth 1 https://github.com/prasanthrangan/hyprdots.git ~/HyDE 2>/dev/null || true
fi
(cd ~/HyDE/Scripts && ./install.sh) || echo "   ⚠️  HyDE terminó con avisos, revisa el log arriba."
unset XDG_CONFIG_HOME

cat << 'EOF' | sudo tee /usr/share/wayland-sessions/hyde-meal.desktop > /dev/null
[Desktop Entry]
Name=HyDE (MEAL)
Comment=Hyprland + HyDE
Exec=env XDG_CONFIG_HOME=%h/.config-hyde Hyprland
Type=Application
EOF

# ---------- 3. Niri en config aislada ----------
echo ""
echo "==> [2/3] Niri (aislado en ~/.config-niri)"
sudo pacman -S --needed --noconfirm niri xwayland-satellite
mkdir -p ~/.config-niri/niri
cp "$(dirname "$0")/../configs/niri/config.kdl" ~/.config-niri/niri/config.kdl 2>/dev/null || cat > ~/.config-niri/niri/config.kdl << 'EOF'
spawn-at-startup "dms" "run"
EOF

cat << 'EOF' | sudo tee /usr/share/wayland-sessions/niri-meal.desktop > /dev/null
[Desktop Entry]
Name=Niri (MEAL)
Comment=Niri + DankMaterialShell
Exec=env XDG_CONFIG_HOME=%h/.config-niri niri-session
Type=Application
EOF

# ---------- 4. Mango en config aislada (auto-detecta el paquete) ----------
echo ""
echo "==> [3/3] Mango 🥭 (aislado en ~/.config-mango)"
MANGO_PKG=""
for candidato in mango-wm-git mango-wm mangowc-git mangowc mango-git mango; do
    if yay -Si "$candidato" &>/dev/null; then
        MANGO_PKG="$candidato"
        break
    fi
done

if [ -n "$MANGO_PKG" ]; then
    echo "   Encontrado paquete: $MANGO_PKG"
    yay -S --noconfirm "$MANGO_PKG"
    mkdir -p ~/.config-mango/mango
    cp "$(dirname "$0")/../configs/mango/config.conf" ~/.config-mango/mango/config.conf 2>/dev/null || cat > ~/.config-mango/mango/config.conf << 'EOF'
autostart=dms run
EOF
    cat << 'EOF' | sudo tee /usr/share/wayland-sessions/mango-meal.desktop > /dev/null
[Desktop Entry]
Name=Mango (MEAL)
Comment=Mango compositor + DankMaterialShell
Exec=env XDG_CONFIG_HOME=%h/.config-mango mango
Type=Application
EOF
else
    echo "   ⚠️  No encontré el paquete de Mango automáticamente. Instálalo luego a mano con:"
    echo "       yay -Ss mango"
fi

# ---------- 5. DankMaterialShell compartido ----------
echo ""
echo "==> Instalando DankMaterialShell (compartido por Niri y Mango)..."
curl -fsSL https://install.danklinux.com | sh

echo ""
echo "======================================================"
echo " ✅ Instalación completa."
echo "    Sesiones disponibles en SDDM: HyDE / Niri / Mango (MEAL)"
echo "    (Omarchy no aplica aquí — requiere su propia VM con ISO)"
echo "======================================================"
echo ""

# ---------- 6. Reinicio ----------
read -p "¿Reiniciar el sistema ahora? [s/N]: " REINICIAR
if [[ "$REINICIAR" =~ ^[sS]$ ]]; then
    echo "Reiniciando..."
    sudo reboot
else
    echo "Ok, reinicia manualmente cuando quieras con: sudo reboot"
fi
