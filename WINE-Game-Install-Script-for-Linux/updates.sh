#!/bin/bash

WINE="$(command -v wine)" # Set $WINE
WINEPREFIX="/home/$(whoami)/Game_Storage/" # Define Wineprefix

export WINE
export WINEPREFIX

shopt -s nocaseglob # Enable case-insensitive globbing

cd Updates

for i in *.exe; do
    echo -e "\nFound \"$i\". What would you like to do?"
    echo "1) Install this file"
    echo "2) Skip to the next file"
    echo "3) Exit the script"
    read -p "Please enter your choice (1/2/3): " choice

    case $choice in
        1)
            echo "Installing \"$i\" into \"$WINEPREFIX\"..."
            "$WINE" "$i" >/dev/null 2>&1
            ;;
        2)
            echo "Skipping \"$i\"..."
            continue
            ;;
        3)
            echo "Exiting the script."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter 1, 2, or 3."
            ;;
    esac
done

