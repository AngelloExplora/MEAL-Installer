#!/bin/bash
# ryoku-on-nixos-install.sh - Ryoku (Hyprland/Niri) para MEAL NixOS
#
# Solo para la rama NixOS de MEAL. Requiere una config NixOS basada en
# flakes - esto NO esta confirmado que nuestro modulo "nixos" de
# calamares-nixos-extensions (Fase NixOS) lo genere asi por defecto.
# Verificar en Fase 14 antes de prometer que esto funciona de una.
#
# El propio proyecto lo marca como "instalador todavia nuevo, en pruebas
# contra distintos layouts de flake" - por eso el --dry-run primero.

set -Eeuo pipefail

if [ ! -f /etc/NIXOS ]; then
    echo "ERROR: esto es solo para la rama NixOS de MEAL." >&2
    exit 1
fi

if ! command -v nix &>/dev/null; then
    echo "ERROR: falta el comando 'nix'." >&2
    exit 1
fi

echo "Requiere que tu configuracion de NixOS ya use flakes (no confirmado que"
echo "nuestra instalacion base lo haga por defecto - revisa /etc/nixos/flake.nix)."
echo ""
echo "Corriendo primero en modo --dry-run (no cambia nada todavia)..."
nix run github:aethctl/Ryoku-on-NixOS/main#install -- --dry-run

echo ""
read -p "Revisa el resultado de arriba. Escribe SI en mayusculas para aplicar de verdad: " confirmar
[ "$confirmar" == "SI" ] || { echo "Cancelado, no se aplico nada."; exit 0; }

nix run github:aethctl/Ryoku-on-NixOS/main#install
