#!/usr/bin/env bash

#set -eo pipefail

# This is nearing the final evolution of my Game Installer Script. Command-line parameters are now optional,
# I've added colour to the output, the logic has been tweaked out a bit so now the script will check for WINE,
# and attempt to install it, should it not be found, and I've also added commentary to each section to explain
# what it all does and added extensive error handling. As far as features go, I have made the MSVC redist,
# Vulkan, MONO and GECKO installs functions which are called independently of actually performing an install with
# a command-line parameter, and added a GameScope wrapper function for the launcher scripts. $WINEPREFIX is now
# optional and can be provided on the commandline. If it doesn't exist, it will be created. Assumes a default
# location as WINEPREFIX="/home/$(whoami)/Games/$NOSPACE" if not provided with "-p (or --prefix) {PREFIX}".
# Due to the fact that some installers do "boxed sets" - that is, they install multiple games, this installer
# script now allows you to select multiple .exe files, if so desired, for your launcher script. If you only
# select one, the launcher writes a standard launcher script. If you select multiple, it writes a menu to the
# launcher which prompts you to choose the .exe you want to run. The menu option text in the "echo" lines can
# be changed later if you want to provide a proper title, so long as the GameScope wrapper is left alone. For
# example, I've included my "Dishonored Collection" launcher menu as an example:
# 
# echo "Select a game to launch:"
# echo "1) Dishonored"
# echo "2) Dishonored 2"
# echo "3) Dishonored: Death of the Outsider"
# read -rp "Enter number: " choice
# case "$choice" in
#   1) cd "${GAMEDEST}/Dishonored/Binaries/Win32" && do_gameScope "Dishonored.exe" ;;
#   2) cd "${GAMEDEST}/Dishonored 2" && do_gameScope "Dishonored2.exe" ;;
#   3) cd "${GAMEDEST}/Dishonored - Death of the Outsider" && do_gameScope "Dishonored_DO.exe" ;;
#   *) echo "Invalid selection." ;;
# esac
# 
# 

# Function: showHelp
# Purpose: Displays usage help and exits
showHelp() {
    echo -e "${GREEN}$0 \"GAME_FOLDER\" -s|--skip-msvc -v|--skip-vulkan -p|--prefix \"{PREFIX}\" -h|--help"
    echo -e "${YELLOW}    -h or --help"
    echo -e "${WHITE}        Optional: Displays this help text and quits, ignoring all other options given."
    echo -e "${YELLOW}    \"GAME_FOLDER\""
    echo -e "${WHITE}        Optional: local folder containing a game or app installer (must be s '.exe' file)."
    echo "        If this option is not specified, the installer will list all folders, requiring you to pick one."
    echo "        When specifying a folder, you should enclose it in double quotes, even if it doesn't contain spaces."
    echo -e "${YELLOW}    -s or --skip-msvc"
    echo -e "${WHITE}        Optional: Skip installing MSVC redistributables"
    echo "        By default, MSVC redist are installed."
    echo -e "${YELLOW}    -v or --skip-vulkan"
    echo -e "${WHITE}        Optional: Skip installing Vulkan"
    echo "        By default, Vulkan is installed and updated."
    echo -e "${YELLOW}    -p {PREFIX} or --prefix \"{PREFIX}\""
    echo -e "${WHITE}        Optional: Create or use the WINE prefix \"{PREFIX}\""
    echo -e "        Default Prefix is ${YELLOW}/home/$(whoami)/Games/GAME_FOLDER ${WHITE}unless changed with ${GREEN}-p${WHITE} or ${GREEN}--prefix${WHITE}."
    echo -e "        Here as well, you should enclose the path in double quotes even if it doesn't contain spaces.\n${RESET}"
}

# Function: grab_exe_list
# Purpose: Given a folder, finds all .exe files and lets user pick one
grab_exe_list() {
    local search_dir="$1"
    local -n _result=$2  # use nameref to return result in array
    local -n _chosen=$3  # use nameref to return selected value
    # shellcheck disable=SC2207
    _result=($(find "$search_dir" -type f -iname "*.exe"))
    if [ "${#_result[@]}" -eq 0 ]; then
        echo -e "\n${RED}No .exe files found in ${YELLOW}\"$search_dir\"${WHITE}\n"
        return 1
    fi

    echo -e "\n${YELLOW}Found the following .exe files in ${WHITE}\"$search_dir\":\n"
    for ((i=0; i<"${#_result[@]}"; i++)); do
        if ((i % 2 == 0)); then
            echo -e "${ULINE}${WHITE}$i: ${_result[$i]}${RESET}${WHITE}"
        else
            echo -e "${ULINE}${GREEN}$i: ${_result[$i]}${RESET}${WHITE}"
        fi
    done
    echo
    while true; do
        IFS= read -r -p "Select an .exe file: " user_sel
        if [[ "$user_sel" =~ ^[0-9]+$ && "$user_sel" -lt "${#_result[@]}" ]]; then
            # shellcheck disable=SC2207
            _chosen="$(basename "${_result[$user_sel]}")"
            return 0
        else
            echo -e "\n${YELLOW}\"$user_sel\" ${RED}is not a valid choice.${WHITE}\n"
        fi
    done
    return 0
}

