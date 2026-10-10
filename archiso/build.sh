#!/bin/bash
# build.sh - construye la ISO de MEAL. Requiere archiso instalado, correr con sudo.
set -Eeuo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: corre esto con sudo (mkarchiso lo requiere)." >&2
    exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PERFIL_DIR="$REPO_DIR/archiso"
DESTINO_OPT="$PERFIL_DIR/airootfs/opt/meal"

echo "MEAL: copiando el repo dentro del overlay de la ISO..."
mkdir -p "$DESTINO_OPT"
rsync -a --delete --exclude archiso --exclude .git "$REPO_DIR/" "$DESTINO_OPT/"

echo "MEAL: corriendo mkarchiso..."
mkdir -p "$REPO_DIR/out"
mkarchiso -v -w /tmp/meal-archiso-work -o "$REPO_DIR/out" "$PERFIL_DIR"
echo "MEAL: ISO lista en $REPO_DIR/out/"
