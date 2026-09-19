#!/bin/bash
# animation.sh - animaciones simples de texto (typewriter)

# Uso: meal_typewriter "Texto a mostrar" 0.03
meal_typewriter() {
    local texto="$1" delay="${2:-0.03}"
    for (( i=0; i<${#texto}; i++ )); do
        printf "%s" "${texto:$i:1}"
        sleep "$delay"
    done
    echo ""
}
