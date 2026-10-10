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
