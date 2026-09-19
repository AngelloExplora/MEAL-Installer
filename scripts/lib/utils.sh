#!/bin/bash
# utils.sh - utilidades compartidas del MEAL UI Engine

meal_require_gum() {
    if ! command -v gum &>/dev/null; then
        echo "ERROR: falta 'gum'. Instala con: pacman -S gum" >&2
        return 1
    fi
}

meal_log_info()  { echo "[INFO] $*"; }
meal_log_warn()  { echo "[AVISO] $*"; }
meal_log_error() { echo "[ERROR] $*" >&2; }
