#!/bin/bash
# test-migrations.sh - pruebas del runner de migraciones (puro Bash, directorios temporales).
set -u
cd "$(dirname "$0")/.." || exit 1
FALLAS=0
ok()  { echo "OK:    $*"; }
bad() { echo "FALLO: $*"; FALLAS=$((FALLAS + 1)); }

source scripts/lib/migrations.sh

nuevo_entorno() {   # crea migraciones y estado temporales; exporta MEAL_MIGRATIONS_DIR y MEAL_STATE_DIR
    T=$(mktemp -d)
    export MEAL_MIGRATIONS_DIR="$T/mig" MEAL_STATE_DIR="$T/state" TRAZA="$T/traza"
    mkdir -p "$MEAL_MIGRATIONS_DIR"; : > "$TRAZA"
}
migracion() {       # migracion <nombre> <comando>
    printf '#!/bin/bash\n%s\n' "$2" > "$MEAL_MIGRATIONS_DIR/$1"
}

echo "== 1) Orden numerico (9 antes que 10) y nombres invalidos ignorados =="
nuevo_entorno
migracion 10-b.sh 'echo b >> "$TRAZA"'; migracion 9-a.sh 'echo a >> "$TRAZA"'
touch "$MEAL_MIGRATIONS_DIR/README.md" "$MEAL_MIGRATIONS_DIR/1-mal;nombre.sh"
orden=$(meal_migrations_list | tr '\n' ' ')
[ "$orden" = "9-a.sh 10-b.sh " ] && ok "orden numerico y solo nombres validos: $orden" || bad "orden/lista: [$orden]"

echo "== 2) Sin manifiesto: fail-closed, no ejecuta nada =="
meal_migrations_run 2>/dev/null; rc=$?
[ "$rc" -eq 1 ] && [ ! -s "$TRAZA" ] && ok "sin SHA256SUMS se niega y no ejecuta" || bad "sin manifiesto: rc=$rc traza=$(cat "$TRAZA")"

echo "== 3) Con manifiesto: ejecuta en orden, registra estado, es idempotente =="
meal_migrations_manifest_update
meal_migrations_run >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && [ "$(tr '\n' ' ' < "$TRAZA")" = "a b " ] && ok "ejecuto a luego b" || bad "ejecucion: rc=$rc traza=$(tr '\n' ' ' < "$TRAZA")"
[ "$(wc -l < "$MEAL_STATE_DIR/applied-migrations")" -eq 2 ] && ok "estado registra 2 migraciones" || bad "estado incorrecto"
: > "$TRAZA"; meal_migrations_run >/dev/null 2>&1
[ ! -s "$TRAZA" ] && ok "segunda corrida no repite nada" || bad "repitio migraciones"

echo "== 4) Archivo alterado despues del manifiesto: no se ejecuta NI LA VALIDA anterior =="
nuevo_entorno
migracion 1-ok.sh 'echo ok >> "$TRAZA"'; migracion 2-evil.sh 'echo evil >> "$TRAZA"'
meal_migrations_manifest_update
echo 'echo hackeado >> "$TRAZA"' >> "$MEAL_MIGRATIONS_DIR/2-evil.sh"
meal_migrations_run 2>/dev/null; rc=$?
[ "$rc" -eq 1 ] && [ ! -s "$TRAZA" ] && ok "hash distinto: se detiene antes de ejecutar cualquiera" || bad "alterado: rc=$rc traza=$(cat "$TRAZA")"

echo "== 5) Migracion nueva que no esta en el manifiesto =="
nuevo_entorno
migracion 1-a.sh 'echo a >> "$TRAZA"'; meal_migrations_manifest_update
migracion 2-nueva.sh 'echo nueva >> "$TRAZA"'
meal_migrations_run 2>/dev/null; rc=$?
[ "$rc" -eq 1 ] && [ ! -s "$TRAZA" ] && ok "sin entrada en el manifiesto: no se ejecuta" || bad "no listada: rc=$rc"

echo "== 6) Fallo a mitad: se detiene, la que fallo no queda como aplicada =="
nuevo_entorno
migracion 1-a.sh 'echo a >> "$TRAZA"'; migracion 2-falla.sh 'exit 7'; migracion 3-c.sh 'echo c >> "$TRAZA"'
meal_migrations_manifest_update
meal_migrations_run >/dev/null 2>&1; rc=$?
estado=$(cat "$MEAL_STATE_DIR/applied-migrations" 2>/dev/null | tr '\n' ' ')
[ "$rc" -eq 1 ] && [ "$estado" = "1-a.sh " ] && [ "$(cat "$TRAZA")" = "a" ] && ok "se detuvo en 2-falla.sh; 3-c.sh no corrio; estado: $estado" || bad "fallo a mitad: rc=$rc estado=[$estado] traza=[$(cat "$TRAZA")]"
pend=$(meal_migrations_pending | tr '\n' ' ')
[ "$pend" = "2-falla.sh 3-c.sh " ] && ok "siguen pendientes: $pend" || bad "pendientes: [$pend]"

echo "== 7) --dry-run no ejecuta ni escribe estado =="
nuevo_entorno
migracion 1-a.sh 'echo a >> "$TRAZA"'; meal_migrations_manifest_update
salida=$(meal_migrations_run --dry-run 2>&1)
[ ! -s "$TRAZA" ] && [ ! -e "$MEAL_STATE_DIR/applied-migrations" ] && echo "$salida" | grep -q 'DRY-RUN' && ok "dry-run no ejecuto ni guardo estado" || bad "dry-run con efectos"

echo ""
[ "$FALLAS" -eq 0 ] && echo "RESULTADO: todo OK" || echo "RESULTADO: $FALLAS fallo(s)"
exit "$FALLAS"
