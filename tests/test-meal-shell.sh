#!/bin/bash
# test-meal-shell.sh - verificacion basica del QML de MEAL Shell (Fase 9)
# NO ejecuta Quickshell real (necesita compositor Wayland = Fase 14).
# Solo revisa llaves balanceadas e imports esperados.
set -e
cd "$(dirname "$0")/.."
ARCHIVO="meal-shell/shell.qml"

ABIERTAS=$(grep -o '{' "$ARCHIVO" | wc -l)
CERRADAS=$(grep -o '}' "$ARCHIVO" | wc -l)

echo "Llaves abiertas: $ABIERTAS, cerradas: $CERRADAS"
[ "$ABIERTAS" -eq "$CERRADAS" ] && echo "OK: balanceadas" || { echo "FALLO: desbalanceadas"; exit 1; }

for imp in "import Quickshell" "import QtQuick" "ShellRoot" "PanelWindow"; do
    grep -q "$imp" "$ARCHIVO" && echo "OK: contiene '$imp'" || { echo "FALLO: falta '$imp'"; exit 1; }
done
