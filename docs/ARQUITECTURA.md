# MEAL Installer 1.0 — Análisis de arquitectura (FASE 0)

*No se ha escrito ningún código todavía, según lo pedido. Este documento espera "APROBADO, EMPEZAMOS".*

---

## ⚠️ Antes de todo: conflicto con el repo actual

`AngelloExplora/MEAL-Installer` ya tiene contenido subido (rama Manjaro: HyDE, Niri, Sway, Mango, `meal-menu`, etc.). Este prompt pide reconstruir "desde cero" — voy a asumir que **reemplaza** ese enfoque, pero no voy a tocar el repo hasta que lo confirmes explícitamente. Si quieres conservar la rama Manjaro en paralelo (por ejemplo como branch `manjaro-layer` separado de `main`), dímelo antes de "APROBADO, EMPEZAMOS".

---

## 1. Arquitectura definitiva recomendada

El patrón que describes (Arch + Calamares + ISO propia) ya existe y funciona en distros reales — no hay que inventar nada, hay que adaptar un patrón probado. Las referencias más cercanas:

- **EndeavourOS**: usa `archiso` (la herramienta oficial de Arch para construir ISOs) muy modificado, más un fork propio de Calamares con un módulo de instalación **online** (pacstrap en vivo, no una imagen pre-armada) y otro **offline** (squashfs). Confirma que "Calamares + Arch real" es viable en ambos modos.
- **ALCI (Arch Linux Calamares Installer)** y **Calam-Arch**: proyectos específicamente diseñados para instalar Arch "casi vanilla" con Calamares — la referencia más directa a lo que describes.
- **ArcoLinux**, **CachyOS**, **Garuda**: mismo patrón, cada uno con su propia capa de personalización.

Arquitectura recomendada:

```
archiso (base oficial) → perfil MEAL (paquetes + airootfs) → ISO en vivo
   ↓
MEAL Boot (bootloader de la ISO en vivo — ver riesgo en punto 9)
   ↓
Sesión en vivo (gum + meal-menu para probar antes de instalar)
   ↓
Calamares (fork/config propio) — módulo de instalación tipo "online" (pacman en vivo, como EndeavourOS) para no depender de reconstruir una imagen squashfs cada vez que cambie un paquete
   ↓
Selección de perfil (Básico/Portátil/Gaming/Desarrollo/Contenido/Personalizado) → Selección de escritorio (KDE/Hyprland/GNOME/XFCE)
   ↓
Sistema instalado + MEAL Recovery en partición/entrada de boot separada
```

**Por qué "online" (pacman en vivo) y no squashfs**: con squashfs, cada vez que actualizas un paquete tienes que reconstruir toda la imagen de la ISO. Con instalación en vivo (pacstrap durante el install), el sistema instalado siempre lleva paquetes actuales de los repos — mismo patrón que ya usa EndeavourOS. Costo: la instalación requiere internet (razonable, ya lo asume Manjaro/Arch también).

---

## 2. Estructura completa de carpetas

Ajusto la tuya — la general está bien, pero separo `airootfs/` (lo que necesita `archiso` específicamente) de `scripts/`:

```
MEAL-Installer/
├── README.md
├── LICENSE
├── archiso/                    # perfil de archiso (basado en releng)
│   ├── packages.x86_64
│   ├── airootfs/                # overlay de archivos que van dentro de la ISO
│   ├── profiledef.sh
│   └── build.sh
├── calamares/
│   ├── settings.conf
│   ├── modules/                 # config de cada módulo (welcome.conf, users.conf...)
│   └── branding/meal/
├── scripts/
│   ├── lib/                     # MEAL UI Engine (ver punto 11)
│   ├── packages/                # listas OBLIGATORIO/RECOMENDADO/OPCIONAL por perfil
│   ├── profiles/
│   ├── desktop/                 # kde.sh, hyprland.sh, gnome.sh, xfce.sh
│   ├── boot/                    # meal-boot (Limine)
│   ├── recovery/                # meal-recovery
│   └── postinstall/
├── docs/
└── tests/
```

