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
#
# >>> 2, July 2025 Update:
#  - Added sub-functions to check for and install FFMPEG (if absent), regardless of shell being used.
#  - Added filename check to skip conversion if "-PS4" already exists, eiminating issue with reconversions
#    when codec data differs due to FFMPEG conversion quality difference from earlier script versions.
# <<<
#
# Function to convert media files to PS4-compatible formats using FFMPEG
makePS4() {
    # Colour Codes
    RESET="\033[0m"; RED="\033[1m\033[1;91m"; WHITE="\033[1m\033[1;97m"; GREEN="\033[1m\033[1;92m"
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

        i=0
        for manager in $managers; do
            if command -v "$manager" >/dev/null 2>&1; then
                echo "Using package manager: $manager"
                eval "${commands[$i]}"
                return $?
            fi
            i=$((i + 1))
        done

        echo "${RED}No supported package manager found. Please install FFMPEG manually.${RESET}"
        return 1
    }
    check_ffmpeg

    TARGET="$1"

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

    TARGET="$1"
    [[ -f "$TARGET" ]] || { echo -e "${RED}Target file not found: $TARGET${RESET}"; return 1; }

    # Sanity check: skip if the filename already ends with "-PS4" before extension
    basename_noext="${TARGET##*/}"
    basename_noext="${basename_noext%.*}"
    if [[ "$basename_noext" =~ -[Pp][Ss]4$ ]]; then
        echo -e "${WHITE}Skipping '$TARGET' — filename already ends with '-PS4'.${RESET}"
        return 0
    fi

    src_ext="mp4"
    codec_data="-c:v libx264 -profile:v high -level:v 4.0 -crf 20 -preset slow -c:a aac -b:a 192k"

    # Skip if already compliant - 'vcodec' is for video, 'acodec' is for audio
    vcodec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "$TARGET")
    acodec=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "$TARGET")
    expected_v=$(echo "$codec_data" | awk '{print $2}')
    expected_a=$(echo "$codec_data" | awk '{print $8}')

    if [[ "$vcodec" == "$expected_v" && "$acodec" == "$expected_a" ]]; then
        echo -e "${WHITE}Skipping '$TARGET' — already matches $expected_v/$expected_a.${RESET}"
        return 0
    fi

    # Subtitles will only be kept if they use the 'mov_text' format.
    # PS4 doesn't support anything else, outside of flattening the subtitles into each frame as part of the video.
    subswitch=""
    s_codec=$(ffprobe -v error -select_streams s -show_entries stream=codec_name -of default=nw=1:nk=1 "$TARGET")
    if [[ "$s_codec" == "mov_text" ]]; then
        subswitch="-c:s copy"
        echo -e "${WHITE}Copying mov_text subtitles.${RESET}"
    elif [[ -n "$s_codec" ]]; then
        echo -e "${RED}Subtitle stream ($s_codec) not compatible — will be dropped.${RESET}"
    fi

    # Output file
    PS4="${TARGET%.*}-PS4.${src_ext}"
    echo -e "${WHITE}Converting '$TARGET' to '$PS4'...${RESET}"
    eval ffmpeg -y -i "\"$TARGET\"" $codec_data $subswitch "\"$PS4\"" || {
        echo -e "${RED}Conversion failed: ${TARGET}${RESET}"
        return 1
    }

    echo -e "${WHITE}Created: $PS4${RESET}\n"
}

# Function to batch convert media files to PS4-compatible formats using makePS4 function above
batchPS4() {
    # Colour codes
    RESET="\033[0m"; RED="\033[1m\033[1;91m"; WHITE="\033[1m\033[1;97m"; GREEN="\033[1m\033[1;92m"

    local basedir=""
    local max_jobs=""
    local requested=""
    local running=0
    local total=0
    local passed=0
    local failed=0

    # Argument parsing
    for arg in "$@"; do
        if [[ "$arg" =~ ^--MAX=([0-9]+)$ ]]; then
            requested="${BASH_REMATCH[1]}"
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
            echo -e "${RED}Warning: --MAX capped to $absolute_cap (1.5× $cpu_count cores).${RESET}"
            max_jobs=$absolute_cap
        else
            max_jobs=$requested
        fi
    else
        max_jobs=$cpu_count
    fi

    echo -e "${WHITE}Batch mode: '$basedir' (max $max_jobs concurrent jobs)${RESET}"

    declare -A job_pid
    # Supports .MP4, .MKV, .MOV, and .AVI for now. To add more, just add `-o -iname '*.(your_extension)' before ' \)' below.
    find "$basedir" -type f \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.mov' -o -iname '*.avi' \) |
    while IFS= read -r file; do
        ((total++))
        logfile="$basedir/ps4_$(basename "$file").log"

        makePS4 "$file" > "$logfile" 2>&1 &
        job_pid[$!]="$logfile"
        ((running++))

        if (( running >= max_jobs )); then
            wait -n
            ((running--))
        fi
    done

    wait

    # Job status report
    for pid in "${!job_pid[@]}"; do
        logfile="${job_pid[$pid]}"
        if grep -q "Created:" "$logfile"; then
            ((passed++))
        else
            ((failed++))
        fi
    done

    echo -e "${WHITE}$max_jobs jobs requested.${RESET}"
    if (( failed > 0 )); then
        echo -e "${RED}$failed jobs failed.${RESET}"
    else
        echo -e "${GREEN}All conversions complete.${RESET}"
    fi
    echo -e "${WHITE}Details: logs in '$basedir/ps4_*.log'${RESET}"
}
