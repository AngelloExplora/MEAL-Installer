# MEAL — Mezcla Explosiva Arch Linux (rama Manjaro)

Scripts y configs propios para armar el stack MEAL sobre Manjaro: HyDE, Niri, Mango 🥭 y DankMaterialShell, todo bajo un solo usuario, cada entorno en su propia sesión aislada.

## ⚠️ Sobre Omarchy

Omarchy **no está incluido** en este repo. Desde su rediseño más reciente pasó a ser una distro completa que solo se instala desde [su propio ISO](https://omarchy.org) (formatea el disco o usa espacio libre para dual-boot) — ya no existe un `install.sh` que se pueda correr sobre un Manjaro o Arch ya instalado, así que no hay nada que "forzar" ni parchear. Si quieres tener Omarchy dentro de la comparación de MEAL, necesita su propia VM dedicada, instalada desde el ISO real.

## Estructura

```
scripts/
  meal-instalador.sh    → instala HyDE + Niri + Mango + DMS (un solo sudo, auto-reinicio)
  renombrar-usuario.sh  → renombra un usuario existente a "USER" sin perder la contraseña
configs/
  niri/config.kdl        → autostart de DankMaterialShell para Niri
  mango/config.conf      → autostart de DankMaterialShell para Mango
docs/
  guia-meal-instalador.md
  guia-ejecutar-script-omarchy-manjaro.md   → guía histórica (ya no aplica, se deja de referencia)
```

## Uso rápido

```bash
git clone <url-de-tu-repo> meal
cd meal
chmod +x scripts/*.sh
./scripts/meal-instalador.sh
```

## Requisitos

- Manjaro ya instalado (con o sin formatear, este script no toca particiones)
- Usuario con permisos sudo
- Conexión a internet

## Créditos / dependencias externas

Este repo no vendoriza (copia completa) los proyectos de terceros — solo referencia sus instaladores oficiales para no quedar desactualizado:

- [HyDE](https://github.com/prasanthrangan/hyprdots) — dotfiles de Hyprland
- [Niri](https://github.com/YaLTeR/niri) — compositor scrollable
- [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) — shell para Wayland
