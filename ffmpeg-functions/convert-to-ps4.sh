# The function has been reworked. Now, by calling makePS4, you can convert a single file. No more template requirement.
# I've also added batchPS4() for batch-mode processing, which can handle entire directory trees by running instances of makePS4()
# as a background process. To prevent it from consuming too many system resources, it will default to running one process per CPU
# core unless otherwise directed through use of the --MAX=## argument, which is limited to 1.5x your 'nproc' core count.

# Function to convert media files to PS4-compatible formats using FFMPEG
makePS4() {
    RESET="\033[0m"; RED="\033[1m\033[1;91m"; WHITE="\033[1m\033[1;97m"; GREEN="\033[1m\033[1;92m"

    TARGET="$1"

    if [[ -z "$TARGET" ]]; then
        echo -e "${RED}Usage: makePS4 FILE${RESET}"
        return 1
    fi

    if [[ -d "$TARGET" ]]; then
        echo -e "${RED}'$TARGET' is a directory.${RESET}"
        echo -e "${WHITE}To convert an entire folder, use:${RESET}"
        echo -e "${WHITE}  makePS4_batch \"$TARGET\" --MAX=#${RESET}"
        return 1
    fi

    if [[ ! -f "$TARGET" ]]; then
        echo -e "${RED}File not found: $TARGET${RESET}"
        return 1
    fi

    TARGET="$1"
    [[ -f "$TARGET" ]] || { echo -e "${RED}Target file not found: $TARGET${RESET}"; return 1; }

    src_ext="mp4"
    codec_data="-c:v libx264 -profile:v high -level:v 4.0 -crf 20 -preset slow -c:a aac -b:a 192k"

    # Skip if already compliant
    vcodec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "$TARGET")
    acodec=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "$TARGET")
    expected_v=$(echo "$codec_data" | awk '{print $2}')
    expected_a=$(echo "$codec_data" | awk '{print $8}')

    if [[ "$vcodec" == "$expected_v" && "$acodec" == "$expected_a" ]]; then
        echo -e "${WHITE}Skipping '$TARGET' — already matches $expected_v/$expected_a.${RESET}"
        return 0
    fi

    # Subtitles
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
        echo -e "\033[1;91mError: must specify a directory.\033[0m"
        return 1
    }

    # Concurrency logic
    cpu_count=$(nproc --all 2>/dev/null || getconf _NPROCESSORS_ONLN || echo 4)
    absolute_cap=$((cpu_count * 3 / 2))
    if [[ -n "$requested" ]]; then
        if (( requested > absolute_cap )); then
            echo -e "\033[1;91mWarning: --MAX capped to $absolute_cap (1.5× $cpu_count cores).\033[0m"
            max_jobs=$absolute_cap
        else
            max_jobs=$requested
        fi
    else
        max_jobs=$cpu_count
    fi

    echo -e "\033[1;97mBatch mode: '$basedir' (max $max_jobs concurrent jobs)\033[0m"

    declare -A job_pid

    find "$basedir" -type f \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.mov' \) |
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

    echo -e "\033[1;97m$max_jobs jobs requested.\033[0m"
    if (( failed > 0 )); then
        echo -e "\033[1;91m$failed jobs failed.${RESET}"
    else
        echo -e "\033[1;92mAll conversions complete.${RESET}"
    fi
    echo -e "\033[1;97mDetails: logs in '$basedir/ps4_*.log'\033[0m"
}
