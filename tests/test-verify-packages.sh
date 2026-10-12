#!/bin/bash
# test-verify-packages.sh - prueba la LOGICA de tests/wsl/verify-packages.sh con pacman falso y con
# bases de datos de Arch falsas. OJO: NO comprueba que los paquetes existan en Arch; eso solo lo hace
# el script real contra Arch real (tests/wsl/verify-packages.sh).
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

echo "== A) Metodo pacman (pacman falso) =="
if command -v pacman >/dev/null 2>&1; then echo "SKIP:  esta maquina tiene pacman real; se omite el caso 'sin pacman'"
else
    MEAL_VERIFY_BACKEND=pacman bash tests/wsl/verify-packages.sh >/dev/null 2>&1; rc=$?
    [ "$rc" -eq 2 ] && ok "forzando pacman sin tenerlo -> codigo 2" || bad "sin pacman devolvio $rc"
fi
salida=$(PATH="$STUB:$PATH" MEAL_VERIFY_BACKEND=pacman STUB_MISSING="calamares steam" STUB_GROUPS="xfce4 base-devel" bash tests/wsl/verify-packages.sh 2>&1); rc=$?
[ "$rc" -eq 1 ] && ok "hay faltantes -> codigo 1" || bad "esperaba codigo 1, obtuvo $rc"
echo "$salida" | grep -q '^FALTA  calamares' && ok "marca calamares como FALTA" || bad "no marco calamares"
echo "$salida" | grep -q '^FALTA  steam' && ok "marca steam como FALTA" || bad "no marco steam"
echo "$salida" | grep -q 'archiso/packages.x86_64' && ok "indica el archivo donde se usa" || bad "no indica el archivo"
echo "$salida" | grep -qE '^FALTA  (xfce4|base-devel) ' && bad "trato un grupo como FALTA" || ok "los grupos (xfce4, base-devel) no son FALTA"
[ "$(echo "$salida" | grep -c '^FALTA ')" -eq 2 ] && ok "exactamente 2 faltantes" || bad "numero de faltantes inesperado"
PATH="$STUB:$PATH" MEAL_VERIFY_BACKEND=pacman STUB_MISSING="" STUB_GROUPS="" bash tests/wsl/verify-packages.sh >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && ok "sin faltantes -> codigo 0" || bad "esperaba 0, obtuvo $rc"
salida=$(PATH="$STUB:$PATH" MEAL_VERIFY_BACKEND=pacman STUB_MISSING="python-pipx" STUB_GROUPS="" bash tests/wsl/verify-packages.sh 2>&1)
echo "$salida" | grep -q '^FALTA  python-pipx.*gnome-layer.sh' && ok "lee el 'pacman -S' de scripts/postinstall/gnome-layer.sh" || bad "no leyo gnome-layer.sh"
echo "$salida" | grep -qE '^FALTA  yu( |$)' && bad "confundio 'pacman -Syu' con un paquete" || ok "no confunde 'pacman -Syu' con un paquete"
rm -rf "$STUB"

echo "== B) Metodo db (bases de datos de Arch FALSAS, sin red) =="
NAMES=$(mktemp); bash tests/wsl/verify-packages.sh --list > "$NAMES"
fixture() {   # fixture DIR roto|completo
python3 - "$1" "$2" "$NAMES" << 'PY'
import io, os, sys, tarfile
d, variante, nombres_f = sys.argv[1:4]
nombres = [l.strip() for l in open(nombres_f) if l.strip()]
especiales = {"xfce4", "xfce4-goodies", "base-devel", "nodejs", "calamares", "steam", "wine"}
def desc(n, grupos=(), provides=()):
    s = f"%FILENAME%\n{n}-1.0-1-x86_64.pkg.tar.zst\n\n%NAME%\n{n}\n\n%VERSION%\n1.0-1\n\n"
    if grupos: s += "%GROUPS%\n" + "\n".join(grupos) + "\n\n"
    if provides: s += "%PROVIDES%\n" + "\n".join(provides) + "\n\n"
    return s
def escribir(ruta, pkgs):
    with tarfile.open(ruta, "w:gz") as tf:
        for n, g, p in pkgs:
            data = desc(n, g, p).encode()
            ti = tarfile.TarInfo(f"{n}-1.0-1/desc"); ti.size = len(data)
            tf.addfile(ti, io.BytesIO(data))
core = [(n, (), ()) for n in nombres[:3] if n not in especiales]
extra = [(n, (), ()) for n in nombres[3:] if n not in especiales]
extra += [("xfce4-session", ("xfce4",), ()), ("xfce4-notifyd", ("xfce4-goodies",), ()),
          ("make", ("base-devel",), ()), ("nodejs-lts-jod", (), ("nodejs=22.0",))]
multilib = []
if variante == "roto":
    multilib = [("steam", (), ()), ("wine", (), ())]
else:
    extra += [("calamares", (), ()), ("steam", (), ()), ("wine", (), ())]
escribir(os.path.join(d, "core.db"), core)
escribir(os.path.join(d, "extra.db"), extra)
escribir(os.path.join(d, "multilib.db"), multilib)
PY
}
D1=$(mktemp -d); fixture "$D1" roto
salida=$(MEAL_VERIFY_BACKEND=db MEAL_ARCH_NO_DOWNLOAD=1 MEAL_ARCH_DB_DIR="$D1" bash tests/wsl/verify-packages.sh 2>&1); rc=$?
[ "$rc" -eq 1 ] && ok "db 'roto': codigo 1" || bad "db roto devolvio $rc"
[ "$(echo "$salida" | grep -c '^FALTA ')" -eq 1 ] && echo "$salida" | grep -q '^FALTA  calamares' && ok "solo calamares es FALTA" || bad "faltantes inesperados: $(echo "$salida" | grep '^FALTA')"
echo "$salida" | grep -q '^MULTILIB steam' && echo "$salida" | grep -q '^MULTILIB wine' && ok "steam y wine se marcan MULTILIB (existen pero requieren [multilib])" || bad "no marco MULTILIB"
echo "$salida" | grep -qE '^(FALTA|MULTILIB) +(xfce4|xfce4-goodies|base-devel|nodejs) ' && bad "un grupo/provide se marco como problema" || ok "grupos (xfce4, xfce4-goodies, base-devel) y provides (nodejs) se resuelven bien"
D2=$(mktemp -d); fixture "$D2" completo
MEAL_VERIFY_BACKEND=db MEAL_ARCH_NO_DOWNLOAD=1 MEAL_ARCH_DB_DIR="$D2" bash tests/wsl/verify-packages.sh >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && ok "db 'completo': codigo 0" || bad "db completo devolvio $rc"
# error si falta un .db esencial
D3=$(mktemp -d)
MEAL_VERIFY_BACKEND=db MEAL_ARCH_NO_DOWNLOAD=1 MEAL_ARCH_DB_DIR="$D3" bash tests/wsl/verify-packages.sh >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok "sin core.db/extra.db -> codigo 2" || bad "sin bases devolvio $rc"
echo "NOTA: la descarga real desde el mirror de Arch NO se probo aqui (este sandbox no llega a ese dominio)."
rm -rf "$D1" "$D2" "$D3" "$NAMES"

echo ""
[ "$FALLAS" -eq 0 ] && echo "RESULTADO: todo OK" || echo "RESULTADO: $FALLAS fallo(s)"
exit "$FALLAS"