# Function: install_msvc_redist
# Purpose: Installs MSVC redist packages from $RSRC, unless skipped
install_msvc_redist() {
    # shellcheck disable=SC2164
    cd "$RSRC"
    for i in *.exe; do
        echo -e "${WHITE}Installing ${YELLOW}$i${WHITE} into $WINEPREFIX..."
        "$WINE" "$i" >/dev/null 2>&1
    done
    SKIP_MSVC=true
}

# Function: install_vulkan
# Purpose: install or update DXVK
install_vulkan() {
    # Install or update Vulkan. Ping GIT HUB to verify network connectivity, then get the latest version of VULKAN,
    # compare to what's installed (if any), and download and install the latest version if there's either none already
    # installed or the installed version is older than the current release. Downloads are deleted after install.
    curl -s --head https://github.com | grep "200 OK" >/dev/null || { echo -e "${RED}Possibly no network. Booting might fail.${WHITE}" ; }
    VLKLOG="$WINEPREFIX/vulkan.log"; VULKAN="$PWD/vulkan"; VLKVER="$(curl -s -m 5 https://api.github.com/repos/jc141x/vulkan/releases/latest | awk -F '["/]' '/"browser_download_url":/ {print $11}' | cut -c 1-)"
    status-vulkan() {
        [[ ! -f "$VLKLOG" || -z "$(awk "/^${FUNCNAME[1]}\$/ {print \$1}" "$VLKLOG" 2>/dev/null)" ]] || { echo -e "${FUNCNAME[1]} present" && return 1; };
    }
    vulkan() {
        DL_URL="$(curl -s https://api.github.com/repos/jc141x/vulkan/releases/latest | awk -F '["]' '/"browser_download_url":/ {print $4}')"
        # shellcheck disable=SC2015
        VLK="$(basename "$DL_URL")"; [ ! -f "$VLK" ] && command -v curl >/dev/null 2>&1 && curl -LO "$DL_URL" && tar -xvf "vulkan.tar.xz" || { rm "$VLK" && echo -e "ERROR: Failed to extract vulkan translation." && return 1; }
        rm -rf "vulkan.tar.xz" && bash "$PWD/vulkan/setup-vulkan.sh" && rm -Rf "$VULKAN"
    }
    vulkan-dl() {
        echo -e "Using external vulkan translation (dxvk,vkd3d,dxvk-nvapi)." && vulkan && echo -e "$VLKVER" >"$VLKLOG"
    }
    [[ ! -f "$VLKLOG" && -z "$(status-vulkan)" ]] && vulkan-dl
    [[ -f "$VLKLOG" && -n "$VLKVER" && "$VLKVER" != "$(awk '{print $1}' "$VLKLOG")" ]] && { rm -f vulkan.tar.xz || true; } && vulkan-dl;
    SKIP_VULKAN=true
}

# Function: get_latest_msi
# Purpose: find the latest MSI file from a Wine download directory
get_latest_msi() {
    local base_url=$1
    curl -s -A "$USER_AGENT" "$base_url" |
        grep -oE 'wine-[a-z]+-[0-9]+\.[0-9]+(\.[0-9]+)?(-x86)?\.msi' |
        sort -V |
        uniq |
        tail -n1
}

# Function: download_if_missing
# Purpose: download and install missing WINE components
download_if_missing() {
    local base_url=$1
    local filename=$2
    local target="$WINE_CACHE/$filename"

    if [[ -f "$target" ]]; then
        echo -e "${GREEN}[✓] $filename already exists.${RESET}"
    else
        echo -e "${YELLOW}[↓] Downloading $filename...${WHITE}"
        wget -q --show-progress "$base_url/$filename" -O "$target"
        echo -e "${GREEN}[✓] Saved to $target${RESET}"
    fi
}

