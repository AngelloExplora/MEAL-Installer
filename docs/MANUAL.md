# Manual — MEAL Rama Manjaro

Bienvenido a "MEAL — Rama Manjaro". Este manual cubre todo lo que necesitas para usar tu sistema.

## Video de presentación

*(pendiente — pega aquí el link del video no listado cuando lo grabes)*

## Atajos de teclado

Ver [`atajos-de-teclado.md`](./atajos-de-teclado.md) para la tabla completa.

## Comandos disponibles

| Comando | Qué hace |
|---|---|
| `meal-menu` | Abre el menú principal: instalar herramientas, ver atajos, este manual, buscar actualizaciones |
| `meal-bienvenida` | La pantalla de bienvenida (se llama sola en el primer login) |

## Sesiones disponibles

Al iniciar sesión (SDDM), puedes elegir entre: **HyDE**, **Niri**, **Sway**, **Mango** — cada una aislada, sin pisarse entre sí.

## Actualizaciones

Desde `meal-menu` → "🔄 Buscar actualizaciones" — revisa Hyprland/Sway/Niri (pacman), Mango (AUR) y HyDE (su repo), y te deja actualizar todo con una confirmación.

## Idioma del sistema

Se elige durante la instalación. Para cambiarlo después:
```bash
sudo localectl set-locale LANG=xx_XX.UTF-8
```
