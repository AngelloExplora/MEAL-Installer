#!/bin/bash
# renderer.sh - encabezados y pantallas compuestas

# Uso: meal_header "Linea 1" "Linea 2" ...
meal_header() {
    gum style --border double --padding "1 4" --border-foreground "$MEAL_THEME_BORDER" --align center "$@"
}
