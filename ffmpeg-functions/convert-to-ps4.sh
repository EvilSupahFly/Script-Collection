function check_and_install() {
    local program=$1
    if ! command -v "$program" &> /dev/null; then
        echo "$program is not installed. Installing..."
        case "$(uname -s)" in
            Linux)
                if [ -f /etc/debian_version ]; then
                    sudo apt-get install "$program"
                elif [ -f /etc/redhat-release ]; then
                    sudo yum install "$program"
                elif [ -f /etc/arch-release ]; then
                    sudo pacman -S "$program"
                else
                    echo "Unsupported distribution."
                fi
                ;;
            Darwin)
                brew install "$program"
                ;;
            *)
                echo "Unsupported OS."
                return 1
                ;;
        esac
    fi
}

function convert_media() {
    if [ "$#" -lt 1 ]; then
        echo "Error: At least one file must be specified."
        return 1
    fi

    TEMPLATE="$HOME/.var/conversions/PS4TEMPLATE.TXT"
    FILE1="$1"
    FILE2="$2"

    if [ -z "$FILE2" ]; then
        if [ ! -f "$TEMPLATE" ]; then
            echo "Error: $TEMPLATE does not exist. Please re-run and specify two files."
            return 1
        fi
        FILE2="$FILE1"
    fi

    for file in "$FILE1" "$FILE2"; do
        if [ ! -f "$file" ]; then
            echo "Error: File $file does not exist."
            return 1
        fi
    done

    if [ ! -f "$TEMPLATE" ]; then
        ffmpeg -i "$FILE1" -f ffmetadata "$TEMPLATE"
    else
        read -p "Update $TEMPLATE with codecs from $FILE1? (y/n): " update
        if [[ "$update" == "y" ]]; then
            rm "$TEMPLATE"
            ffmpeg -i "$FILE1" -f ffmetadata "$TEMPLATE"
        fi
    fi

    # In the case of different file extensions, use $FILE1's extension for the conversion
    # This avoids having to check to be sure that the container format of $FILE2 actually
    # supports the codecs used by $FILE1
    PS4="${FILE2%.*}-PS4.${FILE1##*.}"
        
    # Comprehensive distribution check for FFMPEG and VLC
    check_and_install ffmpeg
    check_and_install vlc

    if ! ffmpeg -i "$FILE2" -c copy -map_metadata 0 "$PS4"; then
        echo "FFMPEG conversion failed."
        return 1
    fi

    if [ ! -f "$PS4" ]; then
        echo "Error: Conversion failed, $PS4 does not exist."
        return 1
    fi

    read -p "Play $PS4 in VLC? (y/n): " play
    if [[ "$play" == "y" ]]; then
        vlc "$PS4"
        # The option to delete is not recommended but provided for situations where free space is a concern.
        read -p "Delete $FILE2 after playback? (y/n): " delete
        if [[ "$delete" == "y" ]]; then
            rm "$FILE2"
        fi
    fi

}
