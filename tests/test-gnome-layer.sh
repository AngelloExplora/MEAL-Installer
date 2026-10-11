#!/bin/bash
# test-gnome-layer.sh - pruebas de la capa GNOME portada de Omakub.
# Niveles: (1) estatico, (2) dry-run, (3) INTEGRACION contra los esquemas GNOME instalados
# (backend keyfile en un directorio temporal: no toca tu configuracion real).
# Si no hay esquemas GNOME en esta maquina, el nivel 3 dice SKIP - nunca pasa en silencio.
set -u
cd "$(dirname "$0")/.." || exit 1
FALLAS=0
ok()   { echo "OK:    $*"; }
bad()  { echo "FALLO: $*"; FALLAS=$((FALLAS + 1)); }
skip() { echo "SKIP:  $*"; }

source scripts/lib/gnome.sh
D=scripts/desktop

echo "== 1) Estatico =="
for f in "$D/gnome-core.tsv" "$D/gnome-extensions-settings.tsv"; do
    if meal_gnome_validate_tsv "$f" 2>/dev/null; then ok "formato valido: $f"; else bad "formato invalido: $f"; fi
done
malo=$(mktemp); printf 'solo-dos\tcolumnas\n-\tesquema\tclave\tvalor\n-\tesquema\tclave\tvalor\n' > "$malo"
if meal_gnome_validate_tsv "$malo" 2>/dev/null; then bad "no detecto un TSV mal formado/duplicado"; else ok "detecta lineas mal formadas y duplicados"; fi
rm -f "$malo"
# cada UUID de ajustes debe estar en la lista de extensiones a instalar
faltan=$(cut -f1 "$D/gnome-extensions-settings.tsv" | grep -v '^#' | sort -u | while read -r u; do grep -q "^$u|" "$D/gnome-extensions.list" || echo "$u"; done)
[ -z "$faltan" ] && ok "todos los UUID con ajustes estan en gnome-extensions.list" || bad "UUID sin instalar: $faltan"

echo "== 2) Dry-run =="
salida=$(bash scripts/postinstall/gnome-layer.sh --dry-run 2>&1); rc=$?
[ "$rc" -eq 0 ] && ok "dry-run termina con codigo 0" || bad "dry-run fallo (codigo $rc)"
esperadas=$(( $(grep -vc '^#' "$D/gnome-core.tsv") + $(grep -vc '^#' "$D/gnome-extensions-settings.tsv") + 1 ))
reales=$(echo "$salida" | grep -c '^\[DRY-RUN\] .*gsettings set')
[ "$reales" -eq "$esperadas" ] && ok "dry-run lista $reales cambios (= datos + favoritos)" || bad "dry-run lista $reales, esperaba $esperadas"
echo "$salida" | grep -q 'ttf-cascadia-mono-nerd' && ok "dry-run incluye la fuente" || bad "falta la fuente en el dry-run"
bash scripts/postinstall/gnome-layer.sh --foo >/dev/null 2>&1; [ $? -eq 2 ] && ok "opcion invalida -> codigo 2" || bad "opcion invalida no devolvio 2"

