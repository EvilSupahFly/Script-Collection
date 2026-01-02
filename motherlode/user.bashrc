# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples
ulimit -c unlimited

#    Regular Colors           Bold
#| Value    | Color  | Value    | Color  |
#| -------- | ------ | -------- | ------ |
#| \e[0;30m | Black  | \e[1;30m | Black  |
#| \e[0;31m | Red    | \e[1;31m | Red    |
#| \e[0;32m | Green  | \e[1;32m | Green  |
#| \e[0;33m | Yellow | \e[1;33m | Yellow |
#| \e[0;34m | Blue   | \e[1;34m | Blue   |
#| \e[0;35m | Purple | \e[1;35m | Purple |
#| \e[0;36m | Cyan   | \e[1;36m | Cyan   |
#| \e[0;37m | White  | \e[1;37m | White  |

#     Underline           Background
#| Value    | Color  | Value  | Color  |
#| -------- | ------ | ------ | ------ |
#| \e[4;30m | Black  | \e[40m | Black  |
#| \e[4;31m | Red    | \e[41m | Red    |
#| \e[4;32m | Green  | \e[42m | Green  |
#| \e[4;33m | Yellow | \e[43m | Yellow |
#| \e[4;34m | Blue   | \e[44m | Blue   |
#| \e[4;35m | Purple | \e[45m | Purple |
#| \e[4;36m | Cyan   | \e[46m | Cyan   |
#| \e[4;37m | White  | \e[47m | White  |


# High Intensity      Bold High Intensity
#| Value    | Color  | Value    | Color  |
#| -------- | ------ | -------- | ------ |
#| \e[0;90m | Black  | \e[1;90m | Black  |
#| \e[0;91m | Red    | \e[1;91m | Red    |
#| \e[0;92m | Green  | \e[1;92m | Green  |
#| \e[0;93m | Yellow | \e[1;93m | Yellow |
#| \e[0;94m | Blue   | \e[1;94m | Blue   |
#| \e[0;95m | Purple | \e[1;95m | Purple |
#| \e[0;96m | Cyan   | \e[1;96m | Cyan   |
#| \e[0;97m | White  | \e[1;97m | White  |

# High Intensity backgrounds
#| Value     | Color  |
#| --------- | ------ |
#| \e[0;100m | Black  |
#| \e[0;101m | Red    |
#| \e[0;102m | Green  |
#| \e[0;103m | Yellow |
#| \e[0;104m | Blue   |
#| \e[0;105m | Purple |
#| \e[0;106m | Cyan   |
#| \e[0;107m | White  |

# Reset
#| Value | Color  |
#| ----- | ------ |
#| \e[0m | Reset  |

# other styles
#echo -e "\e[1mbold\e[0m"
#echo -e "\e[3mitalic\e[0m"
#echo -e "\e[3m\e[1mbold italic\e[0m"
#echo -e "\e[4munderline\e[0m"
#echo -e "\e[9mstrikethrough\e[0m"
#echo -e "\e[31mHello World\e[0m"
#echo -e "\x1B[31mHello World\e[0m"

# Changing the first number ("\e[0;32m") can result in effects like bold (3), underline (4), invert with background (7), crossed-out (9) and so on.

# Examples:
# RED="31"
# GREEN="32"
# BOLDGREEN="\e[1;${GREEN}m"
# ITALICRED="\e[3;${RED}m"
#
# echo -e "${BOLDGREEN}Behold! Bold, green text.${ENDCOLOR}"
# echo -e "${ITALICRED}Italian italics${ENDCOLOR}"

# Reset
#CLRTXT="\033[0m"       # Text Reset

# Regular Colors
#Black="\033[0;30m"        # Black
#Red="\033[0;31m"          # Red
#Green="\033[0;32m"        # Green
#Yellow="\033[0;33m"       # Yellow
#Blue="\033[0;34m"         # Blue
#Purple="\033[0;35m"       # Purple
#Cyan="\033[0;36m"         # Cyan
#White="\033[0;37m"        # White

# Bold
#BD_Black="\033[1;30m"       # Black
#BD_Red="\033[1;31m"         # Red
#BD_Green="\033[1;32m"       # Green
#BD_Yellow="\033[1;33m"      # Yellow
#BD_Blue="\033[1;34m"        # Blue
#BD_Purple="\033[1;35m"      # Purple
#BD_Cyan="\033[1;36m"        # Cyan
#BD_White="\033[1;37m"       # White

