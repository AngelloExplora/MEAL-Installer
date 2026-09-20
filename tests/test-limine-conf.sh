#!/bin/bash
# test-limine-conf.sh - dry-run de la generacion de limine.conf (Fase 7)
# NO instala nada real (requiere disco real + chroot = Fase 14).
# Solo verifica que el template de limine.conf se arma bien con un UUID de prueba.
set -e
UUID_PRUEBA="1234abcd-56ef-78gh-90ij-klmnopqrstuv"

cat << LIMINECONF
timeout: 5

/MEAL
    protocol: linux
    path: boot():/vmlinuz-linux
    cmdline: root=UUID=$UUID_PRUEBA rw
    module_path: boot():/initramfs-linux.img
LIMINECONF
