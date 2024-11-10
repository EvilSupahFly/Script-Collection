function convert_media() {
    FILE1="$1"
    FILE2="$2"
    TEMPLATE="$HOME/.var/conversions/PS4TEMPLATE.TXT"
    PS4="${FILE2%.*}-PS4.${FILE1##*.}"
    CHKTMPLT=FALSE

    function validate_files() {
        if [[ $# -lt 1 || $# -gt 2 ]]; then
            echo "Error: Please provide either one or two files."
            exit 1
        fi

        FILE1="$1"
        FILE2="$2"

        if [[ ! -e "$FILE1" ]]; then
            echo "Error: $FILE1 doesn't exist."
            exit 1
        fi
        if [[ ! -e "$FILE2" ]]; then
            echo "Error: $FILE2 doesn't exist."
            exit 1
        fi
    }

    # Normally functions are defined outside the main loop but these are only used by this function so it's fine to make them sub-functions.
    function chkTemplate() {
        if [[ -e "$TEMPLATE" && $(stat -c%s "$TEMPLATE") -gt 10 ]]; then
            CHKTMPLT=TRUE
        else
            CHKTMPLT=FALSE
        fi
    }

    function chkApp() {
        local app="$1"
        local managers=("apt" "dnf" "pacman" "brew" "zypper" "yum" "apk" "snap" "port" "choco")
        if ! command -v "$app" &> /dev/null; then
            echo -e "$app is not installed. Attempting to install...\n"
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
            echo "Error: No supported package manager found."
            return 1
        fi
    }

    # Execute validation and checks
    validate_files "$@"
    chkApp ffmpeg
    chkTemplate

    # Handle file conversion based on CHKTMPLT
    if [[ $# -eq 1 && $CHKTMPLT == TRUE ]]; then
        FILE2="$FILE1"
    elif [[ $# -eq 1 && $CHKTMPLT == FALSE ]]; then
        echo "Error: Template file is missing or invalid."
        exit 1
    elif [[ $# -eq 2 && $CHKTMPLT == TRUE ]]; then
        codec_data=$(<"$TEMPLATE")
        ffmpeg -i "$FILE2" -c:v "$codec_data" "$PS4" || { echo "FFMPEG conversion failed."; exit 1; }
    elif [[ $# -eq 2 && $CHKTMPLT == FALSE ]]; then
        ffmpeg -i "$FILE1" -f ffmetadata "$TEMPLATE"
        ffmpeg -i "$FILE2" -c:v copy -c:a copy "$PS4" || { echo "FFMPEG conversion failed."; exit 1; }
    fi

    # Verify conversion success
    if [[ ! -e "$PS4" ]]; then
        echo "Error: The output file $PS4 was not created."
        exit 1
    fi

    # Prompt to play the converted file
    read -p "Would you like to play $PS4 in VLC? (y/n) " play_choice
    if [[ $play_choice == "y" ]]; then
        chkApp vlc
        vlc "$PS4" &
    fi

    # Prompt for deletion of FILE2
    read -p "Do you want to delete $FILE2? (y/n) " delete_choice
    if [[ $delete_choice == "y" ]]; then
        read -p "Are you absolutely sure? (y/n) " confirm_delete
        if [[ $confirm_delete == "y" ]]; then
            read -p "Final confirmation to delete $FILE2? (y/n) " final_confirm
            if [[ $final_confirm == "y" ]]; then
                rm "$FILE2"
                echo "$FILE2 has been successfully deleted."
            fi
        fi
    fi
}
