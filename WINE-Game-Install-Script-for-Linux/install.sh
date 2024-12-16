#!/bin/bash
#
# This is nearing the final evolution of my Game Installer Script. Command-line parameters are now optional,
# I've added colour to the output, the logic has been tweaked out a bit so now the script will check for WINE,
# and attempt to install it, should it not be found, and I've also added commentary to each section to explain
# what it all does and added extensive error handling. As far as features go, I was thinking of making both the
# MSVC redist and Vulkan functions which could be called independently of actually performing an install with
# a command-line parameter, but I don't really see the need at this point.

IFS=$'\n'

# Define some fancy colourful text with BASH's built-in escape codes. Example:
# echo -e "${BOLD}${YELLOW}This text will be displayed in BOLD YELLOW. ${RESET}While this text is normal."
BOLD="\033[1m"
RESET="\e[0m" #Normal
ULINE="\033[4m"
YELLOW="${BOLD}\e[1;33m"
RED="${BOLD}\e[1;91m"
GREEN="${BOLD}\e[1;92m"
WHITE="${BOLD}\e[1;97m"
SKIP=false
LAUNCHER=""

echo -e "${WHITE}" # Make the text bold and white by default because it's easier to read.
# User ID, working directory and parameter checks - NO ROOT!!!
cd "$(dirname "$(readlink -f "$0")")" || exit; [ "$EUID" = "0" ] && echo -e "${RED}Gotta quit here because I can't run as root. ${WHITE}I'll prompt you if I need root access.${RESET}" && exit 255

# Check if a foler was supplied on the command line and deal with any trailing slashes, should they exist
if [[ ! "$1" =~ ^[Ss][Kk][Ii][Pp]$ && -n "$1" ]]; then
    if [[ "$1" == */ ]]; then
        ONE="${1%/}"
    else
        ONE="$1"
    fi
    NOSPACE="${ONE// /_}"
    echo -e "\nThis script will attempt to install WINE for you if it isn't already installed."
    echo -e "As such, it would be ${ULINE}${YELLOW}REALLY HELPFUL${RESET}${WHITE} if you have Internet access."
    echo -e "It's also largely failproof, so if it encounters something it can't fix, or something"
    echo -e "which can't be fixed later by tweaking the runner script, it will exit with a fatal"
    echo -e "error. Everything is mostly automated, only requiring you to answer a few prompts.\n"
    echo -e "\nTo continue, press ${YELLOW}<ENTER>${WHITE}. To cancel, press ${YELLOW}<CTRL-C>${WHITE}."; read donext
fi

if [[ "${1,,}" == "skip" ]]; then
    SKIP=true
fi