# Function: do_mono_gecko
# Purpose: download and install MONO and Gecko
do_mono_gecko() {
    WINE_CACHE="$HOME/.cache/wine"
    MONO_URL="https://dl.winehq.org/wine/wine-mono"
    GECKO_URL="https://dl.winehq.org/wine/wine-gecko"
    USER_AGENT="Mozilla/5.0"

    mkdir -p "$WINE_CACHE"

    echo -e "${YELLOW}[ℹ] Checking for the latest Wine Mono and Gecko installers...${WHITE}"

    # Get latest Mono
    latest_mono=$(get_latest_msi "$MONO_URL")
    # Get latest Gecko x86 and x86_64
    latest_gecko_x86=$(curl -s -A "$USER_AGENT" "$GECKO_URL" | grep -oE 'wine-gecko-[0-9]+\.[0-9]+-x86\.msi' | sort -V | tail -n1)
    latest_gecko_64=$(curl -s -A "$USER_AGENT" "$GECKO_URL" | grep -oE 'wine-gecko-[0-9]+\.[0-9]+\.msi' | sort -V | tail -n1)

    # Download them if needed
    download_if_missing "$MONO_URL" "$latest_mono"
    download_if_missing "$GECKO_URL" "$latest_gecko_x86"
    download_if_missing "$GECKO_URL" "$latest_gecko_64"

    echo -e "${GREEN}[✓] Mono and Gecko installers are up to date in $WINE_CACHE"
}

IFS=$'\n'

# Define some fancy colourful text with BASH's built-in escape codes. Example:
# echo -e "${BOLD}${YELLOW}This text will be displayed in BOLD YELLOW. ${RESET}While this text is normal."
ULINE=$'\e[4m'
YELLOW=$'\e[1;33m'
RED=$'\e[1;91m'
GREEN=$'\e[1;92m'
WHITE=$'\e[1;97m'
# Normal
RESET=$'\e[0m'

# -----------------------------
# Defaults
# -----------------------------
FORCE_RUN=false
SKIP_VULKAN=false
SKIP_MSVC=false
POSITIONAL=()
LAUNCHER=""
CUSTOM_PREFIX=""
EXE=""

# -----------------------------
# Parse flags
# -----------------------------
POSITIONAL=()
# shellcheck disable=SC2221
# shellcheck disable=SC2222
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            showHelp; exit 0;;
        --force)
            FORCE_RUN=true; shift;;
        -s|--skip-msvc)
            SKIP_MSVC=true; shift;;
        -v|--skip-vulkan)
            SKIP_VULKAN=true; shift;;
        -p|--prefix)
            CUSTOM_PREFIX="$2"; echo -e "${WHITE}Custom Prefix: ${CUSTOM_PREFIX}"; shift 2;;
        -*|--*)
            echo "Warning: Ignoring unknown option '$1'" >&2; shift;;
        *)
            POSITIONAL+=("$1"); GAMEDEST="$1"; shift;;
    esac
done

