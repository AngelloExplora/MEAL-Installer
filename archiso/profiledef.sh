#!/usr/bin/env bash
# profiledef.sh - perfil de archiso para MEAL
# Basado en el perfil releng oficial (confirmado via ArchWiki), adaptado.

iso_name="meal"
iso_label="MEAL_$(date +%Y%m)"
iso_publisher="MEAL Installer <https://github.com/AngelloExplora/MEAL-Installer>"
iso_application="MEAL Installer - Mezcla Explosiva Arch Linux"
iso_version="$(date +%Y.%m.%d)"
install_dir="meal"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito'
           'uefi-x64.systemd-boot.esp' 'uefi-x64.systemd-boot.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '19')
file_permissions=(
  ["/root"]="0:0:750"
  ["/root/.bash_profile"]="0:0:755"
)
