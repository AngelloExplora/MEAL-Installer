#!/bin/bash
# spinner.sh - espera indeterminada (envuelve gum spin)

# Uso: meal_spin "Instalando..." -- comando arg1 arg2
meal_spin() {
    local titulo="$1"; shift
    gum spin --title="$titulo" -- "$@"
}
