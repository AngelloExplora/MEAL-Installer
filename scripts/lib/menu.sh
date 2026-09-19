#!/bin/bash
# menu.sh - menu de seleccion unica (envuelve gum choose)

# Uso: meal_menu "Titulo" "Opcion 1" "Opcion 2" ...
meal_menu() {
    local header="$1"; shift
    gum choose --header="$header" --cursor.foreground="$MEAL_THEME_TITLE" "$@"
}