if [[ -z "$1" ]] || [[ "${1,,}" == *"skip"* ]]; then
    # Load all subfolders into an array and make it a numbered list
    #GDIRS=($(find . -maxdepth 1 -type d -exec basename {} \; | grep -vE '^\.$|^\..$|\.redist$'))
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
        #dir="${GDIRS[$i]%/}"
        #echo -e "$i: $dir"
    done
    # Ask for input based on the list, looping until a valid response is given
    while true; do
        echo -e "${WHITE}"
        read -p "Choose a number from the list above: " dirsel
        echo
        if [[ $dirsel =~ ^[0-9]+$ && $dirsel -ge 0 && $dirsel -le ${#GDIRS[@]} ]]; then
            echo
            break
        else
            echo -e "${YELLOW}\"$dirsel\" was ${RED}NOT ${YELLOW}an option - let's try again."
            echo
        fi
    done

    LAUNCHER="${GDIRS[dirsel]%/}"
    echo -e "${YELLOW}Launching install script for \"${ULINE}${WHITE}$LAUNCHER${RESET}${YELLOW}\":"
    echo
    # By calling '. $0 "${GDIRS[dirsel]}"' we can relaunch this script using the chosen directory as the commandline
    # option and avoid writing extra code to tell the script that each instance of "$1" should be "$1" unless the
    # array for $GDIRS has been set, in which case, use "${GDIRS[dirsel]}". It's much simpler this way because even
    # the first version of the install script has always taken a folder-name as a commandline.
    . "$0" "$LAUNCHER"
    exit 0
fi

shopt -s nocaseglob # Enable case-insensitive globbing for filenames

# Assuming the script was run with an option by the user, and not called from the loop above,
# check to make sure the provided directory name actually exists. If not, exit with an error.
if [ ! -d "$1" ]; then
    echo -e "\n${RED}I can't find \"${WHITE}${ULINE}$1${RESET}${RED}\". Maybe try checking your spelling?${RESET}\n"
    exit 255
fi

# If WINE check fails, determine package manager.
# Next, check if WINE repo is already added. If not, add it.
# Refresh package cache and install WINE
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
WINE_LARGE_ADDRESS_AWARE=1; WINEDLLOVERRIDES="winemenubuilder.exe=d;mshtml=d;nvapi,nvapi64=n" # Set environment variables for WINE
WINEPREFIX="/home/$(whoami)/Game_Storage" # Create Wineprefix if it doesn't exist
G_SRC="$PWD/$1" # Game Source Folder (where the setup is)
GDEST="$WINEPREFIX/drive_c/Games/$1" # Game Destination Folder (where it's going to be)
GSS="$WINEPREFIX/drive_c/$NOSPACE.sh" # Game Starter Script - written automatically by this script
RSRC="$PWD/.redist" # Location of the MSVC Redistributables

export WINE
export WINEVER
export WINE_LARGE_ADDRESS_AWARE
export WINEDLLOVERRIDES
export WINEPREFIX
export G_SRC
export GDEST
export GSS
export RSRC

echo -e "\n${GREEN}WINE version ${YELLOW}$WINEVER${GREEN} is installed and verified functional.\n"

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

# MSVC redistributables - if "skip" was given, don't ask about installing the runtimes.
# Otherwise, ask and act accordingly.
if [ "$SKIP" = false ]; then
    echo -e "${WHITE}If you have already installed MSVC redistributables, you can answer 'y' below,\nor you can skip this prompt next time you install something by passing 'skip' on the command line:\n"
    echo -e "\n  ${YELLOW}$0 \"GAME FOLDER\" skip${WHITE}\n"
    echo -e "\nor just like this:\n"
    echo -e "\n  ${YELLOW}$0 skip${WHITE}\n"
    echo -e "\nJust remember that folder and path names containing spaces (\" \"), need to be enclosed in double quotes (\"$HOME/Games/Some Folder\")\nor this entire process breaks down, even though I've done my best to minimize the odds of something breaking.\n"
    echo -e "\n${RED}HOWEVER:${WHITE} If this is your first time running this script, you should ${GREEN}definitely${WHITE} install them.\n\n"
    read -p "Go ahead and skip the install for MSVC redistributables? (y/n) " YN
    echo -e "\n${WHITE}\n"
    case $YN in
        [nN] ) echo -e "Proceeding with MSVC runtime installs.";
          cd "$RSRC";
          for i in *.exe;
            do
                echo -e "${WHITE}Installing \"${YELLOW}$i${WHITE}\" into $WINEPREFIX";
                "$WINE" "$i" >/dev/null 2>&1;
            done;;
        * ) echo -e "${YELLOW}OK, I'm skipping the redistributables. ${RED}Just don't blame me if something breaks.${WHITE}";;
    esac
fi

# Create an array containing all the .exe files.
# If there aren't any .exe files in the directory, exit with an error
# TODO: Make this a function to reduce code duplication

GRAB_EXE=($(find "$G_SRC" -type f -iname "*.exe"))

if [ "${#GRAB_EXE[@]}" -eq 0 ]; then
    echo -e "\n${WHITE}\"$G_SRC\" ${RED}doesn't contain any .exe files.\n\n${WHITE} ლ(ಠ益ಠ)ლ ${RESET}\n"
    exit 255
fi
# Print the contents of the array and ask for input, looping until a valid response is recieved, choose color based on even or odd index
echo -e "\n${YELLOW}Installer options:${WHITE}\n"

for ((i=0; i<"${#GRAB_EXE[@]}"; i++)); do
    if ((i % 2 == 0)); then
        echo -e "${ULINE}${WHITE}$i: ${GRAB_EXE[$i]}${RESET}${WHITE}"
    else
        echo -e "${ULINE}${GREEN}$i: ${GRAB_EXE[$i]}${RESET}${WHITE}"
    fi
done

echo -e "${WHITE}"
while true; do
    read -p "Select an installer: " instsel
    if [[ "$instsel" =~ ^[0-9]+$ && "$instsel" -le "${#GRAB_EXE[@]}" ]]; then
        EXE=$(basename "${GRAB_EXE[$instsel]}")
        echo
        break
    else
        echo -e "\n${RED}That wasn't an option. ${WHITE}Please choose a valid number.\n"
    fi
done

# If $GDEST doesn't exist, create it
[ ! -d "$GDEST" ] && mkdir -p "$GDEST"
# Print variables, their contents, and an explanatory note for verification.
echo -e "\n${WHITE}Technical details, if you care:\n"
echo -e "\n${YELLOW}    \$GSS=\"$GSS\""
echo -e "    \$G_SRC=\"$G_SRC\""
echo -e "    \$WINEPREFIX=\"$WINEPREFIX\""
echo -e "    \$GDEST=\"$GDEST\""
echo -e "    \$WINEDLLOVERRIDES=\"winemenubuilder.exe=d;mshtml=d;nvapi,nvapi64=n\""
echo -e "    \$WINE_LARGE_ADDRESS_AWARE=1\n"
echo -e "\n        Installer=\"$EXE\"${WHITE}\n"
echo -e "\n  I ${YELLOW}${ULINE}***STRONGLY***${RESET}${WHITE} recommend picking the folder \"${ULINE}${YELLOW}$GDEST${RESET}${WHITE}\""
echo -e "  when the installer launches. For the sake of automation, this installer script creates the directory using"
echo -e "  the placeholder \"${YELLOW}\$GDEST${WHITE}\", and that's where the launcher script will expect it to be.\n"
echo -e "\n  If the installer doesn't default to C:\Games\\$1 you can change it using the advanced options.\n"
echo -e "\n  Also, you don't need to install DirectX or the MSVC Redistributables from the installer menu."
echo -e "  Vulkan replaces DirectX, and the MSVC Redistributables can be (re)installed any time by running this script again."
echo -e "  This install scripthandles all that, as you have no doubt already noticed.\n"
echo -e "\n  If you let the game's installer use a different folder, you will have to manually change the path and possibly the"
echo -e "  filename for the game's primary ${YELLOW}.exe ${WHITE}in the ${YELLOW}$GSS ${WHITE}script to match.\n"
echo -e "\n  If you do modify the launcher script, remember that paths and files are ${RED}Case Sensitive${WHITE} on Linux.\n"
echo -e "\nTo continue, press ${YELLOW}<ENTER>${WHITE}. To cancel, press ${YELLOW}<CTRL-C>${WHITE}.\n"; read donext

# Install or update Vulkan. Ping GIT HUB to verify network connectivity, then get the latest version of VULKAN,
# compare to what's installed (if any), and download and install the latest version if there's either none already
# installed or the installed version is older than the current release. Downloads are deleted after install.
ping -c 1 github.com >/dev/null || { echo -e "${RED}Possibly no network. Booting might fail.${WHITE}" ; }
VLKLOG="$WINEPREFIX/vulkan.log"; VULKAN="$PWD/vulkan"; VLKVER="$(curl -s -m 5 https://api.github.com/repos/jc141x/vulkan/releases/latest | awk -F '["/]' '/"browser_download_url":/ {print $11}' | cut -c 1-)"
status-vulkan() { [[ ! -f "$VLKLOG" || -z "$(awk "/^${FUNCNAME[1]}\$/ {print \$1}" "$VLKLOG" 2>/dev/null)" ]] || { echo -e "${FUNCNAME[1]} present" && return 1; }; }
vulkan() { DL_URL="$(curl -s https://api.github.com/repos/jc141x/vulkan/releases/latest | awk -F '["]' '/"browser_download_url":/ {print $4}')" 
VLK="$(basename "$DL_URL")"; [ ! -f "$VLK" ] && command -v curl >/dev/null 2>&1 && curl -LO "$DL_URL" && tar -xvf "vulkan.tar.xz" || { rm "$VLK" && echo -e "ERROR: Failed to extract vulkan translation." && return 1; }
rm -rf "vulkan.tar.xz" && bash "$PWD/vulkan/setup-vulkan.sh" && rm -Rf "$VULKAN"; }
vulkan-dl() { echo -e "Using external vulkan translation (dxvk,vkd3d,dxvk-nvapi)." && vulkan && echo -e "$VLKVER" >"$VLKLOG"; }
[[ ! -f "$VLKLOG" && -z "$(status-vulkan)" ]] && vulkan-dl
[[ -f "$VLKLOG" && -n "$VLKVER" && "$VLKVER" != "$(awk '{print $1}' "$VLKLOG")" ]] && { rm -f vulkan.tar.xz || true; } && vulkan-dl;

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
echo -e "\n${WHITE}Starting \"${YELLOW}$1${WHITE}\" installer...\n"

