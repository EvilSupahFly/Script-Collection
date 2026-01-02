# System-wide .bashrc file for interactive bash(1) shells.

# To enable the settings / commands in this file for login shells as well,
# this file has to be sourced in /etc/profile.

# If not running interactively, don't do anything
[ -z "$PS1" ] && return
ulimit -c unlimited

IFS=$'\n'

# Define some fancy colourful text with BASH's built-in escape codes. Example:
# echo -e "${BOLD}${YELLOW}This text will be displayed in BOLD YELLOW. ${RESET}While this text is normal."
BOLD="\033[1m"
RESET="\e[0m" #Normal
BGND="\e[40m"
ULINE="\033[4m"
YELLOW="${BOLD}\e[1;33m"
RED="${BOLD}\e[1;91m"
GREEN="${BOLD}\e[1;92m"
WHITE="${BOLD}\e[1;97m"

color_prompt=yes

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, overwrite the one in /etc/profile)
# but only if not SUDOing and have SUDO_PS1 set; then assume smart user.
#if ! [ -n "${SUDO_USER}" -a -n "${SUDO_PS1}" ]; then
#  PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
#  #PS1="\e[1;38;5;56;48;5;234m\u \e[38;5;240mon \e[1;38;5;28;48;5;234m\h \e[38;5;54m\[\$(date +'%a %-d %b %Y %H:%M:%S %Z')\\] \@\e[0m\n\e[0;38;5;56;48;5;234m[\w] \e[1m\$${ENDCOLOR} "
#fi

# Commented out, don't overwrite xterm -T "title" -n "icontitle" by default.
# If this is an xterm set the title to user@host:dir
#case "$TERM" in
#xterm*|rxvt*)
#    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
#    ;;
#*)
#    ;;
#esac

# enable bash completion in interactive shells
#if ! shopt -oq posix; then
#  if [ -f /usr/share/bash-completion/bash_completion ]; then
#    . /usr/share/bash-completion/bash_completion
#  elif [ -f /etc/bash_completion ]; then
#    . /etc/bash_completion
#  fi
#fi
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

# sudo hint
if [ ! -e "$HOME/.sudo_as_admin_successful" ] && [ ! -e "$HOME/.hushlogin" ] ; then
    case " $(groups) " in *\ admin\ *|*\ sudo\ *)
    if [ -x /usr/bin/sudo ]; then
	cat <<-EOF
	To run a command as administrator (user "root"), use "sudo <command>".
	See "man sudo_root" for details.

	EOF
    fi
    esac
fi

# if the command-not-found package is installed, use it
if [ -x /usr/lib/command-not-found -o -x /usr/share/command-not-found/command-not-found ]; then
	function command_not_found_handle {
	        # check because c-n-f could've been removed in the meantime
                if [ -x /usr/lib/command-not-found ]; then
		   /usr/lib/command-not-found -- "$1"
                   return $?
                elif [ -x /usr/share/command-not-found/command-not-found ]; then
		   /usr/share/command-not-found/command-not-found -- "$1"
                   return $?
		else
		   printf "%s: command not found\n" "$1" >&2
		   return 127
		fi
	}
fi

PATH=$PATH:~/.local/share/flatpak/exports/share
XDG_DATA_DIRS=$XDG_DATA_DIRS:~/.local/share/flatpak/exports/share

run_with_lolcat() {
    local func="$1"
    shift
    if declare -f "$func" > /dev/null; then
        "$func" "$@" | lolcat
    else
        echo "Function '$func' not found." >&2
        return 1
    fi
}

mix() {
    echo -e "${WHITE}Merging $1 and $2 into $3.${RESET}"
    ffmpeg -i "$1" -i "$2" -c:v copy -map 0:v -map 1:a -y "$3"
}

ffmp4() {
    echo -e "${WHITE}Converting $1 to ${1%.*}.mp4.${RESET}"
    ffmpeg -i "$1" -codec copy "${1%.*}.mp4"
}

ffmkv() {
    echo -e "${WHITE}Converting $1 to ${1%.*}.mkv.${RESET}"
    ffmpeg -i "$1" -codec copy "${1%.*}.mkv"
}

fftrim() {
    echo -e "${WHITE}Trimming $3 between $1 and $2 and saving as $4.${RESET}"
    ffmpeg -ss "$1" -to "$2" -i "$3" -c copy "$4"
}

ffps4() {
    echo -e "${WHITE}$1 will be converted to ${1%.*}_PS4.mkv with no subtitles, AAC formatted audio, and x264 video.${RESET}"
    ffmpeg -i "$1" -c:v libx264 -profile:v high -level:v 4.2 -c:a aac -map 0:s? -sn "${1%.*}_PS4.mp4"
}