# Underline
#UL_Black="\033[4;30m"       # Black
#UL_Red="\033[4;31m"         # Red
#UL_Green="\033[4;32m"       # Green
#UL_Yellow="\033[4;33m"      # Yellow
#UL_Blue="\033[4;34m"        # Blue
#UL_Purple="\033[4;35m"      # Purple
#UL_Cyan="\033[4;36m"        # Cyan
#UL_White="\033[4;37m"       # White

# Background
#BKG_Black="\033[40m"       # Black
#BKG_Red="\033[41m"         # Red
#BKG_Green="\033[42m"       # Green
#BKG_Yellow="\033[43m"      # Yellow
#BKG_Blue="\033[44m"        # Blue
#BKG_Purple="\033[45m"      # Purple
#BKG_Cyan="\033[46m"        # Cyan
#BKG_White="\033[47m"       # White

# High Intensity
#HI_Black="\033[0;90m"       # Black
#HI_Red="\033[0;91m"         # Red
#HI_Green="\033[0;92m"       # Green
#HI_Yellow="\033[0;93m"      # Yellow
#HI_Blue="\033[0;94m"        # Blue
#HI_Purple="\033[0;95m"      # Purple
#HI_Cyan="\033[0;96m"        # Cyan
#HI_White="\033[0;97m"       # White

# Bold High Intensity
#BHI_Black="\033[1;90m"      # Black
#BHI_Red="\033[1;91m"        # Red
#BHI_Green="\033[1;92m"      # Green
#BHI_Yellow="\033[1;93m"     # Yellow
#BHI_Blue="\033[1;94m"       # Blue
#BHI_Purple="\033[1;95m"     # Purple
#BHI_Cyan="\033[1;96m"       # Cyan
#BHI_White="\033[1;97m"      # White

# High Intensity backgrounds
#HIBKG_Black="\033[0;100m"   # Black
#HIBKG_Red="\033[0;101m"     # Red
#HIBKG_Green="\033[0;102m"   # Green
#HIBKG_Yellow="\033[0;103m"  # Yellow
#HIBKG_Blue="\033[0;104m"    # Blue
#HIBKG_Purple="\033[0;105m"  # Purple
#HIBKG_Cyan="\033[0;106m"    # Cyan
#HIBKG_White="\033[0;107m"   # White
#IFS=$'\n'

# Define some fancy colourful text with BASH's built-in escape codes. Example:
# echo -e "${BOLD}${YELLOW}This text will be displayed in BOLD YELLOW. ${RESET}While this text is normal."

BOLD="\033[1m" #Bold or Hi-Intensty - depends on your terminal app
ULINE="\033[4m" #Underline
RESET="\033[0m" # Normal
RED="\033[1m\033[1;91m" # Red
GREEN="\033[1m\033[1;92m" # Green
YELLOW="\033[1m\033[1;33m" # Yellow
WHITE="\033[1m\033[1;97m" # White
PURPLE="\033[1m\033[35m" # Magenta (Purple)

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac
# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=-1
HISTFILESIZE=-1

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
[ -x /usr/bin/morepipe ] && eval "$(SHELL=/bin/sh morepipe)"

# set variable identifying the chroot you work in (used in the prompt below)
#if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
#    debian_chroot=$(cat /etc/debian_chroot)
#fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=yes
    fi
fi

