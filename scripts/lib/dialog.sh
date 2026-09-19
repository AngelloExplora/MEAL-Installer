#!/bin/bash
# dialog.sh - confirmaciones y entradas de texto

meal_confirm() {
    gum confirm "$1"
}

meal_input() {
    gum input --placeholder="$1"
}

meal_error_dialog() {
    gum style --border normal --border-foreground "$MEAL_THEME_ERROR" --padding "0 2" "ERROR: $1"
}
