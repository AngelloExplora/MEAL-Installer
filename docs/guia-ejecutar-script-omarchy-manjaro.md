# Guía completa: correr el script de Omarchy forzado en Manjaro

## 1. Prerrequisitos en la VM de Manjaro

```bash
sudo pacman -S --needed git base-devel
```

`git` para clonar Omarchy, `base-devel` porque el instalador de Omarchy va a querer compilar algunas cosas (yay, paquetes de AUR) sobre la marcha.

---

## 2. Llevar el script a la VM de Manjaro

El archivo `forzar-omarchy-manjaro.sh` está en el chat para descargar — pero está en tu Windows, no en la VM. Tres formas de pasarlo, de más a menos cómoda:

**Opción A — Portapapeles compartido (si `open-vm-tools` ya te quedó funcionando):**
1. Abre el `.sh` descargado con el Bloc de notas en Windows, selecciona todo, copia.
2. En la VM, abre una terminal y corre `nano forzar-omarchy-manjaro.sh`.
3. Clic derecho dentro de la terminal → Pegar (o Ctrl+Shift+V según la terminal).
4. Guarda con Ctrl+O, Enter, sal con Ctrl+X.

**Opción B — Carpeta compartida de VMware:**
Si tienes una carpeta compartida configurada entre Windows y la VM, solo copia el archivo ahí y accede desde `/mnt/hgfs/` dentro de Manjaro.

**Opción C — Descarga directa (si el archivo estuviera hosteado en algún lado):**
No aplica aquí porque el script vive solo en tu descarga local, pero lo menciono por si en el futuro subes tus propios scripts a un Gist o repo tuyo — ahí sería `curl -O <url>`.

---

## 3. Verificar que se copió bien

```bash
cat forzar-omarchy-manjaro.sh | head -5
```

Debe mostrar el comentario inicial (`#!/bin/bash` y las líneas de descripción). Si ves caracteres raros o líneas cortadas, el copy-paste se rompió — repite la Opción A con más cuidado.

---

## 4. Dar permisos y ejecutar

```bash
chmod +x forzar-omarchy-manjaro.sh
./forzar-omarchy-manjaro.sh
```

---

## 5. Qué vas a ver, paso a paso

1. **"Clonando Omarchy"** — descarga el repo completo. Si falla aquí, es un problema de red, no del guard.
2. **"Existe carpeta preflight/, revisando..."** o **"No existe carpeta preflight/"** — esto te dice de una vez si tu versión de Omarchy tiene o no el chequeo de arquitectura. Cópiame exactamente qué te sale acá si algo falla más adelante.
3. **"Neutralizando..."** (solo si sí existía la carpeta) — lista los archivos que tocó.
4. **"Corriendo el instalador real de Omarchy"** — de aquí en adelante es el instalador oficial. Te va a pedir confirmar cosas (usuario, algunas preguntas de configuración) — dale Enter para aceptar los valores por defecto si no te importa personalizarlos ahora.

---

## 6. Los errores más probables (y qué hacen)

- **`error: target not found: <paquete>`** — un paquete que Omarchy espera no existe con ese nombre exacto en los repos de Manjaro (por versiones distintas). Cópiame el nombre del paquete que falla y buscamos el equivalente en Manjaro.
- **`failed to synchronize databases`** — la VM no tiene internet, o los espejos de Manjaro están caídos. Prueba `sudo pacman -Syy` aparte primero.
- **Se cuelga pidiendo una contraseña de sudo repetidamente** — normal, el instalador corre varios pasos con sudo; solo escribe tu contraseña cuando la pida.
- **Termina pero al reiniciar no ves Hyprland en el login** — puede que el instalador no haya registrado la sesión; revisa con `ls /usr/share/wayland-sessions/` que exista `hyprland.desktop` o similar.

---

## 7. Si todo salió bien

Reinicia, entra a la sesión de Hyprland/Omarchy, y de ahí seguimos con el ecosistema Hypr y los extras que ya dejamos listos (`hyprlock`, `hypridle`, portales, etc. del paso 20 de la otra guía).

Mándame el output completo (o al menos la parte donde se detiene, si se detiene) y seguimos desde ahí.
