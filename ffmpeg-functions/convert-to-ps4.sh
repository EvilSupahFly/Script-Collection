# Function 'makePS4' takes two filenames are arguments and copies the codec metadata of SOURCE, which should be 'known good' on the PS4,
# and saves it to a template which it uses to convert TARGET using FFMPEG to match, ideally making a 'known-good-on-PS4' copy of TARGET.
#
#     makePS4 "SOURCE" "TARGET"
#
# Alternatively, if you've run 'makePS4' before, and you already have a working template, specifiying only one file will use the existing
# template to convert TARGET to match the format of the file the template was originally built against.
#
#     makePS4 "TARGET"
#

function makePS4() {
    function validate_files() {
        if [[ $# -ne 1 && $# -ne 2 ]]; then
            echo -e "${RED}Error: Please provide either one or two files."
            exit 1
        fi

        for file in "$@"; do
            if [[ ! -e "$file" ]]; then
                echo -e "${RED}Error: $file doesn't exist."
                exit 1
            fi
        done
    }

    function chkTemplate() {
        CHKTMPLT=FALSE
        FILE1="$1"; FILE2="$2"
        if [[ -e "$TEMPLATE" && $(stat -c%s "$TEMPLATE") -gt 10 ]]; then
            CHKTMPLT=TRUE
        fi
        # Handle file conversion based on CHKTMPLT
        if [[ $# -eq 1 ]]; then
            if [[ $CHKTMPLT == TRUE ]]; then
                FILE2="$FILE1"
            else
                echo -e "${RED}Error: Template file is missing or invalid. ${WHITE}Please re-run with two files.${RESET}"
                exit 1
            fi
        fi
    }

    function chkApp() {
        local app="$1"
        local managers=("apt" "dnf" "pacman" "brew" "zypper" "yum" "apk" "snap" "port" "choco")

        if command -v "$app" &> /dev/null; then
            return
        fi

        echo -e "${RED}$app is not installed. ${WHITE}Attempting to install...\n${RESET}"
        for manager in "${managers[@]}"; do
            if command -v "$manager" &> /dev/null; then
                case "$manager" in
                    apt|dnf|pacman|zypper|yum|apk|snap)
                        sudo "$manager" install ffmpeg vlc
                        return
                        ;;
                    brew)
                        brew install ffmpeg vlc
                        return
                        ;;
                    port)
                        sudo port install ffmpeg vlc
                        return
                        ;;
                    choco)
                        choco install ffmpeg vlc
                        return
                        ;;
                esac
            fi
        done
        echo -e "${RED}Error: No supported package manager found."
        return 1
    }

    ## Colour Definitions
    #BOLD="\033[1m" #Bold or Hi-Intensty - depends on your terminal app
    #ULINE="\033[4m" #Underline
    RESET="\033[0m" # Normal
    RED="\033[1m\033[1;91m" # Red
    #GREEN="\033[1m\033[1;92m" # Green
    #YELLOW="\033[1m\033[1;33m" # Yellow
    WHITE="\033[1m\033[1;97m" # White
    #PURPLE="\033[1m\033[35m" # Magenta (Purple)

    FILE1="$1"
    FILE2="$2"
    TEMPLATE="$HOME/.var/conversions/PS4TEMPLATE.TXT"
    CHKTMPLT=FALSE
    echo -e "${WHITE}"

    # Execute validation and checks
    validate_files "$@"
    chkApp ffmpeg
    chkTemplate "$@"

    # Wait until all checks are performed before setting $PS4
    PS4="${FILE2%.*}-PS4.${FILE1##*.}"
    if [[ $CHKTMPLT == TRUE ]]; then
        codec_data=$(<"$TEMPLATE")
        ffmpeg -i "$FILE2" -c:v "$codec_data" "$PS4" || { echo -e "${RED}FFMPEG conversion failed."; exit 1; }
    else
        ffmpeg -i "$FILE1" -f ffmetadata "$TEMPLATE"
        ffmpeg -i "$FILE2" -c:v copy -c:a copy "$PS4" || { echo -e "${RED}FFMPEG conversion failed."; exit 1; }
    fi

    # Verify conversion success
    if [[ ! -e "$PS4" ]]; then
        echo -e "${RED}Error: The output file $PS4 was not created."
        exit 1
    fi

    # Prompt to play the converted file
    read -p "Would you like to play $PS4 in VLC? (y/n) " play_choice
    if [[ $play_choice == "y" ]]; then
        chkApp vlc
        vlc "$PS4" &
    fi

    # Prompt for deletion of FILE2
    echo -e "${RED}"
    read -p "(1/3) Do you want to delete $FILE2? (y/n) " delete_choice
    if [[ $delete_choice == "y" ]]; then
        read -p "(2/3) Are you absolutely sure? (y/n) " confirm_delete
        if [[ $confirm_delete == "y" ]]; then
            read -p "(3/3) Final confirmation to delete $FILE2? (y/n) " final_confirm
            if [[ $final_confirm == "y" ]]; then
                rm -f "$FILE2"
                echo -e "${WHITE}$FILE2 ${RED}has been successfully deleted.${RESET}"
            else
                echo -e "${WHITE}$FILE2 has been left in place.${RESET}"
            fi
        else
            echo -e "${WHITE}$FILE2 has been left in place.${RESET}"
        fi
    else
        echo -e "${WHITE}$FILE2 has been left in place.${RESET}"
    fi
}
