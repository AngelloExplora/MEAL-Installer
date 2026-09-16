#!/bin/bash
# ==========================================================
# MEAL - Renombrar usuario existente a "USER"
# ==========================================================
# Corre esto como ROOT (por SSH o TTY), con el usuario
# objetivo completamente desconectado (sesión cerrada, no
# solo bloqueada).
#
# La contraseña NO cambia, solo el nombre y la carpeta home.
# ==========================================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "❌ Corre esto como root (por SSH o desde una TTY con login root)."
    exit 1
fi

NEWNAME="USER"

read -p "Nombre de usuario ACTUAL que quieres renombrar a $NEWNAME: " OLDNAME

if ! id "$OLDNAME" &>/dev/null; then
    echo "❌ No existe un usuario llamado '$OLDNAME'."
    exit 1
fi

if pgrep -u "$OLDNAME" > /dev/null 2>&1; then
    echo "❌ '$OLDNAME' todavía tiene procesos activos."
    echo "   Cierra su sesión por completo (logout, no solo bloquear) e inténtalo de nuevo."
    exit 1
fi

echo "==> Renombrando $OLDNAME → $NEWNAME..."
usermod -l "$NEWNAME" "$OLDNAME"
usermod -d "/home/$NEWNAME" -m "$NEWNAME"
groupmod -n "$NEWNAME" "$OLDNAME" 2>/dev/null || true

echo ""
echo "✅ Listo. $OLDNAME ahora se llama $NEWNAME, misma contraseña, home movido a /home/$NEWNAME"
echo ""
echo "⚠️  Revisa manualmente si tenías autologin configurado con el nombre viejo en:"
echo "    /etc/sddm.conf  o  /etc/sddm.conf.d/*.conf"
echo "   (busca una línea 'User=$OLDNAME' y cámbiala a 'User=$NEWNAME')"
