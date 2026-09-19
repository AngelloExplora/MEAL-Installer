#!/bin/bash
# checkbox.sh - seleccion multiple (envuelve gum choose --no-limit)

# Uso: meal_checkbox "Titulo" "Opcion 1" "Opcion 2" ...
meal_checkbox() {
    local header="$1"; shift
    gum choose --no-limit --header="$header" "$@"
}