echo "== 3) Integracion contra esquemas GNOME reales =="
if command -v gsettings >/dev/null && [ -f /usr/share/glib-2.0/schemas/org.gnome.desktop.wm.keybindings.gschema.xml ]; then
    TMPCFG=$(mktemp -d)
    export GSETTINGS_BACKEND=keyfile XDG_CONFIG_HOME="$TMPCFG"
    MEAL_GNOME_APPLIED=0; MEAL_GNOME_FAILED=0
    meal_gnome_apply_tsv "$D/gnome-core.tsv" apply
    n_core=$(grep -vc '^#' "$D/gnome-core.tsv")
    [ "$MEAL_GNOME_FAILED" -eq 0 ] && ok "los $MEAL_GNOME_APPLIED/$n_core ajustes del sistema se aplicaron sin error" \
                                    || bad "$MEAL_GNOME_FAILED ajustes fallaron contra los esquemas instalados"
    # leer de vuelta cada clave y comparar con el valor del archivo
    difs=0
    while IFS=$'\t' read -r ext schema key value || [ -n "$ext" ]; do
        case "$ext" in ''|'#'*) continue ;; esac
        leido=$(gsettings get "$schema" "$key" 2>/dev/null)
        norm=${leido#\'}; norm=${norm%\'}
        if [ "$norm" != "$value" ]; then echo "   difiere: $schema $key -> esperado [$value] leido [$leido]"; difs=$((difs + 1)); fi
    done < "$D/gnome-core.tsv"
    [ "$difs" -eq 0 ] && ok "cada clave leida de vuelta coincide con el archivo" || bad "$difs claves no coinciden al leerlas de vuelta"
    # mutacion: una clave que NO existe en el esquema debe contarse como fallo (el test puede fallar)
    mut=$(mktemp); printf -- '-\torg.gnome.desktop.wm.preferences\tclave-que-no-existe\t1\n' > "$mut"
    MEAL_GNOME_APPLIED=0; MEAL_GNOME_FAILED=0
    meal_gnome_apply_tsv "$mut" apply 2>/dev/null
    [ "$MEAL_GNOME_FAILED" -eq 1 ] && ok "una clave inexistente se detecta como fallo" || bad "una clave inexistente NO se detecto (fallos=$MEAL_GNOME_FAILED)"
    rm -f "$mut"
    # mecanismo de esquemas de extension (extension sintetica, sin tocar /usr/share)
    EXT=$(mktemp -d); mkdir -p "$EXT/prueba@meal/schemas"
    cat > "$EXT/prueba@meal/schemas/org.gnome.shell.extensions.meal-prueba.gschema.xml" << 'XML'
<?xml version="1.0" encoding="UTF-8"?>
<schemalist><schema id="org.gnome.shell.extensions.meal-prueba" path="/org/gnome/shell/extensions/meal-prueba/">
<key name="gap-size" type="i"><default>8</default><summary>gap</summary></key></schema></schemalist>
XML
    printf 'prueba@meal\torg.gnome.shell.extensions.meal-prueba\tgap-size\t32\nfantasma@meal\torg.x\tk\t1\n' > "$EXT/ajustes.tsv"
    MEAL_GNOME_EXT_DIR="$EXT"; MEAL_GNOME_APPLIED=0; MEAL_GNOME_FAILED=0
    meal_gnome_apply_tsv "$EXT/ajustes.tsv" apply 2>/dev/null
    v=$(GSETTINGS_SCHEMA_DIR="$EXT/prueba@meal/schemas" gsettings get org.gnome.shell.extensions.meal-prueba gap-size 2>/dev/null)
    [ "$v" = "32" ] && ok "esquema de extension compilado en su carpeta y aplicado (valor $v)" || bad "esquema de extension: valor leido [$v]"
    [ "$MEAL_GNOME_FAILED" -eq 1 ] && ok "una extension no instalada cuenta como fallo (no se ignora)" || bad "extension ausente no se conto como fallo (fallos=$MEAL_GNOME_FAILED)"
    if compgen -G "/usr/share/glib-2.0/schemas/*meal-prueba*" >/dev/null; then bad "se escribio en /usr/share"; else ok "/usr/share/glib-2.0/schemas intacto"; fi
    rm -rf "$TMPCFG" "$EXT"; unset GSETTINGS_BACKEND
else
    skip "no hay gsettings + esquemas GNOME en esta maquina: la integracion NO se ejecuto"
fi

echo "== 4) Favoritos =="
APPS=$(mktemp -d); touch "$APPS/firefox.desktop" "$APPS/code.desktop"
export MEAL_DESKTOP_DIRS="$APPS"
fav=$(meal_gnome_favorites_list "$D/gnome-favorites.list")
[ "$fav" = "['firefox.desktop','code.desktop']" ] && ok "solo incluye apps instaladas, en orden: $fav" || bad "favoritos: [$fav]"
rm -f "$APPS"/*.desktop
fav=$(meal_gnome_favorites_list "$D/gnome-favorites.list")
[ "$fav" = "@as []" ] && ok "sin apps instaladas -> '@as []' (Omakub generaba [''])" || bad "lista vacia: [$fav]"
rm -rf "$APPS"; unset MEAL_DESKTOP_DIRS

echo ""
[ "$FALLAS" -eq 0 ] && echo "RESULTADO: todo OK" || echo "RESULTADO: $FALLAS fallo(s)"
exit "$FALLAS"
