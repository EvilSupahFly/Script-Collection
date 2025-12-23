#!/bin/bash

###############
## Script Name:
## /home/seann/Games/The_Elder_Scrolls_IV_-_Oblivion_Remastered/drive_c/The_Elder_Scrolls_IV_-_Oblivion_Remastered.sh
###############

# Wrapper to run a game EXE with or without GameScope
do_gameScope() {
    local app="$1"
    shift
    if command -v gamescope &>/dev/null; then
        echo "Launching with GameScope (display: $PRIMARY_DISPLAY)..."
        exec gamescope -e --adaptive-sync -O "$PRIMARY_DISPLAY" --              "$WINE" "$app" "$@"
    else
        echo "GameScope not found. Launching game directly..."
        exec "$WINE" "$app" "$@"
    fi
}

# Change the current working directory to the one the scipt was run from
cd "$(dirname "$(readlink -f "$0")")" || exit; [ "$EUID" = "0" ] && echo -e "Please don't run as root!" && exit

# Make sure WINE is configured (although, I'm assuming it was done by the original installer script)
export WINE="$(command -v wine)"
export WINEPREFIX="/home/seann/Games/The_Elder_Scrolls_IV_-_Oblivion_Remastered"
export WINEDLLOVERRIDES="winemenubuilder.exe=d"
export WINE_LARGE_ADDRESS_AWARE=1
#export RESTORE_RESOLUTION=1
#export WINE_D3D_CONFIG="renderer=vulkan"
export GAMEDEST="${WINEPREFIX}/drive_c/Games/The Elder Scrolls IV - Oblivion Remastered"
export DXVK_ENABLE_NVAPI=1
export PRIMARY_DISPLAY=${PRIMARY_DISPLAY:-0}
export STAGING_RT_PRIORITY_SERVER=99
export STAGING_WRITECOPY=1
export STAGING_SHARED_MEMORY=1


# --- Auto-generated game menu ---
# You can edit the "echo" labels below to make them friendlier,
# or change the paths if you installed the game in a different folder.

echo "Select a game to launch:"
echo "1) OblivionRemastered.exe"
echo "2) ArtOfOblivion.exe"
read -rp "Enter number: " choice
case "$choice" in
  1) cd "$GAMEDEST" && do_gameScope "OblivionRemastered.exe" "$@" ;;
  2) cd "$GAMEDEST/Oblivion Remastered - Digital Artbook" && do_gameScope "ArtOfOblivion.exe" "$@" ;;
  *) echo "Invalid selection." ;;
esac
