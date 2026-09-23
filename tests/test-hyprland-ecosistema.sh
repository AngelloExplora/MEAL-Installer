#!/bin/bash
# test-hyprland-ecosistema.sh - verifica el enrutamiento por escritorio (Fase 9)
# NO instala nada real (necesita internet + sistema Arch real = Fase 14).
set -e
cd "$(dirname "$0")/.."

for de in kde hyprland niri mango otro-invalido; do
    echo "=== $de ==="
    grep -A2 "^    $de)" scripts/postinstall/hyprland-ecosistema.sh | head -3 || echo "(no reconocido, como se espera)"
done