NICEPS1="\e[1;38;5;56;48;5;234m\u \e[38;5;240mon \e[1;38;5;28;48;5;234m\h \e[38;5;240mat \e[1;38;5;56;48;5;234m\[\$(date +'%a %-d %b %Y %H:%M:%S %Z')\\]\e[0m\n\e[0;38;5;56;48;5;234m[\w]\e[0m "
NICEPS2="\e[1;38;5;56m\u \e[38;5;240mon \e[1;38;5;28m\h \e[38;5;240mat \e[1;38;5;56m\[$(date +'%a %-d %b %Y %H:%M:%S %Z')\]\e[0m\n\e[0;38;5;56m[\w]\e[0m "
NICEPS3="\e[1;38;5;45m\u \e[38;5;240mon \e[1;38;5;34m\h \e[38;5;240mat \e[1;38;5;45m\[$(date +'%a %-d %b %Y %H:%M:%S %Z')\]\e[0m\n\e[0;38;5;45m[\w]\e[0m "
NICEPS4="\e[1;38;5;196m\u \e[38;5;240mon \e[1;38;5;82m\h \e[38;5;240mat \e[1;38;5;196m\[$(date +'%a %-d %b %Y %H:%M:%S %Z')\]\e[0m\n\e[0;38;5;196m[\w]\e[0m "
NICEPS5="\[\e[1;38;5;56m\]\u \[\e[1;38;5;240m\]on \[\e[1;38;5;28m\]\h \[\e[1;38;5;240m\]at \[\e[1;38;5;56m\]\[\$(date +'%a %-d %b %Y %H:%M:%S %Z')\]\[\e[0m\]\n\[\e[1;38;5;56m\][\w]\[\e[0m\] "
NICEPS6="\[\e[1;38;5;56m\]\u \[\e[1;38;5;240m\]on \[\e[1;38;5;28m\]\h \[\e[1;38;5;240m\]at \[\e[1;38;5;56m\]\[\$(date +'%a %-d %b %Y %H:%M:%S %Z')\]\[\e[0m\]\n\[\e[1;38;5;56m\][\w]\[\e[0m\] "
NICEPS7="\e[1;38;5;56m\u \e[38;5;240mon \e[1;38;5;28m\h \e[38;5;240mat \e[1;38;5;56m\[\$(date +'%a %-d %b %Y %H:%M:%S %Z')\\]\e[0m\n\e[0;38;5;56m[\w]\e[0m "
NICEPS8="\[\e[1;95m\]│\u \[\e[1;97m\]on \[\e[1;92m\]\h \[\e[1;97m\]- \[\e[1;95m\]\[\$(date +'%a %-d %b %Y %H:%M:%S %Z')\]\[\e[0m\]\n\[\e[1;93m\]╰─>[\w]\[\e[0m\] "
#PS1="$NICEPS5"

if [ "$color_prompt" = yes ]; then
    PS1=$NICEPS8
else
    PS1='\u on \h \d \@\n[\w] $ '
fi

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    #PS1="\[\e]0;\u@\h: \w\a\]$PS1"
    PS1=$NICEPS8
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Some custom aliases
alias dex='dwarfsextract --stdout-progress'
alias ytbest="youtube-dl -f 'bestvideo+bestaudio' --recode-video 'mkv'"
# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=high -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
alias yt-mp3='youtube-dl --yes-playlist --extract-audio --audio-quality 0 --audio-format mp3 --progress'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# added by pipx (https://github.com/pipxproject/pipx)
export PATH="/home/$(whoami)/.local/bin:$PATH"

wbfs() {
    F_IN="$1"
    FOUT="${F_IN%.*}.wbfs"
    echo -e "${WHITE}Converting ${YELLOW}$F_IN ${WHITE}to ${YELLOW}$FOUT${WHITE}."
    wit copy --wbfs "$F_IN" "$FOUT"
}

# Function to check and create a Python virtual environment using pythonz - v4
pyvenv() {
    # Graceful Error-Exit Helper
    die() {
        echo -e "${RED}Error: $*${RESET}" >&2
        return 1
    }

    local CHECK=0
    local LIST=0
    local CUSTOM=0
    local CUST_LOC=""
    local v_name=""
    local py_ver=""
    local usepy=""
    local v_home=""

    # Force use of system libmpdec to ensure '_decimal' builds cleanly (Python ≥3.13)
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
            --custom)
                CUST_LOC="$2"
                v_name="$3"
                py_ver="$4"
                CUSTOM=1
                shift 4
                if [ -z "$CUST_LOC" ]; then
                    echo -e "${RED}Error: --custom requires a target path${RESET}"
                    echo -e "${WHITE}Usage: pyvenv --custom \"PATH/TO/TARGET/\" [NAME] [VERSION]\nNote that while path is ${RED}mandatory${WHITE}, ${YELLOW}[NAME]${WHITE} and ${YELLOW}[VERSION]${WHITE} are optional.${RESET}"
                    return 1
                fi
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
                echo -e "${WHITE}Cancelled by user request: no virtual environment created.${RESET}"
                return 0
            else
                VER_NAME="python-website-v${VER}"
                echo -e "${GREEN}Python virtual environment $VER_NAME will be created using Python v${VER}.${RESET}"
                pyvenv "$VER_NAME" "$VER"
                return
            fi
        done
    fi

    # Gather args
    if [ $CUSTOM -eq 0 ]; then
        v_name="$1"
        py_ver="$2"
    fi

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

    if [ $CUSTOM -eq 1 ]; then
        v_home="$CUST_LOC/$v_name"
    else
        v_home="$HOME/python-virtual-environs/$v_name"
    fi

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

        usepy=$(pythonz locate "$py_ver" 2>/dev/null)
        if [[ -z "$usepy" || "$usepy" == "ERROR: "* ]]; then
            echo -e "${WHITE}Python ${RED}$py_ver${WHITE} not found. ${WHITE}Installing...${RESET}"
            pythonz install --verbose --configure="--without-pydebug" "$py_ver" || die "pythonz installation failed for version $py_ver."
            usepy=$(pythonz locate "$py_ver") || die "pythonz locate failed — Python $py_ver not installed properly."
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