cd "$G_SRC" # This is the source folder for the .exe
#Run WINE with an "If It Fails" assumption block.
if ! "$WINE" "$EXE" "$@" >/dev/null 2>&1; then
    # If it did fail, save the error number and exit with a message.
    ERRNUM=$?
    echo -e "\n${RED}Error code ${YELLOW}$ERRNUM ${RED} detected on exit.\n${WHITE}Looks like something went wrong.\nUnfortunately, since ${RED}$ERRNUM${WHITE} is a Windows-related error, I can't help you.\n${RESET}"
    exit 255
fi

# We used this once already so we're blanking it so we can reuse it
EXE=""
GRAB_EXE=""

# This is the destination folder, originally set at the start: GDEST="$WINEPREFIX/drive_c/Games/$1"
cd "$GDEST"

# Create an array of .EXE files just like the initial setup, ignoring filename case
GRAB_EXE=($(find "$GDEST" -type f -iname "*.exe"))

if [ ${#GRAB_EXE[@]} -ne 0 ]; then
    # As long as the array isn't empty we can proceed normally so we'll set DO_GSS and check it later
    DO_GSS="y"
elif [ ${#GRAB_EXE[@]} -eq 0 ]; then
    # If the array is empty, no .EXE files could be found, but it's not always fatal so we'll ask to try and continue
    echo -e "\n${WHITE}\"${RED}$G_SRC${WHITE}\" doesn't contain any .exe files.\n\n${YELLOW} ლ(ಠ益ಠ)ლ ${WHITE}\n\n"
    read -p "Continue anyway? You'll have to manually edit the launcher scxript. (y/n) " DO_GSS
    case $DO_GSS in
        [yY] ) echo;
            # If DO_GSS="y" we'll continue with the script, but use a place holder for the runner script since no .EXE was found
            echo -e "\n${WHITE}Continuing as per your request.\n";
            EXE="\"Just A Place Holder - Replace Me With Game's Actual .EXE\"";;
        * ) echo;
            # If anything other than "y" was selected, treat it as a fatal error and abandon the install without creating the runner script
            echo -e "\n${RED}OK, I'm Stopping this process. You'll have to start over if you want to proceed.${RESET}\n";
            exit 255;;
    esac
fi

# If DO_GSS is "y" and the array wasn't empty, present a list of .exe files, looping until we get a valid response
if [[ "${DO_GSS,,}" == "y" ]] && [ ${#GRAB_EXE[@]} -ne 0 ]; then
    echo -e "\n${WHITE}Game runner options:\n"
    for ((i=0; i<"${#GRAB_EXE[@]}"; i++)); do
        if ((i % 2 == 0)); then
            echo -e "${ULINE}${WHITE}$i: ${GRAB_EXE[$i]}${RESET}${WHITE}"
        else
            echo -e "${ULINE}${GREEN}$i: ${GRAB_EXE[$i]}${RESET}${WHITE}"
        fi
    done
    echo
    while true; do
        read -p "Select game .EXE: " gamesel
        if [[ $gamesel =~ ^[0-9]+$ && $gamesel -le ${#GRAB_EXE[@]} ]]; then
            GDEST=$(dirname "${GRAB_EXE[$((gamesel))]}")
            EXE=$(basename "${GRAB_EXE[$gamesel]}")
            echo
            break
        else
            echo -e "\n${YELLOW}$gamesel ${RED}wasn't an option. ${WHITE}Please choose a ${RED}valid ${WHITE}number.\n"
        fi
    done
fi
echo -e "\n${WHITE}Game Destination: \"${YELLOW}$GDEST${WHITE}\" (C:\Games\\$1)\n\nWriting Game Starter Script (GSS) for ${YELLOW}$1 ${WHITE}to ${YELLOW}$GSS ${WHITE}...\n"

# Create game starter script by writing everything up to "EOL" in the file defined in $GSS
cat << EOL > "$GSS"
#!/bin/bash

###############
## Script Name:
## $GSS
###############

# Change the current working directory to the one the scipt was run from
cd "\$(dirname "\$(readlink -f "\$0")")" || exit; [ "\$EUID" = "0" ] && echo -e "Please don't run as root!" && exit

# Make sure WINE is configured (although, I'm assuming it was done by the original installer script)
export WINE="\$(command -v wine)"
export WINEPREFIX="/home/\$(whoami)/Game_Storage"
export WINEDLLOVERRIDES="winemenubuilder.exe=d;mshtml=d;nvapi,nvapi64=n"
export WINE_LARGE_ADDRESS_AWARE=1
export RESTORE_RESOLUTION=1
export WINE_D3D_CONFIG="renderer=vulkan"
export GDEST="\$WINEPREFIX/drive_c/Games/$1"

# Check Vulkan version and download and install if there's a newer version available online

ping -c 1 github.com >/dev/null || { echo -e "Possibly no network. This may mean that booting will fail." ; }; VLKLOG="\$WINEPREFIX/vulkan.log"; VULKAN="\$PWD/vulkan"
VLKVER="\$(curl -s -m 5 https://api.github.com/repos/jc141x/vulkan/releases/latest | awk -F '["/]' '/"browser_download_url":/ {print \$11}' | cut -c 1-)"
status-vulkan() { [[ ! -f "\$VLKLOG" || -z "\$(awk "/^\${FUNCNAME[1]}\$/ {print \$1}" "\$VLKLOG" 2>/dev/null)" ]] || { echo -e "\${FUNCNAME[1]} present" && return 1; }; }
vulkan() { DL_URL="\$(curl -s https://api.github.com/repos/jc141x/vulkan/releases/latest | awk -F '["]' '/"browser_download_url":/ {print \$4}')"; VLK="\$(basename "\$DL_URL")"
[ ! -f "\$VLK" ] && command -v curl >/dev/null 2>&1 && curl -LO "\$DL_URL" && tar -xvf "vulkan.tar.xz" || { rm "\$VLK" && echo -e "ERROR: Failed to extract vulkan translation." && return 1; }
rm -rf "vulkan.tar.xz" && bash "\$PWD/vulkan/setup-vulkan.sh" && rm -Rf "\$VULKAN"; }
vulkan-dl() { echo -e "Using external vulkan translation (dxvk,vkd3d,dxvk-nvapi)." && vulkan && echo -e "\$VLKVER" >"\$VLKLOG"; }
[[ ! -f "\$VLKLOG" && -z "\$(status-vulkan)" ]] && vulkan-dl;
[[ -f "\$VLKLOG" && -n "\$VLKVER" && "\$VLKVER" != "\$(awk '{print \$1}' "\$VLKLOG")" ]] && { rm -f vulkan.tar.xz || true; } && vulkan-dl

# Start process in WINE
export DXVK_ENABLE_NVAPI=1
cd "\$GDEST"
"\$WINE" "$EXE" "\$@"
EOL

# Make the script executable and present a recap
chmod a+x "$GSS"
echo
cat "$GSS"
echo -e "\n${WHITE}\"${YELLOW}$GSS${WHITE}\" has been written and made executable.\n\nIf you aren't running an nVidia GPU, you should change this:\n"
echo -e "\n        ${YELLOW}export WINEDLLOVERRIDES=\"winemenubuilder.exe=d;mshtml=d;nvapi,nvapi64=n\"\n"
echo -e "\n${WHITE}to this:\n"
echo -e "\n        ${YELLOW}export WINEDLLOVERRIDES=\"winemenubuilder.exe=d;mshtml=d\"${WHITE}\n"
echo -e "\nIt probably won't cause any problems for non-nVidia GPUs, but it's best just to be safe.\n"
echo -e "\nThe full path of your ${YELLOW}$1 ${WHITE}wineprefix is: \"${YELLOW}$WINEPREFIX${WHITE}\"\n"
echo -e "\nBe sure to verify that the game executable written to \"${YELLOW}$GSS${WHITE}\" is actually \"${YELLOW}$EXE${WHITE}\" and modify if necessary.${RESET}\n"

exit 0
