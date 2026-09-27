#!/bin/bash
# zaneyos-install.sh - ZaneyOS encima de MEAL NixOS (post-instalacion)
#
# Solo para la rama NixOS de MEAL (Fase NixOS) - ZaneyOS es una config de
# Nix flakes + Home Manager, no existe version para Arch/Manjaro/CachyOS.
#
# HONESTIDAD: no pude leer el contenido real de install-zaneyos.sh (GitLab
# necesita JS para mostrarlo), asi que esto sigue el patron documentado en su
# propio README (clonar a ~/zaneyos + correr su instalador) pero SIN inventar
# que se el detalle exacto de que toca. Revisa su README/FAQ antes de correrlo:
# https://gitlab.com/Zaney/zaneyos

set -Eeuo pipefail

if [ ! -f /etc/NIXOS ]; then
    echo "ERROR: esto es solo para la rama NixOS de MEAL. Este sistema no es NixOS." >&2
    exit 1
fi

echo "ZaneyOS reemplaza buena parte de tu configuracion de Hyprland/Home Manager."
echo "Revisa antes: https://gitlab.com/Zaney/zaneyos/-/blob/main/README.md"
read -p "Escribe SI en mayusculas para continuar: " confirmar
[ "$confirmar" == "SI" ] || { echo "Cancelado."; exit 0; }

if [ ! -d ~/zaneyos ]; then
    git clone https://gitlab.com/Zaney/zaneyos.git ~/zaneyos
fi
cd ~/zaneyos && ./install-zaneyos.sh