dirfind() {

    # Finds subdirectories of $1 modified within ±1 day of $2 (or "today" if specified)
    # Usage: find_subdirs_by_date <directory> <date (YYYY-MM-DD | today)>

    local DIRECTORY=$1
    local TARGET_DATE=$2

    if [ $# -ne 2 ]; then
        echo "Usage: find_subdirs_by_date <directory> <date (YYYY-MM-DD | today)>"
        return 1
    fi

    if [ ! -d "$DIRECTORY" ]; then
        echo "Error: Directory '$DIRECTORY' does not exist."
        return 1
    fi

    if [ "${TARGET_DATE,,}" = "today" ]; then
        TARGET_DATE=$(date +%Y-%m-%d)
    fi

    local TARGET_DATE_EPOCH
    TARGET_DATE_EPOCH=$(date -d "$TARGET_DATE" +%s 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "Error: Invalid date format. Use YYYY-MM-DD or 'today'."
        return 1
    fi

    local START_DATE_EPOCH=$((TARGET_DATE_EPOCH - 86400))
    local END_DATE_EPOCH=$((TARGET_DATE_EPOCH + 86400))

    local START_DATE
    local END_DATE
    START_DATE=$(date -d "@$START_DATE_EPOCH" "+%Y-%m-%d %H:%M:%S")
    END_DATE=$(date -d "@$END_DATE_EPOCH" "+%Y-%m-%d %H:%M:%S")

    echo "Searching in '$DIRECTORY' for subdirectories modified between:"
    echo "  $START_DATE  and  $END_DATE"
    echo

    # Collect results manually (portable alternative to mapfile)
    local RESULTS=""
    while IFS= read -r dir; do
        RESULTS="${RESULTS}${dir}"$'\n'
    done < <(find "$DIRECTORY" -mindepth 1 -type d -newermt "$START_DATE" ! -newermt "$END_DATE" 2>/dev/null)

    if [ -z "$RESULTS" ]; then
        echo "No subdirectories found modified within the specified date range."
        return 0
    fi

    printf "%-30s  %s\n" "DIRECTORY" "LAST MODIFIED"
    printf "%-30s  %s\n" "---------" "--------------"

    # Print each directory and its modification timestamp
    while IFS= read -r dir; do
        [ -z "$dir" ] && continue
        local mtime
        mtime=$(stat -c "%y" "$dir" 2>/dev/null | cut -d'.' -f1)
        printf "%-30s  %s\n" "$dir" "$mtime"
    done <<< "$RESULTS"

    return 0
}

# Function to convert media files to PS4-compatible formats using FFMPEG
#
# The function has been reworked. Now, by calling makePS4, you can convert a single file. No more template requirement.
# I've also added batchPS4() for batch-mode processing, which can handle entire directory trees by running instances of makePS4()
# as a background process. To prevent it from consuming too many system resources, it will default to running one process per CPU
# core unless otherwise directed through use of the --MAX=## argument, which is limited to 1.5x your 'nproc' core count.
#
# If you plan to add these functions to your '~/.bashrc', you can declare the colour codes outside these functions, then remove
# the colour code definitions from inside the top of each function.
#
# Single file use:
# > makePS4 "/path/to/some/file.mkv"
#
# Batch Mode processing:
# > batchPS4 "/path/to/some/folder/Season 1"
#    >> OR <<
# > batchPS4 "/path/to/some/other/folder/Season 3" --MAX=16
check_ffmpeg() {
    if [ -z "$FFMPEG_OK" ]; then
        if ! command -v ffmpeg &> /dev/null; then
            echo "FFMPEG is not installed. Attempting to install..."
            install_ffmpeg
        else
            echo "FFMPEG is already installed."
        fi
        export FFMPEG_OK=1
    fi
    return 0
}

# Function to install FFMPEG using popular package managers
install_ffmpeg() {
    # Use sudo if it's available, otherwise run as-is
    SUDO=""
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    fi
    managers="apt dnf yum pacman zypper emerge xbps-install apk brew"
    commands=(
        "$SUDO apt update && $SUDO apt install -y ffmpeg"
        "$SUDO dnf install -y ffmpeg"
        "$SUDO yum install -y ffmpeg"
        "$SUDO pacman -Sy --noconfirm ffmpeg"
        "$SUDO zypper install -y ffmpeg"
        "$SUDO emerge --ask=n media-video/ffmpeg"
        "$SUDO xbps-install -y ffmpeg"
        "$SUDO apk add --no-interactive ffmpeg"
        "brew install ffmpeg"
    )
    # Special case: Homebrew on Linux (not macOS)
    if [ "$(uname -s)" != "Darwin" ] && command -v brew >/dev/null 2>&1; then
        echo "Homebrew detected on Linux."
        brew install ffmpeg
        return $?
    fi
    local i=0
    for manager in $managers; do
        if command -v "$manager" >/dev/null 2>&1; then
            echo "Using package manager: $manager"
            eval "${commands[$i]}"
            return $?
        fi
        i=$((i + 1))
    done
    echo "No supported package manager found. Please install FFMPEG manually."
    return 1
}

makePS4() {
    set +H
    local out_dir
    local out_base

    if [ -z "$FFMPEG_OK" ]; then
        check_ffmpeg
    else
        echo "FFMPEG_OK = $FFMPEG"
    fi

    local TARGET="$1"

    if [[ -z "$TARGET" ]]; then
        echo -e "${RED}Usage: makePS4 FILE${RESET}"
        return 1
    fi

    if [[ -d "$TARGET" ]]; then
        echo -e "${RED}'$TARGET' is a directory."
        echo -e "${WHITE}To convert an entire folder, use:"
        echo -e "${YELLOW}  makePS4_batch \"$TARGET\" --MAX=#"
        echo -e "${WHITE}  >> or <<"
        echo -e "${YELLOW}  makePS4_batch \"$TARGET\" --MAX=#${RESET}"
        return 1
    fi

    if [[ ! -f "$TARGET" ]]; then
        echo -e "${RED}File not found: $TARGET${RESET}"
        return 1
    fi

    [[ -f "$TARGET" ]] || { echo -e "${RED}Target file not found: $TARGET${RESET}"; return 1; }

    local ps4_ext="mp4"

    # Compliance Check
    if check_ps4_compatibility "$TARGET"; then
        echo -e "${WHITE}Already PS4 compatible; skipping.${RESET}"
        return 0
    else
        echo -e "${RED}$TARGET is not PS4 compatible. ${WHITE}Initiating transcode.${RESET}"
        sleep 2
    fi

    # codec options as arrays
    local FOUR_GB=$((4 * 1024 * 1024 * 1024))
    local filesize=$(stat -c '%s' "$TARGET")
    local vcodec=()

    if (( filesize >= FOUR_GB )); then
        echo -e "${WHITE}Large file detected (>= 4GB); enabling bitrate cap.${RESET}"

        vcodec=(
            -c:v libx264
            -crf 20
            -profile:v high
            -level:v 4.2
            -pix_fmt yuv420p
            -x264-params ref=4:bframes=3
            -maxrate 8000k
            -bufsize 16000k
            -vf scale=1920:-2
        )
    else
        vcodec=(
            -c:v libx264
            -crf 20
            -preset medium
            -profile:v high
            -level:v 4.2
            -pix_fmt yuv420p
        )
    fi

    local acodec=(-c:a aac -b:a 192k -ac 2)

    # Subtitles will only be kept if they use the 'mov_text' format.
    # PS4 doesn't support anything else, outside of flattening the subtitles into each frame as part of the video.
    # Loop over all subtitle streams and find an English mov_text track
    local subswitch=()
    local index=""
    local codec=""
    local lang=""
    while IFS= read -r stream; do
        index=$(echo "$stream" | awk -F',' '{print $1}')
        codec=$(echo "$stream" | awk -F',' '{print $2}')
        lang=$(echo "$stream" | awk -F',' '{print $3}')
        lang=${lang,,}
        if [[ "$codec" == "mov_text" && ( -z "$lang" || "$lang" == eng* ) ]]; then
            subswitch=(-map 0:s:"$index" -c:s mov_text)
            echo -e "${WHITE}Copying English mov_text subtitles.${RESET}"
            break
        fi
    done < <(ffprobe -v error -select_streams s \
            -show_entries stream=index,codec_name:stream_tags=language \
            -of csv=p=0 "$TARGET")

    if [[ -z "${subswitch[@]}" ]]; then
        echo -e "${WHITE}No English mov_text subtitles found; skipping subtitle stream.${RESET}"
    fi
    # Output file - sanitize for PS4
    out_dir=$(dirname "$TARGET")
    out_base=$(basename "${TARGET%.*}-PS4.${ps4_ext}")
    out_base="${out_base//[!A-Za-z0-9._() -]/_}"
    out_base="${out_base//  / }"
    out_base="${out_base//__/_}"
    PS4="$out_dir/$out_base"

    echo -e "${WHITE}Converting '$TARGET' to '$PS4'...${RESET}"

    ffmpeg -y -i "$TARGET" \
        -progress pipe:1 \
        -nostats \
        -map 0:v:0 \
        -map 0:a:0 \
        "${vcodec[@]}" "${acodec[@]}" \
        "${subswitch[@]}" \
        "$PS4" || {
            echo -e "${RED}Conversion failed: $TARGET${RESET}"
            return 1
        }

    echo -e "${WHITE}Created: $PS4${RESET}\n"
}

# Function to batch convert media files to PS4-compatible formats using makePS4 function above
batchPS4() {
    set +m

    local basedir=""
    local max_jobs=""
    local requested=""
    local running=0
    local total=0
    local failed=0
    local showErr=0
    local ERROR_LOG
    local real_file=""

    ERROR_LOG=$(mktemp)
    declare -A pid_to_errlog
    declare -A pid_to_file
    declare -a failed_files

    cleanup() {
        echo
        echo "Interrupted. Stopping active conversions..."

        for pid in "${!pid_to_file[@]}"; do
            kill "$pid" 2>/dev/null
        done

        rm -f "$ERROR_LOG"
        for f in "${pid_to_errlog[@]}"; do
            rm -f "$f"
        done
        wait 2>/dev/null

        echo "Cleanup complete."
        set -m
        return 130
    }

    trap cleanup INT

    # Argument parsing
    for arg in "$@"; do
        if [[ "$arg" =~ ^--MAX=([0-9]+)$ ]]; then
            requested="${BASH_REMATCH[1]}"
        elif [[ "$arg" == "--show-errors" ]]; then
            showErr=1
        elif [[ -d "$arg" ]]; then
            basedir="$arg"
        fi
    done

    [[ -z "$basedir" ]] && {
        echo -e "${RED}Error: must specify a directory.${RESET}"
        return 1
    }

    # Concurrency logic
    cpu_count=$(nproc --all 2>/dev/null || getconf _NPROCESSORS_ONLN || echo 4)
    absolute_cap=$((cpu_count * 3 / 2))
    if [[ -n "$requested" ]]; then
        if (( requested > absolute_cap )); then
            echo -e "${RED}Warning: --MAX capped to $absolute_cap (1.5x $cpu_count cores).${RESET}"
            max_jobs=$absolute_cap
        else
            max_jobs=$requested
        fi
    else
        max_jobs=$cpu_count
    fi

    echo -e "${WHITE}Batch mode: '$basedir' (max $max_jobs concurrent jobs)${RESET}"

    # Supports .MP4, .MKV, .MOV, and .AVI
    while IFS= read -r file; do
        ((total++))
        errfile=$(mktemp)
        real_file="$(realpath "$file")"
        echo -e "${WHITE}Starting: $real_file ${RESET}\n"
        makePS4  "$real_file" \
            # > >(sed -u "s|^|[$(basename "$file")] |") \
            > >(grep -E 'out_time=|speed=' | sed -u "s|^|[$(basename "$file")] |") \
            2> "$errfile" &

        pid=$!
        pid_to_file[$pid]="$file"
        pid_to_errlog[$pid]="$errfile"
        ((running++))

        # Track completion and failures inline
        if (( running >= max_jobs )); then
            wait -n -p finished_pid
            exit_code=$?
            errfile="${pid_to_errlog[$finished_pid]}"
            current_file="${pid_to_file[$finished_pid]}"
            ((running--))

            if (( exit_code != 0 )) || [[ -s "$errfile" ]]; then
                failed_file="$current_file"
                echo -e "${RED}Failed: $failed_file${RESET}"
                failed_files+=("$failed_file")

                ((failed++))
                if (( showErr )); then
                    {
                        echo "----"
                        echo "File: $failed_file"
                        echo "Exit code: $exit_code"
                        cat "$errfile"
                    } >> "$ERROR_LOG"
                fi
            else
                echo -e "${WHITE}Processing completed for $current_file${RESET}\n"
            fi
            unset pid_to_file[$finished_pid]
            unset pid_to_errlog[$finished_pid]
            rm -f "$errfile"
        fi
    done < <(
        find "$basedir" -type f \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.mov' -o -iname '*.avi' \)
    )

    while (( running > 0 )); do
        wait -n -p finished_pid
        exit_code=$?
        errfile="${pid_to_errlog[$finished_pid]}"
        current_file="${pid_to_file[$finished_pid]}"
        ((running--))

        if (( exit_code != 0 )) || [[ -s "$errfile" ]]; then
            failed_file="${pid_to_file[$finished_pid]}"
            echo -e "${RED}Failed: $failed_file${RESET}"
            failed_files+=("$failed_file")
            ((failed++))

            if (( showErr )); then
                {
                    echo "----"
                    echo "File: $failed_file"
                    echo "Exit code: $exit_code"
                    cat "$errfile"
                } >> "$ERROR_LOG"
            fi
        else
            echo -e "${GREEN}File $current_file completed without errors.${RESET}\n"
        fi
        unset pid_to_file[$finished_pid]
        unset pid_to_errlog[$finished_pid]
        rm -f "$errfile"

    done

    echo -e "${WHITE}$total files processed.${RESET}"
    if (( failed > 0 )); then
        echo -e "${RED}$failed jobs failed.${RESET}"
    else
        echo -e "${GREEN}All conversions complete.${RESET}"
    fi
    # Report failed files explicitly
    if (( failed > 0 )); then
        echo
        echo "Failed files:"
        for f in "${failed_files[@]}"; do
            echo "  - $f"
        done
    fi
    if (( showErr )) && [[ -s "$ERROR_LOG" ]]; then
        cat "$ERROR_LOG"
    fi
    rm -f "$ERROR_LOG"
    trap - INT

    read -t 0 </dev/tty
    set -m
}

check_ps4_compatibility() {
  local file="$1"
  local good=1

  # Run ffprobe
  mapfile -t info < <(ffprobe -hide_banner -v error -show_streams -show_format "$file")

  local vcodec acodec pixfmt level profile num_streams data_streams

  for line in "${info[@]}"; do
    case "$line" in
      codec_name=* )
        [[ "$line" == codec_name=h264 && -z $vcodec ]] && vcodec=h264
        [[ "$line" == codec_name=aac && -z $acodec ]] && acodec=aac
        ;;
      pix_fmt=* ) pixfmt="${line#pix_fmt=}";;
      profile=* ) profile="${line#profile=}";;
      level=* ) level="${line#level=}";;
      codec_type=data ) data_streams=1;;
    esac
  done

  # Check
  (( vcodec != h264 )) && echo "$file: [FAIL] video codec = $vcodec" && good=0
  [[ "$acodec" != "aac" ]] && echo "$file: [FAIL] audio codec = $acodec" && good=0
  [[ "$pixfmt" != "yuv420p" ]] && echo "$file: [FAIL] pixel format = $pixfmt" && good=0
  [[ "$profile"   != "High" ]]   && echo "$file: [FAIL] profile = $profile" && good=0
  (( level > 40 )) && echo "$file: [FAIL] level = $level" && good=0
  [[ -n "$data_streams" ]] && echo "$file: [FAIL] contains data stream" && good=0

  (( good )) && echo "$file: [PASS] OK"
  return $((1-good))
}