No es definitiva — si en Fase 1 aparece fricción real con esta división, se ajusta.

---

## 3–4. Lista de paquetes (~50) clasificados

**OBLIGATORIO** (base mínima funcional, sin esto no arranca ni tiene red):
`base`, `linux`, `linux-firmware`, `sudo`, `systemd`, `bash`, `coreutils`, `util-linux`, `pacman`, microcode (`intel-ucode` o `amd-ucode` según hardware detectado), `networkmanager`, `sddm` (o el gestor de sesión del DE elegido)

**RECOMENDADO** (marcados por defecto, el usuario puede desmarcar):
`reflector`, `pacman-contrib`, `zstd`, `power-profiles-daemon`, `systemd-zram-generator` (moderno, reemplaza al `zram-generator` viejo), `pipewire`, `pipewire-pulse`, `pipewire-alsa`, `wireplumber`, `pavucontrol`, `xdg-desktop-portal` + el portal específico del DE, `git`, `curl`, `wget`, `fastfetch`, `btop`, `eza`, `zoxide`, `fzf`, `unzip`, `tar`, `nano`

**OPCIONAL** (desmarcados por defecto, van con el perfil que los active):
- *Gaming*: `steam`, `wine`, `gamemode`, `gamescope`, `mangohud`
- *Desarrollo*: `base-devel`, `gcc`, `make`, `cmake`, `python`, `nodejs`, `npm`, `docker`, `visual-studio-code-bin` (AUR)
- *Contenido*: `obs-studio`, `kdenlive`, `gimp`, `inkscape`

**NO NECESARIO** (los descarto y por qué):
- `auto-cpufreq` — se solapa con `power-profiles-daemon`; instalar ambos causa conflictos reales de gobernor. Elegir uno, no los dos.
- `iwd` — solo si decides reemplazar wpa_supplicant por completo; NetworkManager con su backend por defecto ya cubre el 95% de los casos. Déjalo para un perfil "avanzado" si acaso.
- `fstrim` como paquete — ya viene en `util-linux`, no es un paquete aparte; lo que se activa es el *timer* `fstrim.timer`.

**Gráficos**: no se listan como "un paquete", se detectan por hardware — `mesa` + `vulkan-icd-loader` siempre; luego `intel-media-driver`/`vulkan-intel`, `xf86-video-amdgpu`/`vulkan-radeon`, o `nvidia nvidia-utils` (o `nvidia-open` en tarjetas Turing+) según lo que devuelva `lspci`.

---

## 5. Dependencias de KDE Plasma

- **Obligatorio real**: `plasma-desktop` (no todo `plasma-meta`, que trae ~40 paquetes incluyendo cosas que no todos quieren), `sddm`, `konsole`, `dolphin`
- **Recomendado**: `kde-gtk-config` (para que apps GTK no se vean rotas dentro de Plasma), `xdg-desktop-portal-kde`, `ark` (archivos), `kcalc`
- **Opcional**: el resto de `kde-applications` (Kate, Okular, Spectacle, etc.) — que el usuario elija cuáles

## 6. Dependencias de Hyprland

`hyprland`, `xdg-desktop-portal-hyprland`, `qt5-wayland`, `qt6-wayland`, `polkit-kde-agent` (o el agente polkit que uses), una terminal (`kitty`), un lanzador (`fuzzel` o `wofi`), `hyprpaper` o `swaybg` (fondo), opcionalmente `hypridle`+`hyprlock`. Para la barra: aquí es donde entra la decisión del punto 11 — DankMaterialShell (ya la conocemos de la rama Manjaro) es una opción real, o Waybar como alternativa más ligera.

## 7. Plan para GNOME y XFCE

