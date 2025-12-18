#!/bin/bash

makePS4() {
    if shopt -qo histexpand; then
        set +H
    fi
    # Colour Codes
    RESET="\033[0m"; RED="\033[1m\033[1;91m"; WHITE="\033[1m\033[1;97m"; GREEN="\033[1m\033[1;92m"
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
    # Output file

    #PS4="$(dirname "$TARGET")/$(basename "${TARGET%.*}-PS4.${ps4_ext}")"
    # sanitize for PS4
    #PS4="${TARGET%.*}-PS4.${ps4_ext}"
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
    if shopt -qo monitor; then
        set +m
    fi

    # Colour codes
    RESET="\033[0m"; RED="\033[1m\033[1;91m"; WHITE="\033[1m\033[1;97m"; GREEN="\033[1m\033[1;92m"

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
    #wait 2>/dev/null
    read -t 0 </dev/tty
    set -m
}

# PS4 Media Compliance Check
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
