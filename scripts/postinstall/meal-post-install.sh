#!/bin/bash
# meal-post-install.sh - FASE 12: extras opcionales, corre como usuario normal
# ya en el escritorio (necesita gum + terminal grafica - ver Fase 2).

set -Eeuo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_DIR/scripts/lib/tui.sh"
source "$REPO_DIR/scripts/lib/packages.sh"
source "$REPO_DIR/scripts/lib/profiles.sh"

detectar_aur_helper() {
    if command -v yay &>/dev/null; then echo "yay"
    elif command -v paru &>/dev/null; then echo "paru"
    else echo ""
    fi
}

solo_opcionales_de_categoria() {
    grep '|OPCIONAL$' "$REPO_DIR/scripts/packages/$1.list" 2>/dev/null | cut -d'|' -f1
}

instalar_opcionales_perfil() {
    local perfil
    perfil=$(meal_menu "Elige tu perfil" $(meal_profile_list))
    [ -z "$perfil" ] && return

    meal_profile_load "$perfil"
    if [ "$MEAL_PROFILE_CATEGORIAS_OPCIONALES" == "INTERACTIVO" ] || [ -z "$MEAL_PROFILE_CATEGORIAS_OPCIONALES" ]; then
        meal_error_dialog "Este perfil no tiene categorias opcionales fijas."
        return
    fi

    local disponibles=""
    for cat in $MEAL_PROFILE_CATEGORIAS_OPCIONALES; do
        disponibles="$disponibles $(solo_opcionales_de_categoria "$cat")"
    done
    disponibles=$(echo "$disponibles" | tr ' ' '\n' | sort -u | grep -v '^$')

    [ -z "$disponibles" ] && { meal_error_dialog "No hay opcionales para $MEAL_PROFILE_NOMBRE."; return; }

    local elegidos
    elegidos=$(meal_checkbox "Opcionales de $MEAL_PROFILE_NOMBRE" $disponibles)
    [ -z "$elegidos" ] && return
    meal_confirm "Instalar: $elegidos ?" && sudo pacman -S --needed $elegidos
}

instalar_vscode() {
    local helper; helper=$(detectar_aur_helper)
    [ -z "$helper" ] && { meal_error_dialog "Falta yay o paru para VS Code (AUR)."; return; }
    meal_confirm "Instalar Visual Studio Code (AUR)?" && "$helper" -S --needed visual-studio-code-bin
}

instalar_limine_hook() {
    local helper; helper=$(detectar_aur_helper)
    [ -z "$helper" ] && { meal_error_dialog "Falta yay o paru para limine-mkinitcpio-hook (AUR)."; return; }
    meal_confirm "Instalar limine-mkinitcpio-hook (actualiza limine.conf en cada kernel nuevo)?" && \
        "$helper" -S --needed limine-mkinitcpio-hook
}

instalar_ryoku() {
    meal_confirm "Instalar Ryoku Linux encima de este MEAL? (reversible con --uninstall)" && \
        bash "$REPO_DIR/scripts/postinstall/ryoku-install.sh"
}

instalar_zaneyos() {
    if [ ! -f /etc/NIXOS ]; then
        meal_error_dialog "ZaneyOS es solo para la rama NixOS de MEAL."
        return
    fi
    bash "$REPO_DIR/scripts/postinstall/zaneyos-install.sh"
}

meal_post_install_loop() {
    while true; do
        local opciones=("Opcionales de mi perfil" "Visual Studio Code (AUR)" "limine-mkinitcpio-hook (AUR)" "Ryoku Linux (sobre Hyprland/Niri/Mango)")
        [ -f /etc/NIXOS ] && opciones+=("ZaneyOS (Hyprland para NixOS)")
        opciones+=("Salir")

        OPCION=$(meal_menu "MEAL - Post-instalacion" "${opciones[@]}")

        case "$OPCION" in
            "Opcionales de mi perfil") instalar_opcionales_perfil ;;
            "Visual Studio Code (AUR)") instalar_vscode ;;
            "limine-mkinitcpio-hook (AUR)") instalar_limine_hook ;;
            "Ryoku Linux"*) instalar_ryoku ;;
            "ZaneyOS"*) instalar_zaneyos ;;
            *) break ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    meal_post_install_loop
fi
