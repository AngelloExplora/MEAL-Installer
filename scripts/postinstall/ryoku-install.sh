#!/bin/bash
# ryoku-install.sh - Instala Ryoku Linux encima de un MEAL ya instalado
# (Fase 12 - post-instalacion, opcional, no forzado durante Calamares)
#
# IMPORTANTE: correr como usuario normal, YA logueado en el escritorio -
# NO dentro del chroot de Calamares. El propio instalador de Ryoku pide
# sudo el mismo cuando lo necesita, y esta pensado para una sesion
# interactiva real, no para un postinstall silencioso.
#
# Fuente real confirmada (docs.ryoku.dev/docs/convert):
#   - Corre como usuario normal, nunca como root
#   - Hace backup de toda config que toca + genera restore.sh (reversible)
#   - No desinstala otros escritorios; niri y sway quedan como sesiones de respaldo
#   - Tiene --dry-run y --uninstall

set -Eeuo pipefail

if [ "$EUID" -eq 0 ]; then
    echo "ERROR: no corras esto como root. Ryoku pide sudo el solo cuando lo necesita." >&2
    exit 1
fi

echo "MEAL: instalando Ryoku Linux (respaldo automatico, reversible con --uninstall)..."
echo "Recomendado probar primero con --dry-run"
echo ""

curl -fsSL https://raw.githubusercontent.com/ryoku-dev/ryoku-arch/main/ryoku-shell-installer/install.sh | bash "$@"
