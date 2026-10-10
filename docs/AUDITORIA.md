# Auditoría del repositorio — MEAL-Installer (branch installer-1.0)

Hecha corriendo el código real, no leyendo los mensajes de commit. Fecha: ahora mismo, contra el estado real de GitHub.

## 1-5. Estructura real, commits, y qué se perdió

16 commits reales en `installer-1.0`. Estructura completa en `find . -type f`. Un hallazgo concreto: **la Fase 13 (construcción de ISO) que se mencionó como hecha en el chat nunca llegó a subirse** — los archivos (`profiledef.sh`, `packages.x86_64`, `pacman.conf`, `build.sh`, overlay de autologin) se generaron pero el `git push` nunca se ejecutó antes de que llegara este prompt nuevo. Solo existe `archiso/airootfs/.gitkeep`. Corrijo esto: de ahora en adelante, ninguna fase se da por "hecha" en el chat hasta confirmar con `git log` que el commit llegó a GitHub.

Tampoco existen `bootstrap.sh` ni `install.sh` en la raíz — este prompt nuevo los asume como punto de entrada ("Lee README.md, bootstrap.sh, install.sh"), pero el proyecto hasta ahora usa `scripts/recovery/meal-recovery.sh` como entrada (arranca con la ISO, opción "Instalar MEAL" lanza Calamares).

## 6. Qué está implementado vs incompleto

Todos los `.sh` del repo (29 archivos) tienen sintaxis válida (`bash -n`) y permisos de ejecución correctos. 10 archivos de prueba, resultado real corriéndolos ahora:

| Test | Resultado |
|---|---|
| test-desktop.sh | ✅ pasa |
| test-hyprland-ecosistema.sh | ✅ pasa |
| test-limine-conf.sh | ✅ pasa |
| test-meal-shell.sh | ✅ pasa |
| test-packages.sh | ✅ pasa |
| test-pacstrap-meal.sh | ✅ pasa |
| test-post-install.sh | ✅ pasa |
| test-profiles.sh | ✅ pasa |
| test-recovery.sh | ✅ pasa |
| test-ui-engine.sh | ❌ falla (falta `gum` en este sandbox - **esperado**, no es un bug) |

**Nada de código duplicado ni funciones muertas encontradas.**

## 7. Qué se puede correr aquí vs qué necesita un entorno real

Esta es la honestidad más importante de toda la auditoría: **los 9 tests que pasan solo verifican lógica en Bash puro** (resolución de listas de paquetes, templating de texto, rutas de archivos). Ninguno de ellos — ni uno solo — ejecutó jamás: `pacstrap` real, `arch-chroot` real, `limine-install` real, Calamares real, Quickshell real, o `gum` real. Este sandbox es Ubuntu, no Arch — no tiene `pacman`, no tiene gum, no tiene nada del stack real.

Es decir: **todo lo construido hasta ahora está verificado en su lógica, pero CERO por ciento verificado en un sistema Arch real.** Nivel 4 (máquinas virtuales) y Nivel 5 (ISO) de las pruebas que pide este prompt nunca se han ejecutado, ni una sola vez, en todo el proyecto.

## 8. Incompatibilidad real entre este prompt y lo ya construido

Esto es lo más importante de reportar antes de seguir. Este prompt nuevo describe un proyecto **distinto en dos decisiones de fondo** a lo que ya está construido:

**A) Calamares core vs Calamares opcional**
Lo construido (Fase 6): Calamares es el motor de instalación completo — `pacstrap-meal.conf`, `bootloader.conf`, todo el flujo pasa por sus módulos.
Este prompt: "La interfaz gráfica no debe ser un requisito... Separa la lógica del instalador de su interfaz" y "Evalúa Calamares como interfaz gráfica OPCIONAL" — pide un motor en Bash puro (`pacstrap`, `genfstab`, `arch-chroot` directos) con Calamares como capa opcional encima, no al revés.

**B) Multi-escritorio vs Hyprland+DMS único**
Lo construido (Fases 5, 9, 10, 11): KDE, Hyprland, Niri, Mango, GNOME, XFCE, todos seleccionables.
Este prompt: "Entorno gráfico: Hyprland con Dan Material Shell (DMS)" — un solo entorno, sin mencionar los otros cinco.

No voy a decidir esto por mi cuenta — ambas son arquitecturas válidas, pero son proyectos distintos en tamaño y alcance.
