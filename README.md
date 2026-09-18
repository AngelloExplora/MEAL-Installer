# MEAL — Mezcla Explosiva Arch Linux (rama Manjaro)

Scripts y configs propios para armar el stack MEAL sobre Manjaro: HyDE, Niri, Sway, Mango 🥭 y DankMaterialShell, todo bajo un solo usuario, cada entorno en su propia sesión aislada.

## ⚠️ Sobre Omarchy

Omarchy **no está incluido** en este repo. Desde su rediseño más reciente pasó a ser una distro completa que solo se instala desde [su propio ISO](https://omarchy.org) (formatea el disco o usa espacio libre para dual-boot) — ya no existe un `install.sh` que se pueda correr sobre un Manjaro o Arch ya instalado, así que no hay nada que "forzar" ni parchear. Si quieres tener Omarchy dentro de la comparación de MEAL, necesita su propia VM dedicada, instalada desde el ISO real.

## Estructura

```
scripts/
  meal-instalador.sh    → instala HyDE + Niri + Sway + Mango + DMS (un solo sudo, auto-reinicio)
  renombrar-usuario.sh  → renombra un usuario existente a "USER" sin perder la contraseña
  meal-menu.sh           → menú TUI (gum): instala herramientas de programador, muestra atajos
configs/
  niri/config.kdl        → autostart de DMS + atajos de teclado MEAL
  sway/config             → autostart de DMS + atajos de teclado MEAL
  mango/config.conf      → autostart de DankMaterialShell para Mango
docs/
  guia-meal-instalador.md
  guia-ejecutar-script-omarchy-manjaro.md   → guía histórica (ya no aplica, se deja de referencia)
  atajos-de-teclado.md   → tabla de atajos de teclado de MEAL
```

## Uso rápido

```bash
git clone https://github.com/AngelloExplora/MEAL-Installer.git
cd MEAL-Installer
chmod +x scripts/*.sh
./scripts/meal-instalador.sh
```

## Menú MEAL

Tras instalar, el comando `meal-menu` queda disponible en cualquier terminal (y con `Super + M` en Niri/Sway). Opciones:

- **Instalar aplicaciones** — por categoría: Programación (git, docker, lazygit, mise, jq, starship, fzf, zoxide, ripgrep, fd, bat, eza, etc.), Multimedia y contenido (OBS, Kdenlive, Obsidian, yt-dlp, etc.) y Sistema y utilidades (btop, fastfetch, screenshots).
- **Ver atajos de teclado**
- **Ver manual completo** (abre `docs/MANUAL.md` en GitHub)
- **Buscar actualizaciones** (Hyprland/Sway/Niri/Mango/HyDE, con confirmación antes de aplicar)

## Requisitos

- Manjaro ya instalado (con o sin formatear, este script no toca particiones)
- Usuario con permisos sudo
- Conexión a internet

## Créditos / dependencias externas

Este repo no vendoriza (copia completa) los proyectos de terceros — solo referencia sus instaladores oficiales para no quedar desactualizado:

- [HyDE](https://github.com/prasanthrangan/hyprdots) — dotfiles de Hyprland
- [Niri](https://github.com/YaLTeR/niri) — compositor scrollable
- [DankMaterialShell](https://danklinux.com/) — shell para Wayland
- [Hyprland](https://hypr.land/) un estilo monito de Waybar
- [Sway](https://swaywm.org/) — Sway es un compositor de Wayland de azulejos y un reemplazo de la caída para el Administrador de ventanas i3 para X11. Funciona con la configuración existente de i3 y soporta la mayoría de las características de i3, además de algunos extras.
