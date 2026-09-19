#!/bin/bash
# tui.sh - punto de entrada del MEAL UI Engine
# Uso: source scripts/lib/tui.sh

MEAL_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$MEAL_LIB_DIR/colors.sh"
source "$MEAL_LIB_DIR/theme.sh"
source "$MEAL_LIB_DIR/utils.sh"
source "$MEAL_LIB_DIR/menu.sh"
source "$MEAL_LIB_DIR/checkbox.sh"
source "$MEAL_LIB_DIR/dialog.sh"
source "$MEAL_LIB_DIR/spinner.sh"
source "$MEAL_LIB_DIR/progress.sh"
source "$MEAL_LIB_DIR/renderer.sh"
source "$MEAL_LIB_DIR/animation.sh"

meal_require_gum || return 1 2>/dev/null || exit 1