check_ps4_batch() {
    local dir base ext clean_base new_name new_path
    local basedir="$1"
    declare -a failed=()

    [[ ! -d "$basedir" ]] && {
        echo -e "\033[1;91mError: Not a directory: '$basedir'\033[0m"
        return 1
    }

    echo -e "\033[1;97mChecking compatibility in '$basedir'...\033[0m"

    while IFS= read -r file; do
        echo -n "Checking: $file... "

        if check_ps4_compatibility "$file"; then
            echo -e "\033[1;92mOK\033[0m"
        else
            echo -e "\033[1;91mFAIL\033[0m"

            dir=$(dirname "$file")
            base=$(basename "$file")
            ext="${base##*.}"
            base="${base%.*}"

            # Strip -PS4 suffix if present
            if [[ "${base,,}" == *-ps4 ]]; then
                clean_base="${base::-4}"  # Removes last 4 characters
                new_name="${clean_base}.${ext}"
                new_path="${dir}/${new_name}"

            if [[ "$file" != "$new_path" ]]; then
                echo -e "\033[1;93mRenaming failed file:\033[0m $file → $new_path"
                mv -- "$file" "$new_path"
                file="$new_path"
            fi
        fi
        # Store absolute path to avoid relative path issues
        failed+=("$(realpath "$file")")
    fi
    done < <(find "$basedir" -type f \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.mov' \))

    echo
    echo -e "\033[1;97m${#failed[@]} files failed compatibility check.\033[0m"

    [[ ${#failed[@]} -eq 0 ]] && return 0

    read -p "Convert failed files now? (y/n) " ans
    [[ "$ans" != [Yy] ]] && return 1

    for file in "${failed[@]}"; do
        echo -e "\n\033[1;97mConverting: $file\033[0m"
        dir=$(dirname "$file")
        (
        cd "$dir" || return 1
        makePS4 "$file"
        )
    done
}

# Function to convert files using background processes
ff_cvt() {
    local file_type="$1"
    local output_format="$2"
    local files=(*."$file_type")
    local failed_files=()

    # Function to check if FFMPEG is installed
    check_ffmpeg() {
        if ! command -v ffmpeg &> /dev/null; then
            echo "FFMPEG is not installed. Attempting to install..."
            install_ffmpeg
        else
            echo "FFMPEG is already installed."
        fi
    }

    # Function to install FFMPEG using popular package managers
    install_ffmpeg() {
        local managers=("apt-get" "yum" "dnf" "brew" "pacman")
        for manager in "${managers[@]}"; do
            if command -v "$manager" &> /dev/null; then
                sudo "$manager" install ffmpeg -y
                return
            fi
        done
        echo -e "${RED}No supported package manager found. Please install FFMPEG manually."
        return 1
    }

    check_ffmpeg

    for file in "${files[@]}"; do
        {
            if ffmpeg -i "$file" "${file%.*}.$output_format"; then
                echo "${GREEN}Converted: $file"
            else
                echo "${RED}Failed to convert: $file"
                failed_files+=("$file")
            fi
        } &
    done

    wait

    if [ ${#failed_files[@]} -ne 0 ]; then
        echo "Some files failed to convert. Would you like to try again? (y/n)"
        read -r retry
        if [[ $retry == "y" ]]; then
            for file in "${failed_files[@]}"; do
                ffmpeg -i "$file" "${file%.*}.$output_format" || echo "Still failed: $file"
            done
        fi
    fi

    echo "Do you want to delete the original files? (y/n)"
    read -r delete
    if [[ $delete == "y" ]]; then
        rm -f *."$file_type"
        echo "Original files deleted."
    else
        echo "Original files kept."
    fi
}

ff_join() {
    if [ "$#" -ne 3 ]; then
        echo "Usage: $0 <input_file1> <input_file2> <output_file>"
        return 1
    fi

    # Create a temporary file list
    base_name=$(basename "$3" .${3##*.})  # Extract base name without extension
    temp_file="${base_name}.tmp"      # Create temp file with .tmp extension
    echo "file '$1'" > "$temp_file"
    echo "file '$2'" >> "$temp_file"

    ffmpeg -f concat -safe 0 -i "$temp_file" -c copy "$3"
    rm "$temp_file"
}

# Function to list all functions and their contents
lsfn() {
    # Check if there are any functions defined
    if declare -F | grep -q .; then
        echo "Listing all functions and their contents:"
        # Loop through each function and print its name and content
        for func in $(declare -F | awk '{print $3}'); do
            echo "Function: $func"
            # Print the function content
            declare -f "$func"
            echo "-----------------------------------"
        done
    else
        echo "No functions defined in the current session."
    fi
}

# Start background job to write history every 60 seconds
history_autosave() {
    # Exit early if not interactive
    [[ $- != *i* ]] && return

    while true; do
        sleep 60
        history -a
    done
}

[[ -s $HOME/.pythonz/etc/bashrc ]] && source $HOME/.pythonz/etc/bashrc
history_autosave &
alias diffuse='/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=diffuse --file-forwarding io.github.mightycreak.Diffuse @@ $1 $2 @@'