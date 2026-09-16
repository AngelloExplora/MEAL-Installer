# MEAL — Guía del instalador maestro para Manjaro

## Por qué el script no "formatea" por sí solo

Un script corre dentro del sistema operativo ya arrancado. Formatear el disco donde ese mismo sistema está corriendo no es posible sin colgar la sesión a la mitad — por eso el "formateo real" siempre pasa por el instalador gráfico (Calamares) desde el USB de Manjaro, nunca desde un script en vivo.

Por eso el flujo queda así:

| Quieres... | Qué haces |
|---|---|
| Empezar de cero (formateado) | 1. Arranca el USB de Manjaro → instala normal con Calamares → crea el usuario **USER** ahí mismo → 2. Ya adentro, corre `meal-instalador.sh` y elige **opción 1** |
| Agregar todo sin tocar tu Manjaro actual | Corre `meal-instalador.sh` directamente en tu sistema actual y elige **opción 2** |

La diferencia entre las dos opciones dentro del script es solo si saca un snapshot de Timeshift antes (opción 2, por seguridad, ya que hay algo que perder) o no (opción 1, porque el sistema está recién instalado y no tiene nada que respaldar).

---

## Cómo queda armado, usuario único "USER"

En vez de un usuario del sistema por cada entorno (como hicimos antes), ahora todo vive en el **mismo usuario**, pero cada pieza tiene su propia carpeta de configuración aislada:

- `~/.config-omarchy` → sesión "Omarchy (MEAL)"
- `~/.config-hyde` → sesión "HyDE (MEAL)"
- `~/.config-niri` → sesión "Niri (MEAL)"
- `~/.config-mango` → sesión "Mango (MEAL)"

Cada sesión aparece por separado en la pantalla de login de SDDM (mismo usuario, distinta sesión) gracias a los archivos `.desktop` que el script crea en `/usr/share/wayland-sessions/`.

---

## Cómo correrlo

```bash
chmod +x meal-instalador.sh
./meal-instalador.sh
```

Te va preguntando en el camino: modo (1 o 2), y el nombre exacto del paquete de Mango (porque puede variar, `yay -Ss mango` te muestra las opciones antes de pedírtelo).

---

## Aviso sobre HyDE

A diferencia de las otras tres, HyDE toca **GRUB, SDDM y `/etc/pacman.conf` globalmente**, sin importar en qué carpeta aislada corra. Eso significa que puede cambiar el tema visual de SDDM o el menú de GRUB aunque tú elijas otra sesión después — es cosmético, no rompe nada funcionalmente, pero por eso el script instala Timeshift desde el inicio.

---

## Si algo falla a la mitad

El script usa `set -e`, así que se detiene en el primer error real. Vuelve a correrlo — ya tiene `--needed` y comprobaciones de "si ya existe, sáltalo", así que es seguro re-ejecutarlo sin duplicar trabajo. Mándame el mensaje de error exacto que te muestre y seguimos desde ahí.
