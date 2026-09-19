#!/bin/bash
# progress.sh - barra de progreso con porcentaje, texto plano (sin emojis)

# Uso: meal_progress_bar 45 "Instalando paquetes"
meal_progress_bar() {
    local pct=$1 label=$2 ancho=30
    local llenas=$(( pct * ancho / 100 ))
    local vacias=$(( ancho - llenas ))
    printf "\r%s [" "$label"
    printf "%0.s#" $(seq 1 $llenas 2>/dev/null) 2>/dev/null
    printf "%0.s-" $(seq 1 $vacias 2>/dev/null) 2>/dev/null
    printf "] %d%%" "$pct"
    [ "$pct" -ge 100 ] && echo ""
}
