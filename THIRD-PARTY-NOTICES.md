# Avisos de terceros

## Omakub

- Proyecto: Omakub — https://github.com/basecamp/omakub
- Licencia declarada: **MIT**, segun el README del proyecto ("released under the MIT License").
- Verificado el 2026-10-11 clonando el repositorio upstream: **no contiene un archivo LICENSE ni una linea de
  copyright**. Por eso no podemos reproducir el aviso de copyright exacto; se atribuye al proyecto Omakub
  (basecamp/omakub). Si upstream agrega un LICENSE, copiarlo aqui.
- Fuente usada: el zip proporcionado (carpeta `omakub-1.5.0`; su archivo `version` interno dice 1.4.0, el de
  upstream master dice 1.5.0). Los 5 archivos usados (set-gnome-settings.sh, set-gnome-hotkeys.sh, set-gnome-extensions.sh, set-dock.sh, themes/set-gnome-theme.sh) son byte a byte iguales entre el zip y upstream master (verificado con diff el 2026-10-11).

### Que se derivo

| Archivo de MEAL | Origen en Omakub | Cambios |
|---|---|---|
| `scripts/desktop/gnome-core.tsv` | `set-gnome-settings.sh`, `set-gnome-hotkeys.sh`, `themes/set-gnome-theme.sh` | Datos generados con un parser (shlex). Se omiten atajos que dependen de apps que MEAL no instala y el dash-to-dock. Del tema solo se toma el modo oscuro |
| `scripts/desktop/gnome-extensions.list` y `gnome-extensions-settings.tsv` | `set-gnome-extensions.sh` | Mismos UUID y ajustes, menos TopHat (dependencia sin verificar en Arch) y los ajustes de blur-my-shell para dash-to-dock |
| `scripts/desktop/gnome-favorites.list` y `meal_gnome_favorites_list` | `set-dock.sh` | Misma idea (solo apps con .desktop instalado), apps distintas, y corregido el caso de lista vacia |
| `scripts/postinstall/gnome-layer.sh`, `scripts/lib/gnome.sh` | `install/desktop/*.sh` | Reescritos para Arch (pacman, sin modificar /usr/share ni borrar .desktop del sistema) |
| `scripts/lib/migrations.sh` | `bin/omakub-sub/migrate.sh` | Solo la idea; reimplementado (sin git pull, con manifiesto SHA-256 y verificacion previa) |

### Que NO se copio

- Fondos de pantalla e imagenes de los temas: su licencia no esta confirmada.
- Todo lo especifico de Ubuntu (apt, comprobacion de version, Yaru, y `set-app-grid.sh`, que borra archivos
  .desktop del sistema con sudo).
- Los atajos personalizados que lanzan Ulauncher, Flameshot, Alacritty, Chrome y ASDControl.
