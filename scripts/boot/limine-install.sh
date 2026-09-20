#!/bin/bash
# limine-install.sh - MEAL Boot: instala y configura Limine
#
# Estrategia (confirmada contra ArchWiki, no inventada): usar la ruta de
# fallback UEFI (esp/EFI/BOOT/BOOTX64.EFI) como metodo PRINCIPAL, ya que
# es la recomendacion oficial para maxima compatibilidad quando no se puede
# garantizar que efibootmgr cree entradas NVRAM correctamente en el firmware
# real del usuario. La entrada NVRAM se intenta ademas, pero de forma
# no bloqueante.
#
# PENDIENTE DE VERIFICAR (Fase 14): como expone realmente el modulo
# shellprocess de Calamares el disco/particion elegidos por el usuario.
# Aqui se asumen variables de entorno; puede requerir ajuste real.

set -Eeuo pipefail

RAIZ="${ROOT_MOUNT_POINT:-/mnt/meal-root}"
DISCO="${MEAL_DISCO:?falta MEAL_DISCO, ej. /dev/sda (ver nota de verificacion pendiente arriba)}"
PARTICION_ESP_NUM="${MEAL_ESP_PART_NUM:?falta MEAL_ESP_PART_NUM, ej. 1}"
ESP="$RAIZ/boot"

echo "MEAL Boot: instalando limine..."
arch-chroot "$RAIZ" pacman -S --needed --noconfirm limine

mkdir -p "$ESP/EFI/BOOT"
cp "$RAIZ/usr/share/limine/BOOTX64.EFI" "$ESP/EFI/BOOT/BOOTX64.EFI"

UUID_RAIZ=$(blkid -o value -s UUID "$(findmnt -no SOURCE "$RAIZ")")
[ -n "$UUID_RAIZ" ] || { echo "MEAL Boot: no pude obtener el UUID de la raiz" >&2; exit 1; }

cat > "$ESP/EFI/BOOT/limine.conf" << LIMINECONF
timeout: 5

/MEAL
    protocol: linux
    path: boot():/vmlinuz-linux
    cmdline: root=UUID=$UUID_RAIZ rw
    module_path: boot():/initramfs-linux.img

# MEAL Recovery (Fase 8): ruta real pendiente de confirmar en Fase 14 -
# depende de donde termine viviendo el entorno de recovery en el disco
# (particion propia / dentro de la ESP / imagen aparte - decision de
# particionado, no de este script).
/MEAL Recovery
    protocol: linux
    path: boot():/meal-recovery/vmlinuz-linux
    cmdline: root=UUID=$UUID_RAIZ rw meal_recovery=1
    module_path: boot():/meal-recovery/initramfs-linux.img
LIMINECONF

echo "MEAL Boot: intentando entrada NVRAM (no critico si falla)..."
arch-chroot "$RAIZ" efibootmgr --create --disk "$DISCO" --part "$PARTICION_ESP_NUM" \
    --label "MEAL" --loader '\EFI\BOOT\BOOTX64.EFI' --unicode \
    || echo "MEAL Boot: entrada NVRAM no se pudo crear - no es critico, ya se instalo en la ruta de fallback"

arch-chroot "$RAIZ" mkinitcpio -P

echo "MEAL Boot: Limine instalado correctamente."