- **GNOME**: NO instalar `gnome` (el grupo completo, ~200 paquetes). Usar `gnome-shell` + `gdm` + `nautilus` + `gnome-control-center` como base, y el resto (Totem, Music, etc.) como opcional.
- **XFCE**: `xfce4` (grupo base) sin `xfce4-goodies` por defecto; goodies como opcional.
- Ambos como perfiles de escritorio independientes, mismo patrón que KDE/Hyprland — no se listan juntos nunca en la instalación por defecto (coincide con tu regla del punto 2).

## 8. Integración de Calamares

Paquete: `calamares` o `calamares-git` (AUR, ambos activamente mantenidos). Necesita branding propio (`calamares/branding/meal/branding.desc`) y config de módulos en secuencia: `welcome → locale → keyboard → partition → users → summary` (show phase) y `mount → unpackfs-o-pacman → machineid → fstab → localecfg → initcpiocfg → initcpio → bootloader → postcfg` (exec phase).

**Decisión abierta que hay que resolver en Fase 6, no ahora**: ¿módulo `unpackfs` (imagen pre-armada) o un módulo tipo `pacman`/shell-process que haga pacstrap en vivo (como el modo "online" de EndeavourOS)? Recomiendo estudiar el módulo real de EndeavourOS-Calamares (es público) antes de decidir, en vez de escribir uno desde cero a ciegas.

## 9. Integración de Limine

**Riesgo real, no trivial**: la documentación oficial de Calamares solo lista **systemd-boot o GRUB2** como dependencias documentadas de su módulo `bootloader`. Limine no es una opción nativa. EndeavourOS mismo usa systemd-boot (UEFI) + syslinux (BIOS legacy), no Limine.

Para que Limine funcione con Calamares hay dos caminos:
1. Escribir un módulo custom de Calamares para Limine (mismo patrón que el módulo `refind` que sí existe en `calamares-extensions` como ejemplo de bootloader no-core añadido por la comunidad).
2. Usar el módulo `shellprocess` de Calamares para invocar tu propio script de instalación de Limine post-partición, sin escribir un módulo C++/Python completo — más rápido de lograr, menos "nativo".

Recomiendo la opción 2 para la Beta 1.0, y dejar el módulo nativo como mejora futura.

## 10. Diseño de MEAL Recovery

Inspirado en el concepto (no el diseño visual) de un recovery Android: un entorno mínimo aparte del sistema instalado, arrancable desde el menú de boot. La forma más realista de lograrlo sin duplicar trabajo: reutilizar el mismo `airootfs` de la ISO en vivo, copiado a una partición/carpeta separada en el disco, con una entrada de arranque dedicada.

Menú (con `gum`, coherente con lo que ya construimos en la rama Manjaro):
```
MEAL Recovery
> Instalar MEAL       (lanza Calamares)
> Reparar sistema      (chroot al sistema instalado + fsck + pacman -Syu --overwrite)
> Actualizar MEAL
> Recuperar configuración   (restaurar desde snapshot Timeshift, si existe)
> Terminal
> Reiniciar
> Apagar
```
Referencia de qué incluir como herramientas de rescate: EndeavourOS trae en su ISO `testdisk`, `clonezilla`, `partclone`, `gparted`, `ddrescue` — buen punto de partida ya probado en producción.

## 11. Diseño de MEAL UI Engine

Aquí te doy mi opinión de ingeniería, no solo ejecuto lo pedido: la estructura `lib/` que propones (colors.sh, tui.sh, menu.sh, checkbox.sh, dialog.sh, progress.sh, spinner.sh...) es básicamente **reconstruir lo que `gum` ya hace**, la misma herramienta que ya usamos en `meal-menu` (menús, checkboxes con `gum choose --no-limit`, confirmaciones con `gum confirm`, progreso con `gum spin`, estilos con `gum style`). Omarchy mismo usa `gum` para esto — no lo hace desde cero.

**Recomendación**: no reconstruyas el motor a mano para el Installer principal — envuelve `gum` en tus propios `theme.sh`/`tui.sh` con la paleta de colores de MEAL, y listo. Ahorra semanas de trabajo y mantenimiento.

