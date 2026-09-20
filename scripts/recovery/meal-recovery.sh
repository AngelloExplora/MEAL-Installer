#!/bin/bash
# meal-recovery.sh - MEAL Recovery
# Bash puro, sin gum a proposito (ver razonamiento de Fase 2: un entorno de
# rescate debe asumir el minimo de dependencias posibles).

set -Eeuo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

confirmar() {
    local mensaje="$1"
    read -p "$mensaje Escribe SI en mayusculas para confirmar: " respuesta
    [ "$respuesta" == "SI" ]
}

elegir_particion_raiz() {
    echo "Particiones disponibles:" >&2
    lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT >&2
    read -p "Escribe la particion raiz de MEAL (ej. /dev/sda2): " particion
    echo "$particion"
}

instalar_meal() {
    if command -v calamares &>/dev/null; then
        calamares
    else
        echo "ERROR: calamares no esta disponible en este entorno." >&2
    fi
}

reparar_sistema() {
    confirmar "Esto monta el sistema instalado y corre fsck + pacman -Syu --overwrite '*'." || { echo "Cancelado."; return; }
    local particion
    particion=$(elegir_particion_raiz)
    mkdir -p /mnt/meal-repair
    fsck -y "$particion" || true
    mount "$particion" /mnt/meal-repair
    arch-chroot /mnt/meal-repair pacman -Syu --overwrite '*'
    umount /mnt/meal-repair
    echo "Reparacion completada."
}

actualizar_meal() {
    if [ -d "$REPO_DIR/.git" ]; then
        (cd "$REPO_DIR" && git pull)
    else
        echo "Este entorno no tiene el repo de MEAL clonado con git; no se puede actualizar asi."
    fi
}

recuperar_configuracion() {
    local particion
    particion=$(elegir_particion_raiz)
    mkdir -p /mnt/meal-repair
    mount "$particion" /mnt/meal-repair
    if arch-chroot /mnt/meal-repair command -v timeshift &>/dev/null; then
        confirmar "Esto restaura el ultimo snapshot de Timeshift disponible." || { umount /mnt/meal-repair; return; }
        arch-chroot /mnt/meal-repair timeshift --restore
    else
        echo "No encontre Timeshift instalado en ese sistema."
    fi
    umount /mnt/meal-repair
}

mostrar_menu() {
    echo ""
    echo "=== MEAL Recovery ==="
    echo "1) Instalar MEAL"
    echo "2) Reparar sistema"
    echo "3) Actualizar MEAL"
    echo "4) Recuperar configuracion"
    echo "5) Terminal"
    echo "6) Reiniciar"
    echo "7) Apagar"
}

meal_recovery_loop() {
    while true; do
        mostrar_menu
        read -p "Elige una opcion: " opcion
        case "$opcion" in
            1) instalar_meal ;;
            2) reparar_sistema ;;
            3) actualizar_meal ;;
            4) recuperar_configuracion ;;
            5) echo "Escribe 'exit' para volver al menu."; bash ;;
            6) confirmar "Vas a reiniciar." && reboot ;;
            7) confirmar "Vas a apagar el equipo." && poweroff ;;
            *) echo "Opcion invalida." ;;
        esac
    done
}

# Permite hacer `source` de este archivo desde los tests sin arrancar el loop.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    meal_recovery_loop
fi
