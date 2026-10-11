#!/bin/bash
# test-verify-packages.sh - prueba la LOGICA de tests/wsl/verify-packages.sh con un pacman FALSO.
# OJO: esto NO comprueba que los paquetes existan en Arch; eso solo lo hace el script real en un Arch real.
set -u
cd "$(dirname "$0")/.." || exit 1
FALLAS=0
ok()  { echo "OK:    $*"; }
bad() { echo "FALLO: $*"; FALLAS=$((FALLAS + 1)); }

STUB=$(mktemp -d)
cat > "$STUB/pacman" << 'PAC'
#!/bin/bash
# pacman falso. STUB_MISSING: nombres que no existen. STUB_GROUPS: nombres que son grupos.
case "$1" in
  -Sl) exit 0 ;;
  -Si) for m in $STUB_MISSING $STUB_GROUPS; do [ "$m" = "$2" ] && exit 1; done
       printf 'Name            : %s\nRepository      : extra\n' "$2"; exit 0 ;;
  -Sg) for g in $STUB_GROUPS; do [ "$g" = "$2" ] && { echo "$g miembro1"; exit 0; }; done; exit 1 ;;
esac
exit 1
PAC
chmod +x "$STUB/pacman"

echo "== 1) Sin pacman: codigo 2 con mensaje claro =="
# PATH sin pacman (este sandbox no tiene)
if command -v pacman >/dev/null 2>&1; then echo "SKIP:  esta maquina ya tiene pacman, se omite este caso"
else
    PATH=/usr/bin:/bin bash tests/wsl/verify-packages.sh >/dev/null 2>&1; rc=$?
    [ "$rc" -eq 2 ] && ok "sin pacman -> codigo 2" || bad "sin pacman devolvio $rc"
fi

echo "== 2) Faltantes y grupos detectados (calamares y steam 'no existen'; xfce4 es grupo) =="
salida=$(PATH="$STUB:$PATH" STUB_MISSING="calamares steam" STUB_GROUPS="xfce4 base-devel" bash tests/wsl/verify-packages.sh 2>&1); rc=$?
[ "$rc" -eq 1 ] && ok "hay faltantes -> codigo 1" || bad "esperaba codigo 1, obtuvo $rc"
echo "$salida" | grep -q '^FALTA  calamares' && ok "marca calamares como FALTA" || bad "no marco calamares"
echo "$salida" | grep -q '^FALTA  steam' && ok "marca steam como FALTA" || bad "no marco steam"
echo "$salida" | grep -q 'archiso/packages.x86_64' && ok "indica en que archivo se usa (archiso/packages.x86_64)" || bad "no indica el archivo"
echo "$salida" | grep -q '^FALTA  xfce4' && bad "trato un grupo como FALTA" || ok "un grupo (xfce4) no se marca como FALTA"
echo "$salida" | grep -q '^FALTA  base-devel' && bad "trato base-devel como FALTA" || ok "base-devel (grupo) tampoco se marca como FALTA"
n_faltan=$(echo "$salida" | grep -c '^FALTA ')
[ "$n_faltan" -eq 2 ] && ok "exactamente 2 faltantes" || bad "esperaba 2 faltantes, hay $n_faltan"

echo "== 3) Todo existe -> codigo 0 =="
PATH="$STUB:$PATH" STUB_MISSING="" STUB_GROUPS="" bash tests/wsl/verify-packages.sh >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && ok "sin faltantes -> codigo 0" || bad "esperaba 0, obtuvo $rc"

echo "== 4) Extrae paquetes de lineas 'pacman -S' pero no de '-Syu' =="
salida=$(PATH="$STUB:$PATH" STUB_MISSING="python-pipx" STUB_GROUPS="" bash tests/wsl/verify-packages.sh 2>&1)
echo "$salida" | grep -q '^FALTA  python-pipx.*gnome-layer.sh' && ok "encontro python-pipx en scripts/postinstall/gnome-layer.sh" || bad "no leyo el 'pacman -S' de gnome-layer.sh"
echo "$salida" | grep -qE '^FALTA  yu( |$)' && bad "confundio 'pacman -Syu' con un paquete 'yu'" || ok "no confunde 'pacman -Syu' con un paquete"

rm -rf "$STUB"
echo ""
[ "$FALLAS" -eq 0 ] && echo "RESULTADO: todo OK" || echo "RESULTADO: $FALLAS fallo(s)"
exit "$FALLAS"