ffmerge() {
    # Check if the input parameter has the correct format
    if [[ $1 != *.* ]]; then
        extension="*.$1"
    else
        extension="$1"
    fi

    # Check if the extension is provided
    if [ -z "$extension" ]; then
        echo "Usage: $0 <file_extension>"
        exit 1
    fi

    echo -e "${WHITE}Generating list for \"${GREEN}$extension${WHITE}\", and concatenating to \""${GREEN}merged.$1${WHITE}\"".${RESET}"

    # Load files into an array using globbing
    mapfile -t files < <(ls $extension 2>/dev/null)

    # Create or clear the list.txt file
    > list.txt

    # Write the formatted filenames to list.txt
    {
        for file in "${files[@]}"; do
            echo "file '$file'"
        done
    } > list.txt

    sleep 5; echo -e "${RESET}"

    # Run ffmpeg to merge the files
    ffmpeg -safe 0 -f concat -i list.txt -c copy merged.mp4

    # Prompt to delete list.txt
    echo -e "${RED}"
    read -p "Do you want to delete list.txt? (y/n): " choice
    if [[ $choice == [Yy] ]]; then
        rm list.txt
        echo "${RED}list.txt deleted.${RESET}"
    else
        echo "${WHITE}list.txt retained.${RESET}"
    fi
}

ddimg() {
    echo -e "${WHITE}Using dd to copy $1 to image file $2.${RESET}"
    if [ -z "$3" ]; then
        dd if="$1" of="$2" status=progress
    else
        dd if="$1" of="$2" bs=$3 count=$4 status=progress
    fi
}

# Replace "cp" with "rsync"
cp() {
    # One-time warning
    if [[ -z "${_RSYNC_CP_WARNING_PRINTED}" ]]; then
        echo -e "${YELLOW}Using ${RED}rsync${YELLOW} instead of built-in ${WHITE}cp${YELLOW}!${RESET}"
        _RSYNC_CP_WARNING_PRINTED=1
    fi

    local EXCLUDE_FILE="$HOME/.rsync-excludes"
    local EXCLUDES=()
    local args=()
    local use_excludes=false

    # Process arguments
    for arg in "$@"; do
        if [[ "$arg" == "-x" ]]; then
            use_excludes=true
        else
            args+=("$arg")
        fi
    done

    # If -x was specified and exclude file exists, add it
    if [[ "$use_excludes" == true && -f "$EXCLUDE_FILE" ]]; then
        EXCLUDES+=(--exclude-from="$EXCLUDE_FILE")
    fi

    echo "rsync -a -v -h --info=progress2 ${EXCLUDES[*]} ${args[*]}"
    rsync -a -v -h --info=progress2 "${EXCLUDES[@]}" "${args[@]}"
}

# Replace "mv" with rsync + rm
mv() {
    # One-time warning
    if [[ -z "${_RSYNC_MV_WARNING_PRINTED}" ]]; then
        echo -e "${YELLOW}Using ${RED}rsync${YELLOW} instead of built-in ${WHITE}mv${YELLOW}!${RESET}"
        _RSYNC_MV_WARNING_PRINTED=1
    fi

    local EXCLUDE_FILE="$HOME/.rsync-excludes"
    local EXCLUDES=()
    local ARGS=()
    local use_excludes=false

    # Process arguments
    for arg in "$@"; do
        if [[ "$arg" == "-x" ]]; then
            use_excludes=true
        else
            ARGS+=("$arg")
        fi
    done

    # Fallback to system mv for simple renames (same dir, single file/dir)
    if [[ ${#ARGS[@]} -eq 2 && -e "${ARGS[0]}" && ! -d "${ARGS[1]}" ]]; then
        local SRC_REALPATH
        local DST_REALPATH
        SRC_REALPATH="$(realpath -s "${ARGS[0]}")"
        DST_REALPATH="$(realpath -sm "${ARGS[1]}")"
        if [[ "$(dirname "$SRC_REALPATH")" == "$(dirname "$DST_REALPATH")" ]]; then
            command mv "${ARGS[@]}"
            return $?
        fi
    fi

    # Use rsync for move with optional excludes
    if [[ "$use_excludes" == true && -f "$EXCLUDE_FILE" ]]; then
        EXCLUDES+=(--exclude-from="$EXCLUDE_FILE")
    fi

    echo "rsync -a -v -h --info=progress2 ${EXCLUDES[*]} ${ARGS[*]}"
    rsync -a -v -h --info=progress2 "${EXCLUDES[@]}" "${ARGS[@]}"

    if [[ $? -eq 0 ]]; then
        local DEST="${ARGS[-1]}"
        if [[ -e "$DEST" || -d "$DEST" ]]; then
            unset 'ARGS[${#ARGS[@]}-1]'  # Remove destination from list
            rm -rf "${ARGS[@]}"
        else
            echo "Destination was not created - skipping source deletion!" >&2
            return 1
        fi
    else
        echo "rsync failed - not deleting original files." >&2
        return 1
    fi
}

# Function to check and create a Python virtual environment using pythonz - v2
pyvenv() {
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
alias fix-opera='sudo ~root/.scripts/fix-opera.sh' # Opera fix HTML5 media
/usr/bin/neofetch
/usr/games/fortune | /usr/games/cowsay -f dragon
