# MEAL Installer 1.0

Instalador Linux basado en Arch Linux, propio, modular. Ver `docs/ARQUITECTURA.md` para el análisis completo (Fase 0).

> La rama Manjaro anterior (HyDE/Niri/Sway/Mango sobre un Manjaro ya instalado) sigue disponible en `main` — este branch (`installer-1.0`) es una iniciativa separada: una ISO propia basada en `archiso` + Calamares.

## Estado

**FASE 1 — Carpetas** ✅ (este commit)

Siguiente: FASE 2 — MEAL UI Engine.

## Estructura

```
archiso/            → perfil de archiso para construir la ISO en vivo
  airootfs/            overlay de archivos que van dentro de la ISO
calamares/           → configuración e instalador
  modules/             config de cada módulo (welcome, users, partition...)
  branding/meal/       branding propio de MEAL para Calamares
scripts/
  lib/                 MEAL UI Engine (envoltorio sobre gum)
  packages/            listas OBLIGATORIO/RECOMENDADO/OPCIONAL por perfil
  profiles/            definición de cada perfil (Básico/Gaming/Desarrollo...)
  desktop/             kde.sh, hyprland.sh, gnome.sh, xfce.sh
  boot/                MEAL Boot (Limine)
  recovery/            MEAL Recovery
  postinstall/         pasos posteriores a la instalación
docs/                → documentación del proyecto
tests/               → pruebas
```

## Requisitos para desarrollar

Máquina Arch Linux o basada en Arch, con `archiso`, `git`, `base-devel` instalados. `gum` para el UI Engine (Fase 2).
