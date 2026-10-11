# Decisión de arquitectura — pivote a Bash-core + Hyprland/DMS

Fecha: ahora. Reemplaza el supuesto de Fase 0 (Calamares como nucleo) para
todo desarrollo nuevo. No se borra lo anterior.

## Decisión

1. **Motor del instalador: Bash puro** (pacstrap/genfstab/arch-chroot directos),
   no Calamares. Calamares queda como capa gráfica OPCIONAL futura, separada
   de la lógica (la logica no depende de que Calamares exista).
2. **Un solo escritorio activo: Hyprland + DankMaterialShell.** KDE, GNOME,
   XFCE, Niri y Mango (Fases 5/9/10/11) quedan en el repo tal cual estan,
   pausados - no se borran, no se desarrollan mas por ahora.
3. **Portabilidad tipo DMS**: el instalador debe funcionar across distintos
   entornos Arch-family (ISO oficial de Arch, Arch ya instalado, Manjaro,
   EndeavourOS, CachyOS), detectando el entorno en vez de asumir uno fijo.
   Honestidad: esto es "multi-sistema dentro de la familia Arch", no
   "cualquier distro Linux" - pacstrap/arch-chroot son herramientas de Arch,
   instalar una base Arch desde, por ejemplo, Ubuntu, no es lo mismo que
   DMS instalando un shell sobre un escritorio ya corriendo.

## Mapeo de carpetas (adaptar, no duplicar)

| Prompt nuevo pide | Ya existe como | Decisión |
|---|---|---|
| `packages/*.list` | `scripts/packages/*.list` | Se mantiene donde esta |
| `config/profiles/` | `scripts/profiles/*.conf` | Se mantiene donde esta |
| `scripts/common.sh`, `logging.sh`, `preflight.sh` | No existian | Se crean ahora |
| `bootstrap.sh` (raiz) | No existia | Se crea ahora, punto de entrada real |
| `modules/` | No existe asi | Se evalua mas adelante, no bloquea Fase C |

## Addendum 2026-10-11 — referencia Omakub

Por pedido del usuario se usa Omakub (Ubuntu + GNOME, MIT segun su README; ver `THIRD-PARTY-NOTICES.md`) de dos formas:

1. **Capa GNOME portada** (`scripts/postinstall/gnome-layer.sh`): retoma parcialmente GNOME, que estaba pausado,
   solo en su capa de configuracion. El entorno activo del instalador sigue siendo Hyprland + DMS.
2. **Referencia para el nucleo Hyprland + DMS**: de Omakub se tomo la idea de migraciones
   (`scripts/lib/migrations.sh`, pensado para MEAL Gestor).

Pendiente de esa segunda parte (no hecho): temas y menu. Antes hay que decidir como convive un sistema de temas
con DMS (no esta verificado como maneja DMS el suyo) y que terminal usa Hyprland (los temas de Omakub traen
`alacritty.toml`, no config de kitty).

Pendiente de verificar en Arch real: compatibilidad de las 6 extensiones con la version de GNOME Shell que traiga
Arch (las claves de gsettings solo se validaron contra los esquemas de GNOME 46 de Ubuntu 24.04), que paquete de Arch
provee GTop para TopHat, y los IDs de los .desktop de gnome-favorites.list.