**Excepción real**: para **MEAL Recovery** específicamente sí tiene sentido un subconjunto mínimo hecho a mano (sin depender de `gum`), porque un entorno de rescate debe asumir el mínimo de dependencias posibles — si algo se rompió en el sistema, no quieres que tu herramienta de reparación dependa de un paquete que también pudo romperse.

## 12. Diseño del sistema de perfiles

Cada perfil como un archivo declarativo simple (no un script con lógica), por ejemplo `scripts/profiles/desarrollo.conf`:
```bash
NOMBRE="Desarrollo"
DESCRIPCION="Herramientas para programar"
PAQUETES="base-devel gcc make cmake python nodejs npm docker"
TAMANO_APROX_MB=1800
SERVICIOS="docker.service"
```
Un script genérico (`profiles.sh`) los lee todos, se los pasa al UI Engine para mostrar el checklist, y arma la lista final de paquetes para Calamares.

## 13. Diseño del sistema de paquetes

Tres listas por perfil: OBLIGATORIO (siempre, no aparece en el checklist), RECOMENDADO (aparece pre-marcado), OPCIONAL (aparece sin marcar). El checklist final que ve el usuario es la unión de RECOMENDADO+OPCIONAL de todos los perfiles que activó, sin duplicados.

## 14. Plan de construcción de la ISO

Estándar `archiso`: partir del perfil `releng` oficial (`/usr/share/archiso/configs/releng/`), copiarlo como base de `archiso/`, agregar `packages.x86_64` propio, meter overlays en `airootfs/` (branding, `meal-menu`, la config del UI Engine), y construir con `mkarchiso -v -o out/ archiso/`. Mismo mecanismo que usa EndeavourOS, solo que su perfil está mucho más modificado que un `releng` limpio.

## 15. Riesgos técnicos

- **Limine + Calamares**: no hay integración nativa (punto 9) — es el riesgo técnico más concreto del proyecto.
- **Decisión online vs squashfs sin resolver todavía** (punto 8) — bloquea la Fase 6 hasta que se investigue el módulo real de EndeavourOS.
- **Naturaleza rolling-release de Arch**: un paquete que hoy instala bien puede romperse en 2 semanas. Sin un pipeline de pruebas automatizado, cada rebuild de la ISO puede fallar por sorpresa.
- **Alcance del proyecto**: lo que describes (Boot + Recovery + UI Engine + Calamares + 4 escritorios + ISO) es, en tamaño real, comparable a EndeavourOS o CachyOS — proyectos con equipos de varias personas. Como riesgo honesto: el cronograma de 15 fases es correcto en orden, pero el volumen de trabajo por fase es grande; conviene tratar cada fase como su propio hito con tiempo real asignado, no asumir que son pasos rápidos.
- **Multi-DE en la misma ISO**: si algún día quieres poder cambiar de escritorio ya instalado (no solo elegir uno al instalar), instalar/desinstalar DEs completos en un sistema ya en uso genera basura de dependencias huérfanas — hay que decidir si eso es un caso de uso soportado o no.

## 16. Orden exacto de desarrollo

Tu orden (Fase 0 a 15) es correcto tal cual lo planteaste — Arquitectura → Carpetas → UI Engine → Paquetes → Perfiles → KDE → Calamares → Boot+Limine → Recovery → Hyprland → GNOME → XFCE → Post-install → ISO → Pruebas → Beta. Un solo ajuste sugerido: mover la investigación del módulo de Calamares (online vs squashfs, punto 8) **antes** de la Fase 5 (KDE), porque esa decisión afecta cómo se prueba KDE desde el principio (¿se prueba dentro de la ISO en vivo con pacstrap, o se prueba con una imagen ya armada?). El resto del orden queda igual.

---

## Video privado / manual

Espacio reservado para cuando grabes el video no listado — pégalo en `docs/MANUAL.md` cuando lo tengas.

---

Quedo esperando: (1) tu confirmación sobre qué hacer con la rama Manjaro ya subida, y (2) **"APROBADO, EMPEZAMOS"** para recién empezar con Fase 1.
