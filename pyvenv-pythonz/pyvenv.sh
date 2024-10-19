#!/bin/bash

check_src() {
    # Check to see if the whole script is being sourced or running stand alone because this part shouldn't be included if sourced
    if [[ "$(ps -o ppid= -p $$)" -eq 1 ]]; then
        pyvenv $1 $2
    fi
}

check_src $1 $2

# Want automatic integreation? Copy everything below this line into either /etc/bash.bashrc or $HOME/.bashrc and restart your terminal!
# Moving these colour-code variables outside this function makes them available to the whole script, not just this function
RESET="\033[0m" #Normal
RED="\033[1;31m" #Red
GREEN="\033[1;32m" #Green
YELLOW="\033[1;33m" #Yellow
WHITE="\033[1;37m" #White

# Function to check and create a Python virtual environment using pythonz
pyvenv() {
    # If no parameters are given, we prompt for both
    # If only one is given, it will be assumed to be NAME
    # If both are given, first will be assumed to be NAME, second will be VERSION
    local v_name=${1:-$(read -p "Enter the virtual environment name: " name && echo $name)}
    local v_home="$HOME/python-virtual-environs/$v_name"

    # Check if pythonz is installed
    if ! command -v pythonz &> /dev/null; then
        echo -e "${RED}Couldn't find pythonz. ${WHITE}Installing...\n"
        curl -kL https://raw.github.com/saghul/pythonz/master/pythonz-install | bash

        # Check if the bashrc configuration exists
        if ! grep -q "[[ -s \$HOME/.pythonz/etc/bashrc ]]" "$HOME/.bashrc"; then
            echo "[[ -s \$HOME/.pythonz/etc/bashrc ]] && source \$HOME/.pythonz/etc/bashrc" >> "$HOME/.bashrc"
            echo -e "${GREEN}Added pythonz to .bashrc\n"
        fi

        # Source the updated .bashrc
        source "$HOME/.bashrc"
        pyvenv $1
        return
    fi

    # Check to be sure user didn't just hit ENTER when prompted for NAME
    if [ -z "$v_name" ]; then
        echo -e "\n${RED}Error: Virtual environment name must be provided.\n"
        return 1
    fi

    # If $v_home doesn't exist, assume we're making a new VENV and prompt for Python version
    if [ ! -d "$v_home" ]; then
        py_ver=${2:-$(read -p "Enter the Python version: " version && echo $version)}
        usepy="$(pythonz locate $py_ver)"
        no_py="ERROR: \`CPython-$py_ver\` is not installed."
        # Check to see if the requested version is installed
        if [[ -z "$usepy" || "$usepy" = "$no_py" ]]; then
            echo -e "\n${WHITE}Installing now.\n"
            pythonz install "$py_ver"
            usepy="$(pythonz locate $py_ver)"
        fi

        # Create VENV
        $usepy -m venv "$v_home" 
    else
        usepy="$v_home/bin/python3"
        py_ver=$($usepy --version 2>&1 | awk '{print $2}')
    fi
 
    echo -e "${WHITE}\n    \$usepy=$usepy"
    echo -e "    \$v_name=$v_name"
    echo "    \$v_home=$v_home"
    echo -e "    \$py_ver=$py_ver\n"

    # Activate VENV
    source "$v_home/bin/activate"
    echo -e "\nType 'deactivate' to exit this venv when you're done."
    echo -e "${RESET} \n"
}
