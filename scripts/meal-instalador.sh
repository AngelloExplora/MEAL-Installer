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

echo "======================================================"
echo " MEAL - Instalador para Manjaro"
echo "======================================================"
echo ""

# ==========================================================
# FASE 1: Renombrado de usuario (correr como root/sudo)
# ==========================================================
# Por seguridad del sistema, un usuario no puede renombrarse
# a sí mismo mientras tiene procesos activos. Por eso esta
# fase corre aparte, como root, desde una TTY (Ctrl+Alt+F2)
# con la sesión del usuario objetivo completamente cerrada.
# ==========================================================
if [ "$EUID" -eq 0 ]; then
    echo "=== Fase 1: elegir tu nombre de usuario ==="
    echo ""
    echo "Usuarios disponibles en este sistema:"
    awk -F: '$3>=1000 && $3<60000 {print "  - "$1}' /etc/passwd
    echo ""
    read -p "¿Cuál es tu usuario ACTUAL (el que quieres renombrar)?: " OLDNAME
    read -p "¿Qué nombre nuevo quieres ponerle?: " NEWNAME

    if ! id "$OLDNAME" &>/dev/null; then
        echo "❌ No existe un usuario llamado '$OLDNAME'."
        exit 1
    fi
    if pgrep -u "$OLDNAME" > /dev/null 2>&1; then
        echo "❌ '$OLDNAME' todavía tiene procesos activos."
        echo "   Cierra su sesión por completo (logout, no solo bloquear) e inténtalo de nuevo."
        exit 1
    fi

    usermod -l "$NEWNAME" "$OLDNAME"
    usermod -d "/home/$NEWNAME" -m "$NEWNAME"
    groupmod -n "$NEWNAME" "$OLDNAME" 2>/dev/null || true

    echo ""
    echo "✅ Listo: $OLDNAME → $NEWNAME (misma contraseña)."
    echo "   Inicia sesión como '$NEWNAME' y vuelve a correr este mismo script para instalar todo."
    exit 0
fi

# ==========================================================
# FASE 2: Instalación (correr como usuario normal, con sudo)
# ==========================================================
echo "Va a pedir tu contraseña de sudo UNA sola vez."
echo "Todo lo demás corre solo, sin más preguntas."
echo ""

# ---------- 0. Pedir sudo una sola vez y mantenerlo vivo ----------
sudo -v
( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT

# ---------- 0.1 Idioma del sistema ----------
echo ""
echo "==> ¿Qué idioma quieres para el sistema?"
IDIOMA=$(gum choose "Español (Perú)" "Español (España)" "English (US)" "Saltar, lo configuro después" 2>/dev/null || echo "Saltar, lo configuro después")
case "$IDIOMA" in
    "Español (Perú)") sudo localectl set-locale LANG=es_PE.UTF-8; sudo localectl set-keymap la-latin1 2>/dev/null || true ;;
    "Español (España)") sudo localectl set-locale LANG=es_ES.UTF-8 ;;
    "English (US)") sudo localectl set-locale LANG=en_US.UTF-8 ;;
    *) echo "   Saltado. Cámbialo luego con: sudo localectl set-locale LANG=xx_XX.UTF-8" ;;
esac

# ---------- 1. Prerrequisitos comunes ----------
echo "==> Instalando prerrequisitos base..."
sudo pacman -S --needed --noconfirm git base-devel timeshift
sudo pacman -S --needed --noconfirm hyprland xdg-desktop-portal-hyprland
sudo pacman -S --needed --noconfirm gum fuzzel kitty xdg-utils

echo "==> Instalando el menú de MEAL (meal-menu) y la bienvenida..."
sudo install -Dm755 "$(dirname "$0")/meal-menu.sh" /usr/local/bin/meal-menu
sudo install -Dm755 "$(dirname "$0")/meal-bienvenida.sh" /usr/local/bin/meal-bienvenida
sudo mkdir -p /usr/local/share/meal
sudo cp "$(dirname "$0")/../docs/atajos-de-teclado.md" /usr/local/share/meal/atajos-de-teclado.md

echo "==> Sacando snapshot de Timeshift antes de continuar..."
sudo timeshift --create --comments "antes de MEAL" || echo "   ⚠️  Timeshift no pudo crear snapshot, continuando de todas formas."

mkdir -p ~/meal-build
cd ~/meal-build

# ---------- 2. HyDE en config aislada ----------
echo ""
echo "==> [1/4] HyDE (aislado en ~/.config-hyde)"
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
echo "==> [2/4] Niri (aislado en ~/.config-niri)"
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

# ---------- 4. Sway en config aislada ----------
echo ""
echo "==> [3/4] Sway (aislado en ~/.config-sway)"
sudo pacman -S --needed --noconfirm sway
mkdir -p ~/.config-sway/sway
cp "$(dirname "$0")/../configs/sway/config" ~/.config-sway/sway/config 2>/dev/null || cat > ~/.config-sway/sway/config << 'EOF'
exec dms run
EOF

cat << 'EOF' | sudo tee /usr/share/wayland-sessions/sway-meal.desktop > /dev/null
[Desktop Entry]
Name=Sway (MEAL)
Comment=Sway + DankMaterialShell
Exec=env XDG_CONFIG_HOME=%h/.config-sway sway
Type=Application
EOF

# ---------- 5. Mango en config aislada (auto-detecta el paquete) ----------
echo ""
echo "==> [4/4] Mango 🥭 (aislado en ~/.config-mango)"
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
echo "    Sesiones disponibles en SDDM: HyDE / Niri / Sway / Mango (MEAL)"
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