if [[ ${#POSITIONAL[@]} -gt 1 ]]; then
    echo -e "${RED}Note: Multiple folders given: ${WHITE}${POSITIONAL[*]}"
    echo -e "${RED}Only ${WHITE}${GAMEDEST}${RED} will be used.${RESET}"
fi

# restore positional parameters: $1 is now your game-folder (if any)
set -- "${POSITIONAL[@]}"

echo -e "${WHITE}" # Make the text bold and white by default because it's easier to read.
# User ID, working directory and parameter checks - NO ROOT!!!
cd "$(dirname "$(readlink -f "$0")")" || exit; [ "$EUID" = "0" ] && echo -e "${RED}Gotta quit here because I can't run as root. ${WHITE}I'll prompt you if I need root access.${RESET}" && exit 255

# Check if a foler was supplied on the command line and deal with any trailing slashes, should they exist
if [[ -z "$1" ]]; then
    # Load all subfolders into an array and make it a numbered list
    GDIRS=()
    echo -e "\n${RED}Commandline was blank. ${WHITE}Listing potential game folders:\n"
    for dir in */; do
        if [[ $dir =~ ^\.[^.]|^\.redist ]]; then
            continue
        fi
        GDIRS+=("$dir")
    done
    for ((i=0; i<"${#GDIRS[@]}"; i++)); do
        # Write the list to the screen, removing the trailing slashes, and determine the color based on the index
        if ((i % 2 == 0)); then
            echo -e "${ULINE}${WHITE}$i: ${GDIRS[$i]%/}${RESET}${WHITE}"
        else
            echo -e "${ULINE}${GREEN}$i: ${GDIRS[$i]%/}${RESET}${WHITE}"
        fi
    done
    # Ask for input based on the list, looping until a valid response is given
    while true; do
        echo -e "${WHITE}"
        IFS= read -r -p "Choose a number from the list above: " dirsel
        echo
        if [[ $dirsel =~ ^[0-9]+$ && $dirsel -ge 0 && $dirsel -le ${#GDIRS[@]} ]]; then
            echo
            break
        else
            echo -e "${YELLOW}\"$dirsel\" was ${RED}NOT ${YELLOW}an option - let's try again."
            echo
        fi
    done

    LAUNCHER="${GDIRS[dirsel]%/}" # Remove trailing slash if present
    echo -e "${YELLOW}Launching install script for \"${ULINE}${WHITE}$LAUNCHER${RESET}${YELLOW}\":"
    echo
    # By calling '. $0 "${GDIRS[dirsel]}"' we can relaunch this script using the chosen directory as the commandline
    # option and avoid writing extra code to tell the script that each instance of "$1" should be "$1" unless the
    # array for $GDIRS has been set, in which case, use "${GDIRS[dirsel]}". It's much simpler this way because even
    # the first original version of this install script always took a folder name as a commandline argument.
    exec "$0" --force ${CUSTOM_PREFIX:+--prefix "$CUSTOM_PREFIX"} "$LAUNCHER"
    exit 0
fi

shopt -s nocaseglob # Enable case-insensitive globbing for filenames

# Assuming the script was run with an option by the user, and not called from the loop above,
# check to make sure the provided directory name actually exists. If not, exit with an error.
if [ ! -d "$1" ]; then
    echo -e "\n${RED}I can't find \"${WHITE}${ULINE}$1${RESET}${RED}\". Maybe try checking your spelling?${RESET}\n"
    exit 255
fi

if [[ "$1" == */ ]]; then
    ONE="${1%/}"
else
    ONE="$1"
fi

NOSPACE="${ONE// /_}"
echo -e "${WHITE}\nThis script will attempt to install WINE for you if it isn't already installed."
echo -e "As such, it would be ${ULINE}${YELLOW}REALLY HELPFUL${RESET}${WHITE} if you have Internet access."
echo -e "It's also largely failproof, so if it encounters something it can't fix, or something"
echo -e "which can't be fixed later by tweaking the runner script, it will exit with a fatal"
echo -e "error. Everything is mostly automated, only requiring you to answer a few prompts.\n"
# shellcheck disable=SC2162
read -r -p $'\nTo continue, press '"${YELLOW}"'<ENTER>'"${WHITE}"'. To cancel, press '"${YELLOW}"'<CTRL-C>'"${WHITE}"'. ' donext

# If WINE check fails, determine package manager.
# Next, check if WINE repo is already added. If not, add it.
# Refresh package cache and install WINE
echo -e "${YELLOW}Checking for WINE..."; sleep 1
if ! command -v wine &> /dev/null; then
    echo -e "\n${RED}WINE isn't installed. ${WHITE}Attempting to rectify...\n"
    if command -v apt &> /dev/null; then
        PMGR="apt"
        INST="sudo apt install -y --install-recommends winehq-stable winetricks"
        REPO="sudo add-apt-repository -y ppa:wine/wine-builds"
        if ! grep -q "wine/wine-builds" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
            eval "$REPO"
        fi
    elif command -v dnf &> /dev/null; then
        PMGR="dnf"
        INST="sudo dnf install -y wine"
        REPO="sudo dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/$(rpm -E %fedora)/winehq.repo"
        if ! dnf repolist | grep -q "winehq"; then
            eval "$REPO"
        fi
    elif command -v pacman &> /dev/null; then
        PMGR="pacman"
        INST="sudo pacman -S --noconfirm wine"
        REPO="echo '[wine]' | sudo tee /etc/pacman.d/wine.conf"
        if ! pacman -Slq | grep -q "wine"; then
            eval "$REPO"
        fi
    elif command -v zypper &> /dev/null; then
        PMGR="zypper"
        INST="sudo zypper install wine"
        REPO="echo 'deb http://download.opensuse.org/repositories/Emulators:/Wine/openSUSE_Tumbleweed/ /' | sudo tee /etc/apt/sources.list.d/wine.list"
        if ! zypper lr | grep -q "Wine"; then
            eval "$REPO"
        fi
    else
        echo -e "\n${RED}What are you even running this on? This won't work.${RESET}\n"
        exit 255
    fi

    # Refresh the package manager's repository cache
    if [ "$PMGR" = "apt" ]; then
        sudo apt update
    elif [ "$PMGR" = "dnf" ]; then
        sudo dnf makecache
    elif [ "$PMGR" = "pacman" ]; then
        sudo pacman -Sy
    elif [ "$PMGR" = "zypper" ]; then
        sudo zypper refresh
    fi

    if ! eval "$INST"; then
        ERRNUM=$?
        echo -e "\n${RED}Fatal error ${WHITE}$ERRNUM ${RED}occurred installing WINE. ٩(๏̯๏)۶ \n${YELLOW}Hey. Don't look at me. ${WHITE}I don't know what it means.\n${YELLOW}Try Googling error ${ULINE}$ERRNUM ${RESET}${YELLOW}and see if that helps?${RESET}\n"
        exit $ERRNUM
    fi
fi

# Variable Declarations
# Using the short-circuit trick, check if $WINE is empty (if we didn't have to install WINE, it will be)
# and if so, assign it through command substitution
WINE="$(command -v wine)" # Set $WINE
WINEVER="$(wine --version)" # Get the WINE version number
WINE_LARGE_ADDRESS_AWARE=1
WINEDLLOVERRIDES="winemenubuilder.exe=d;mshtml=d;dxgi=n;mscoree,mshtml=" #;nvapi,nvapi64=n" # Set environment variables for WINE

# Install or update MONO and GECKO
do_mono_gecko

# Create Wineprefix if it doesn't exist
if [[ -n "$CUSTOM_PREFIX" ]]; then
    WINEPREFIX="$CUSTOM_PREFIX"
    echo -e "${GREEN}Using custom prefix ${WHITE}${WINEPREFIX}${RESET}"
else
    WINEPREFIX="/home/$(whoami)/Games/$NOSPACE"
    echo -e "${GREEN}Using default prefix ${WHITE}${WINEPREFIX}${RESET}"
fi

G_SRC="$PWD/$ONE" # Game Source Folder (where the setup is)
GAMEDEST="$WINEPREFIX/drive_c/Games/$ONE" # Game Destination Folder (where it's going to be)
GSS="$WINEPREFIX/drive_c/${NOSPACE}.sh" # Game Starter Script - written automatically by this script
RSRC="$PWD/.redist" # Location of the MSVC Redistributables

export WINE
export WINEVER
export WINE_LARGE_ADDRESS_AWARE
export WINEDLLOVERRIDES
export WINEPREFIX
export G_SRC
export GAMEDEST
export GSS
export RSRC

echo -e "\n${GREEN}WINE version ${YELLOW}$WINEVER${GREEN} is installed."

# Check to see if $G_SRC actually exists. If not, exit with an error (useful check if user gives $1)
if [ ! -d "$G_SRC" ]; then
    echo -e "${RED}Error: \"${WHITE}$G_SRC${RED}\" doesn't exist.\n ლ(ಠ益ಠ)ლ \n${RESET}"
    exit 255
fi

# Check to see if $G_SRC contains files. If not, exit with an error (also useful check if user gives $1)
if [ -z "$G_SRC" ]; then
    echo -e "${RED}Error: \"$G_SRC\" is an empty directory.${WHITE}\n ಠ_ಠ \n${RESET}"
    exit 255
fi

if [ ! -d "$WINEPREFIX/drive_c" ]; then
    echo -e "${WHITE}Initializing new WINE prefix at ${YELLOW}$WINEPREFIX${WHITE}..."
    "$WINE" wineboot -u >/dev/null 2>&1
fi

# MSVC redistributables  / Vulkan - if "skip" was given, don't ask about installing them.
# Otherwise, ask and act accordingly.
if [ "$FORCE_RUN" = true ]; then
    install_vulkan
    install_msvc_redist
fi
if [ "$SKIP_MSVC" = false ]; then
    install_msvc_redist
fi
if [ "$SKIP_VULKAN" = false ]; then
    install_vulkan
fi

# Create an array containing all the .exe files.
# If there aren't any .exe files in the directory, exit with an error
grab_exe_list "$G_SRC" GRAB_EXE EXE
# shellcheck disable=SC2181
[ $? -ne 0 ] && exit 255
EXE=$(basename "$EXE")

# If $GAMEDEST doesn't exist, create it
[ ! -d "$GAMEDEST" ] && mkdir -p "$GAMEDEST"

# Print variables, their contents, and an explanatory note for verification.
echo -e "\n${WHITE}Technical details, if you care:\n"
echo -e "\n${YELLOW}    \$GSS=\"$GSS\""
echo -e "    \$G_SRC=\"$G_SRC\""
echo -e "    \$WINEPREFIX=\"$WINEPREFIX\""
echo -e "    \$GAMEDEST=\"$GAMEDEST\""
echo -e "    \$WINEDLLOVERRIDES=\"winemenubuilder.exe=d;mshtml=d;nvapi,nvapi64=y\""
echo -e "    \$WINE_LARGE_ADDRESS_AWARE=1\n"
echo -e "\n        Installer=\"$EXE\"${WHITE}\n"
echo -e "\n  I ${YELLOW}${ULINE}***STRONGLY***${RESET}${WHITE} recommend picking the folder \"${ULINE}${YELLOW}$GAMEDEST${RESET}${WHITE}\""
echo -e "  when the installer launches. For the sake of automation, this installer script creates the directory using"
echo -e "  the placeholder \"${YELLOW}\$GAMEDEST${WHITE}\", and that's where the launcher script will expect it to be.\n"
echo -e "\n  If the installer doesn't default to \"${YELLOW}C:\Games\\$1${WHITE}\" you can change it using the advanced options.\n"
echo -e "\n  Also, you don't need to install DirectX or the MSVC Redistributables from the installer menu."
echo -e "  Vulkan replaces DirectX, and the MSVC Redistributables can be (re)installed any time by running this script again."
echo -e "  This install scripthandles all that, as you have no doubt already noticed.\n"
echo -e "\n  If you let the game's installer use a different folder, you will have to manually change the path and possibly the"
echo -e "  filename for the game's primary ${YELLOW}.exe ${WHITE}in the ${YELLOW}$GSS ${WHITE}script to match.\n"
echo -e "\n  If you do modify the launcher script, remember that paths and files are ${RED}Case Sensitive${WHITE} on Linux.\n"
# shellcheck disable=SC2034
read -r -p $'\nTo continue, press '"${YELLOW}"'<ENTER>'"${WHITE}"'. To cancel, press '"${YELLOW}"'<CTRL-C>'"${WHITE}"'. ' donext

# Enables some nVidia-specific functionality, offering entry points for supporting the following features in applications:
# - NVIDIA DLSS for Vulkan, by supporting the relevant adapter information by querying from Vulkan.
# - NVIDIA DLSS for D3D11 and D3D12, by querying from Vulkan and forwarding the relevant calls into DXVK / VKD3D-Proton.
# - NVIDIA Reflex, by forwarding the relevant calls into either DXVK / VKD3D-Proton or LatencyFleX.
# - Several NVAPI D3D11 extensions, among others SetDepthBoundsTest and UAVOverlap, by forwarding the relevant calls into DXVK.
# - NVIDIA PhysX, by supporting entry points for querying PhysX capabilities.
# - Several GPU topology related methods for adapter and display information, by querying from DXVK and Vulkan.
# Note that DXVK-NVAPI does not implement DLSS, Reflex or PhysX. It mostly forwards the relevant calls.
export DXVK_ENABLE_NVAPI=1

# Start WINE and pass the primary installer .EXE to it.
echo -e "\n${WHITE}Starting \"${YELLOW}${ONE}${WHITE}\" installer...\n"
# shellcheck disable=SC2164
cd "$G_SRC" # This is the source folder for the .exe
#Run WINE with an "If It Fails" assumption block.
if ! "$WINE" "$EXE" "$@" >/dev/null 2>&1; then
    # If it did fail, save the error number and exit with a message.
    ERRNUM=$?
    echo -e "\n${RED}Error code ${YELLOW}$ERRNUM ${RED}detected on exit.\n${WHITE}Looks like something went wrong.\nUnfortunately, since ${RED}$ERRNUM${WHITE} is a Windows-related error, I can't help you.\n${RESET}"
    exit 255
fi

# We used this once already so we're blanking it so we can reuse it
EXE=""
GRAB_EXE=""
DO_GSS="y"
SELECTED_EXES=()

# This is the destination folder, originally set at the start: GAMEDEST="$WINEPREFIX/drive_c/Games/$ONE"
cd "$GAMEDEST" || exit 1

# Run grab_exe_list to populate GRAB_EXE and EXE
if ! grab_exe_list "$GAMEDEST" GRAB_EXE EXE; then    echo -e "\n${WHITE}\"${RED}$GAMEDEST${WHITE}\" doesn't contain any .exe files.\n\n${YELLOW} ლ(ಠ益ಠ)ლ ${WHITE}\n\n"
    IFS= read -r -p "Continue anyway? You'll have to manually edit the launcher script. (y/n) " DO_GSS
    case $DO_GSS in
        [nN] ) echo -e "${RED}Stopping as requested.${RESET}"; exit 255;;
        * ) SELECTED_EXES=("Just A Place Holder - Replace Me With Game's Actual .EXE");;
    esac
else
    if [ -n "$EXE" ]; then
        SELECTED_EXES+=("$EXE")
    fi
fi

while true; do
    echo -e "\n${WHITE}Additional game runner options:\n"
    for ((i=0; i<"${#GRAB_EXE[@]}"; i++)); do
        if (( i % 2 == 0 )); then
            color="$WHITE"
        else
            color="$GREEN"
        fi
        echo -e "${ULINE}${color}$i: ${GRAB_EXE[$i]}${RESET}${WHITE}"
    done
    echo -e "\n${WHITE}Selected so far:${YELLOW}"
    printf '  %s\n' "${SELECTED_EXES[@]}"
    echo -e "${WHITE}"

    IFS= read -r -p "Select game .EXE (or 'q' to finish): " gamesel
    if [[ "$gamesel" =~ ^[QqXx]$ ]]; then
        break
    elif [[ "$gamesel" =~ ^[0-9]+$ && $gamesel -lt ${#GRAB_EXE[@]} ]]; then
        selected="${GRAB_EXE[$gamesel]}"
        if [[ ! " ${SELECTED_EXES[*]} " =~ " $selected " ]]; then
            SELECTED_EXES+=("$selected")
        else
            echo -e "${YELLOW}Already selected.${WHITE}"
        fi
    else
        echo -e "\n${YELLOW}$gamesel ${RED}wasn't a valid number.${WHITE}\n"
    fi
done

echo -e "\n${WHITE}Game Destination: \"${YELLOW}$GAMEDEST${WHITE}\" (\"C:\Games\\$ONE\")\n\nWriting Game Starter Script (GSS) for ${YELLOW}$ONE ${WHITE}to ${YELLOW}$GSS ${WHITE}...\n"

# Create game starter script by writing everything up to "EOL" in the file defined in $GSS
cat << EOL > "${GSS}"
#!/bin/bash

###############
## Script Name:
## $GSS
###############

# Wrapper to run a game EXE with or without GameScope
do_gameScope() {
    local app="\$1"
    shift
    if command -v gamescope &>/dev/null; then
        echo "Launching with GameScope (display: \$PRIMARY_DISPLAY)..."
        exec gamescope -e --adaptive-sync -O "\$PRIMARY_DISPLAY" -- \
             "\$WINE" "\$app" "\$@"
    else
        echo "GameScope not found. Launching game directly..."
        exec "\$WINE" "\$app" "\$@"
    fi
}

# Change the current working directory to the one the scipt was run from
cd "\$(dirname "\$(readlink -f "\$0")")" || exit; [ "\$EUID" = "0" ] && echo -e "Please don't run as root!" && exit

# Make sure WINE is configured (although, I'm assuming it was done by the original installer script)
export WINE="\$(command -v wine)"
export WINEPREFIX="$WINEPREFIX"
export WINEDLLOVERRIDES="winemenubuilder.exe=d;mshtml=d;dxgi=n"
export WINE_LARGE_ADDRESS_AWARE=1
#export RESTORE_RESOLUTION=1
#export WINE_D3D_CONFIG="renderer=vulkan"
export GAMEDEST="\${WINEPREFIX}/drive_c/Games/${ONE}"
export DXVK_ENABLE_NVAPI=1
export PRIMARY_DISPLAY=\${PRIMARY_DISPLAY:-0}

# Check Vulkan version and download and install if there's a newer version available online

curl -s --head https://github.com | grep "200 OK" >/dev/null || { echo -e "Possibly no network. This may mean that booting will fail." ; }; VLKLOG="\$WINEPREFIX/vulkan.log"; VULKAN="\$PWD/vulkan"
VLKVER="\$(curl -s -m 5 https://api.github.com/repos/jc141x/vulkan/releases/latest | awk -F '["/]' '/"browser_download_url":/ {print \$11}' | cut -c 1-)"
status-vulkan() { [[ ! -f "\$VLKLOG" || -z "\$(awk "/^\${FUNCNAME[1]}\$/ {print \$1}" "\$VLKLOG" 2>/dev/null)" ]] || { echo -e "\${FUNCNAME[1]} present" && return 1; }; }
vulkan() { DL_URL="\$(curl -s https://api.github.com/repos/jc141x/vulkan/releases/latest | awk -F '["]' '/"browser_download_url":/ {print \$4}')"; VLK="\$(basename "\$DL_URL")"
[ ! -f "\$VLK" ] && command -v curl >/dev/null 2>&1 && curl -LO "\$DL_URL" && tar -xvf "vulkan.tar.xz" || { rm "\$VLK" && echo -e "ERROR: Failed to extract vulkan translation." && return 1; }
rm -rf "vulkan.tar.xz" && bash "\$PWD/vulkan/setup-vulkan.sh" && rm -Rf "\$VULKAN"; }
vulkan-dl() { echo -e "Using external vulkan translation (dxvk,vkd3d,dxvk-nvapi)." && vulkan && echo -e "\$VLKVER" >"\$VLKLOG"; }
[[ ! -f "\$VLKLOG" && -z "\$(status-vulkan)" ]] && vulkan-dl;
[[ -f "\$VLKLOG" && -n "\$VLKVER" && "\$VLKVER" != "\$(awk '{print \$1}' "\$VLKLOG")" ]] && { rm -f vulkan.tar.xz || true; } && vulkan-dl

# Detect primary display (auto handles multi-monitor)
PRIMARY_DISPLAY=\$(xrandr --query | awk '/ primary/{print \$1; exit}')
# Start process in WINE with GameScope, if available
EOL

if [[ ${#SELECTED_EXES[@]} -eq 1 ]]; then
    full_path="${SELECTED_EXES[0]}"
    rel_path="${full_path#$GAMEDEST/}"
    exe_dir="$(dirname "$rel_path")"
    EXE="$(basename "$rel_path")"

    cat << EOL >> "${GSS}"
cd "\$GAMEDEST/${exe_dir}"
[[ -f "$EXE" ]] || { echo -e "Executable not found: $EXE"; exit 1; }

do_gameScope "$EXE" "$@"

EOL
else
    # Start the menu section
    cat << EOL >> "${GSS}"

# Menu entries relative to \$GAMEDEST
REL_EXES=(
EOL

    # Write each relative path into the REL_EXES array
    for p in "${SELECTED_EXES[@]}"; do
        rel="${p#$GAMEDEST/}"
        printf '  "%s"\n' "$rel" >> "$GSS"
    done

    cat << 'EOL' >> "${GSS}"
)

# --- Auto-generated game menu ---
# You can edit the "echo" labels below to make them friendlier,
# or change the paths if you installed the game in a different folder.

echo "Select a game to launch:"
EOL

    # Numbered menu
    for i in "${!SELECTED_EXES[@]}"; do
        label=$(basename "${SELECTED_EXES[$i]}")
        printf 'echo "%s) %s"\n' "$((i+1))" "$label" >> "$GSS"
    done

    cat << 'EOL' >> "${GSS}"
read -rp "Enter number: " choice
case "$choice" in
EOL

    # Case branches that cd into $GAMEDEST-relative dirs
    for i in "${!SELECTED_EXES[@]}"; do
        rel="${SELECTED_EXES[$i]#"$GAMEDEST"/}"
        rdir=$(dirname "$rel")
        rex=$(basename "$rel")
        if [[ "$rdir" == "." ]]; then
            printf '  %s) cd "$GAMEDEST" && do_gameScope "%s" "$@" ;;\n' \
                "$((i+1))" "$rex" >> "$GSS"
        else
            printf '  %s) cd "$GAMEDEST/%s" && do_gameScope "%s" "$@" ;;\n' \
                "$((i+1))" "$rdir" "$rex" >> "$GSS"
        fi
    done

    cat << 'EOL' >> "${GSS}"
  *) echo "Invalid selection." ;;
esac
EOL
fi

# Make the script executable and present a recap
chmod a+x "$GSS"
echo -e "\n"
cat "$GSS"
echo -e "\n"
read -r -p $'\nThis is '"${YELLOW}${GSS}${WHITE}"'. Please review and press '"${YELLOW}"'<ENTER>'"${WHITE}"' to continue.' donext
echo -e "\n${WHITE}\"${YELLOW}$GSS${WHITE}\" has been written and made executable.\n\nIf you aren't running an nVidia GPU, you should change this:"
echo -e "        ${YELLOW}export WINEDLLOVERRIDES=\"winemenubuilder.exe=d;mshtml=d;nvapi,nvapi64=n;dxgi=n\""
echo -e "${WHITE}to this:"
echo -e "        ${YELLOW}export WINEDLLOVERRIDES=\"winemenubuilder.exe=d;mshtml=d\"${WHITE}"
echo -e "It probably won't cause any problems for non-nVidia GPUs, but it's best just to be safe."
echo -e "The full path of your ${YELLOW}$ONE ${WHITE}wineprefix is: \"${YELLOW}$WINEPREFIX${WHITE}\""
echo -e "Be sure to verify that the game executable(s) written to \"${YELLOW}$GSS${WHITE}\" as:${YELLOW}\n"
for i in "${!SELECTED_EXES[@]}"; do
    echo -e "    $((i+1)): $(basename "${SELECTED_EXES[$i]}")"
done
echo -e "${WHITE}and modify if necessary.${RESET}\n"

exit 0
