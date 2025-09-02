#!/bin/bash

# Want automatic integreation? Copy the entire `pyvenv()` function into either /etc/bash.bashrc or $HOME/.bashrc and restart your terminal!

pyvenv() {
    # Function 'pyvenv' starts and enters a Python VENV, creating it if it doesn't exist. Also has a list feature, showing existing VENVs, and a Python version check:
    #    Normal Usage: pyvenv venv version
    #    List VENVs: pyvenv --list
    #    Version Check: pyvenv --check-ver
    
    # Define some fancy colourful text with BASH's built-in escape codes. Example:
    # echo -e "${YELLOW}This text will be displayed in BOLD YELLOW. ${RESET}While this text is normal."
    ULINE=$'\e[4m'
    YELLOW=$'\e[1;33m'
    RED=$'\e[1;91m'
    GREEN=$'\e[1;92m'
    WHITE=$'\e[1;97m'
    RESET=$'\e[0m'

    local CHECK=0
    local LIST=0

    # Force use of system libmpdec to ensure _decimal builds cleanly (Python ≥3.13)
    export PYTHONZ_CONFIGURE_OPTS="--with-system-libmpdec"

    # Parse flags
    while [[ "$1" =~ ^-- ]]; do
        case "$1" in
            --check-ver)
                CHECK=1
                shift
                ;;
            --list)
                LIST=1
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
                echo -e "${RED}Unknown option: $1${RESET}"
                return 1
                ;;
        esac
    done

    # Handle --list
    if [ "$LIST" -eq 1 ]; then
        if [ "$#" -gt 0 ]; then
            echo -e "${YELLOW}Warning: --list does not take additional arguments. Ignoring: $*${RESET}"
        fi
        if [ -d "$HOME/python-virtual-environs/" ]; then
            echo -e "${WHITE}Existing virtual environments:${RESET}"
            ls -1A "$HOME/python-virtual-environs/"
        else
            echo -e "${YELLOW}No virtual environments found.${RESET}"
        fi
        return 0
    fi

    # Handle --check-ver
    if [ "$CHECK" -eq 1 ]; then
        if [ "$#" -gt 0 ]; then
            echo -e "${YELLOW}Warning: --check-ver does not take additional arguments. Ignoring: $*${RESET}"
        fi
        echo -e "${WHITE}Fetching latest Python releases...${RESET}"
        mapfile -t VERSIONS < <(
            curl -s https://www.python.org/ftp/python/ |
            grep -oP '(?<=href=")[0-9]+\.[0-9]+\.[0-9]+(?=/")' |
            grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' |
            sort -Vr | uniq | while read -r ver; do
                url="https://www.python.org/ftp/python/$ver/Python-$ver.tgz"
                if curl -sfI "$url" > /dev/null; then
                    echo "$ver"
                fi
            done | head -n 10
        )

        if [ "${#VERSIONS[@]}" -eq 0 ]; then
            echo -e "${RED}Unable to retrieve version list. You can specify a version manually.${RESET}"
            return 1
        fi
        echo -e "${WHITE}Available versions:${RESET}"
        select VER in "${VERSIONS[@]}" "Cancel"; do
            if [ "$VER" = "Cancel" ] || [ -z "$VER" ]; then
                echo -e "${WHITE}Cancelled. No virtual environment created.${RESET}"
                return 0
            else
                echo -e "${GREEN}You selected Python $VER${RESET}"
                pyvenv "$VER_NAME" "$VER"
                return
            fi
        done
    fi

    # Gather args
    local v_name=$1
    local py_ver=$2

    if [ -z "$v_name" ]; then
        read -erp "$(echo -e "${WHITE}Enter the virtual environment name: ${RESET}")" v_name
    fi

    if [[ "$v_name" =~ ^- ]]; then
        echo -e "${RED}Error: Virtual environment name cannot start with a dash: '$v_name'${RESET}"
        echo -e "${WHITE}Usage: pyvenv NAME [VERSION]${RESET}"
        echo -e "${WHITE}       pyvenv --list${RESET}"
        echo -e "${WHITE}       pyvenv --check-ver${RESET}"
        return 1
    fi

    local v_home="$HOME/python-virtual-environs/$v_name"

    # Check pythonz
    if ! command -v pythonz >/dev/null 2>&1; then
        echo -e "${RED}pythonz not found. ${WHITE}Installing...${RESET}"
        curl -sL https://raw.github.com/saghul/pythonz/master/pythonz-install | bash
        if ! grep -q '\.pythonz/etc/bashrc' "$HOME/.bashrc"; then
            echo '[[ -s $HOME/.pythonz/etc/bashrc ]] && source $HOME/.pythonz/etc/bashrc' >> "$HOME/.bashrc"
            echo -e "${GREEN}Added pythonz to .bashrc${RESET}"
        fi
        source "$HOME/.bashrc"
        pyvenv "$v_name" "$py_ver"
        return
    fi

    # Create venv if missing
    if [ ! -d "$v_home" ]; then
        echo -e "${YELLOW}Virtual environment '${WHITE}${v_name}${YELLOW}' does not exist. ${WHITE}Creating it now.${RESET}"
        if [ -z "$py_ver" ]; then
            read -erp "$(echo -e "${WHITE}Enter the Python version (e.g. 3.12.1): ${RESET}")" py_ver
        fi

        local usepy
        usepy=$(pythonz locate "$py_ver" 2>/dev/null)
        if [[ -z "$usepy" || "$usepy" == "ERROR: "* ]]; then
            echo -e "${WHITE}Python ${RED}$py_ver${WHITE} not found. ${WHITE}Installing...${RESET}"
            pythonz install --verbose --configure="--without-pydebug" "$py_ver"
            usepy=$(pythonz locate "$py_ver")
        fi

        "$usepy" -m venv "$v_home"
        echo -e "${GREEN}Virtual environment '${WHITE}${v_name}${YELLOW}' created successfully.${RESET}"
    else
        usepy="$v_home/bin/python3"
        py_ver=$("$usepy" --version 2>/dev/null | awk '{print $2}')
        echo -e "${GREEN}Virtual environment '$v_name' already exists.${RESET}"
    fi

    echo
    echo -e "${WHITE}  VENV name:   ${GREEN}$v_name${RESET}"
    echo -e "${WHITE}  VENV path:   ${GREEN}$v_home${RESET}"
    echo -e "${WHITE}  Python used: ${GREEN}$usepy${RESET}"
    echo -e "${WHITE}  Version:     ${GREEN}$py_ver${RESET}"
    echo

    source "$v_home/bin/activate"
    echo -e "${WHITE}Activated virtual environment '${YELLOW}${v_name}${WHITE}'. Type 'deactivate' to exit.${RESET}"
}
# Automatic integreation: Stop at this line
check_src() {
    # Check to see if the whole script is being sourced or running stand alone because this part shouldn't be included if sourced
    if [[ "$(ps -o ppid= -p $$)" -eq 1 ]]; then
        pyvenv $1 $2
    fi
}

check_src $1 $2
