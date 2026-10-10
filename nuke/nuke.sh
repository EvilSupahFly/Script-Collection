#!/usr/bin/env bash

# Define some fancy colourful text with BASH's built-in escape codes. Example:
# echo -e "${BOLD}${YELLOW}This text will be displayed in BOLD YELLOW. ${RESET}While this text is normal."
# Complete colour table available at https://gist.github.com/JBlond/2fea43a3049b38287e5e9cefc87b2124

BOLD="\033[1m" #Bold or Hi-Intensty - depends on your terminal app
ULINE="\033[4m" #Underline
RESET="\033[0m" # Normal
RED="\033[1;91m" # Red
GREEN="\033[1;92m" # Green
YELLOW="\033[1;33m" # Yellow
WHITE="\033[1;97m" # White
PURPLE="\033[35m" # Magenta (Purple)

# Function: nuke
# Purpose: Given a directory and a name pattern, finds matching files/folders
#          and deletes them with rm -Rfdv. --dryrun previews without deleting.
#
# Usage:
#   nuke <search_dir> <pattern> [--dryrun]
#
# Examples:
#   nuke "/data/evilsupahfly" ".trashed-*" --dryrun
#   nuke "/data/evilsupahfly" ".trashed-*"
#
# Note: no -type restriction on find, so this matches files AND folders,
# same as the -iname "*trash*" search that inspired it.
nuke() {
    local search_dir="$1"
    local pattern="$2"
    local dryrun=0

    if [[ "$3" == "--dryrun" ]]; then
        dryrun=1
    fi

    if [[ -z "$search_dir" || -z "$pattern" ]]; then
        echo -e "\n${RED}Usage: nuke <search_dir> <pattern> [--dryrun]${WHITE}\n"
        return 1
    fi

    if [[ ! -d "$search_dir" ]]; then
        echo -e "\n${RED}\"$search_dir\" is not a valid directory.${WHITE}\n"
        return 1
    fi

    # NUL-delimited read via `read -d ''` instead of `mapfile -d ''` --
    # mapfile's custom delimiter is bash 4.4+ only, and older platforms
    # (NAS firmware, older distros) are often still on 4.3 or earlier.
    # `read -d ''` has worked the same way since early bash 3.x.
    local -a targets=()
    local item
    while IFS= read -r -d '' item; do
        targets+=("$item")
    done < <(find "$search_dir" -iname "$pattern" -print0)

    if [ "${#targets[@]}" -eq 0 ]; then
        echo -e "\n${RED}Nothing matching ${YELLOW}\"$pattern\"${RED} found in ${YELLOW}\"$search_dir\"${WHITE}\n"
        return 1
    fi

    echo -e "\n${YELLOW}Found ${#targets[@]} item(s) matching ${WHITE}\"$pattern\"${YELLOW} in ${WHITE}\"$search_dir\":\n"
    for ((i=0; i<"${#targets[@]}"; i++)); do
        if ((i % 2 == 0)); then
            echo -e "${ULINE}${WHITE}$i: ${targets[$i]}${RESET}${WHITE}"
        else
            echo -e "${ULINE}${GREEN}$i: ${targets[$i]}${RESET}${WHITE}"
        fi
    done
    echo

    if ((dryrun)); then
        # One path per line (like the preview list above), not one unbroken
        # line. The 150-match wall of text I got when I tested on my NAS was
        # unreadable and defeated the point of a dry run, which is to actually
        # be able to check it. Trailing backslashes keep it a single valid
        # command if copy-pasted.
        echo -e "${YELLOW}--dryrun set: nothing deleted. Command that would run:${WHITE}"
        echo "rm -Rfdv -- \\"
        local last_idx=$(( ${#targets[@]} - 1 ))
        for ((i=0; i<${#targets[@]}; i++)); do
            if ((i == last_idx)); then
                printf '  %q\n' "${targets[$i]}"
            else
                printf '  %q \\\n' "${targets[$i]}"
            fi
        done
        echo
        return 0
    fi

    # rm -Rfdv is permanent, so a plain y/n is too easy to blow through on
    # autopilot -- require the literal word as a deliberate second action.
    # Since we don't know how big the list will be, we don't want manual
    # confirmation on every file and directory, and we prefer recursion
    # so we only have to run once, and that's a safety risk when run blind.
    # The solution is to run rm with -v for verbosity for visibility.
    local confirm
    read -r -p "Type NUKE to permanently delete these ${#targets[@]} item(s): " confirm
    if [[ "$confirm" != "NUKE" ]]; then
        echo -e "\n${YELLOW}Aborted. Nothing was deleted.${WHITE}\n"
        return 1
    fi

    rm -Rfdv -- "${targets[@]}"
}
