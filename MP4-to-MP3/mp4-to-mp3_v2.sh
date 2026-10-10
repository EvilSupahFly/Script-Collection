#!/bin/bash
#
# mp4-to-mp3.sh - convert MP4/M4A audio to MP3 using ffmpeg
#
# Usage:
#   mp4-to-mp3.sh FILE        convert just FILE
#   mp4-to-mp3.sh             list MP4/M4A in the current directory and pick
#   mp4-to-mp3.sh --all       convert every MP4/M4A in the current directory
#
# If an MP3 with a similar name already exists you're asked whether to skip.
# Skipped and failed files are listed at the end of the run.

# nullglob: unmatched globs expand to nothing instead of themselves.
# nocaseglob: *.mp4 also catches .MP4, .Mp4, etc. without a find -iname dance.
shopt -s nullglob nocaseglob

SKIPPED=()
FAILED=()
CONVERTED=0

usage() {
    echo "Usage: ${0##*/} [--all] [FILE]"
    echo "  FILE       convert a single MP4/M4A file"
    echo "  -a, --all  convert every MP4/M4A in the current directory"
    echo "  -h, --help show this help"
}

# Function to check if FFMPEG is installed
check_ffmpeg() {
    if ! command -v ffmpeg &> /dev/null; then
        echo "FFMPEG is not installed. Installing..."
        if [[ -x "$(command -v apt)" ]]; then
            sudo apt update && sudo apt install ffmpeg -y
        elif [[ -x "$(command -v yum)" ]]; then
            sudo yum install ffmpeg -y
        else
            echo "Unsupported package manager. Please install FFMPEG manually."
            exit 1
        fi
    fi
}

# Lowercase and strip everything but letters/digits, so "Some Song - Live.mp3"
# and "some_song-live.MP3" compare equal. Result goes in $NORM rather than
# stdout because calling this in $(...) per candidate gets slow in big folders.
# Falls back to the plain lowercase name if stripping would leave nothing
# (e.g. a title made entirely of punctuation).
normalize() {
    NORM=${1,,}
    NORM=${NORM//[^[:alnum:]]/}
    [[ -z $NORM ]] && NORM=${1,,}
}

# Print the first MP3 in FILE's directory whose normalized name matches FILE's.
# Returns 1 if none.
find_similar_mp3() {
    local file=$1 dir want cand
    dir=$(dirname -- "$file")
    normalize "$(basename -- "${file%.*}")"
    want=$NORM
    for cand in "$dir"/*.mp3; do
        normalize "$(basename -- "${cand%.*}")"
        if [[ $NORM == "$want" ]]; then
            printf '%s\n' "$cand"
            return 0
        fi
    done
    return 1
}

# Print the numbered list of candidates.
show_list() {
    local i
    for i in "${!MATCHES[@]}"; do
        printf '%4d) %s\n' $((i + 1)) "${MATCHES[i]#./}"
    done
}

# Page through less only when the list wouldn't fit on screen (leaving one
# line for the prompt), otherwise just print it.
page_list() {
    local rows
    rows=$(tput lines 2>/dev/null || echo 24)
    if (( ${#MATCHES[@]} > rows - 1 )); then
        show_list | less
    else
        show_list
    fi
}

# Ask which entries to convert; fills SELECTED. Accepts numbers, ranges
# (5-7), commas or spaces as separators, 'a' for all, 'l' to re-list (the
# list is gone from view once less exits), 'q' to quit.
select_files() {
    local reply tok lo hi n bad
    local -A seen
    while true; do
        read -r -p "Select (e.g. 1 3 5-7), 'a' = all, 'l' = relist, 'q' = quit: " reply </dev/tty || exit 1
        case ${reply,,} in
            q) exit 0 ;;
            l) page_list; continue ;;
            a|all) SELECTED=("${MATCHES[@]}"); return ;;
        esac

        SELECTED=()
        seen=()
        bad=0
        for tok in ${reply//,/ }; do
            if [[ $tok =~ ^[0-9]+$ ]]; then
                lo=$tok; hi=$tok
            elif [[ $tok =~ ^([0-9]+)-([0-9]+)$ ]]; then
                lo=${BASH_REMATCH[1]}; hi=${BASH_REMATCH[2]}
            else
                echo "Not understood: '$tok'"; bad=1; break
            fi
            if (( lo < 1 || hi > ${#MATCHES[@]} || lo > hi )); then
                echo "Out of range: '$tok' (valid: 1-${#MATCHES[@]})"; bad=1; break
            fi
            for (( n = lo; n <= hi; n++ )); do
                # De-dupe so "1 1-3" doesn't convert file 1 twice.
                [[ -n ${seen[$n]} ]] && continue
                seen[$n]=1
                SELECTED+=("${MATCHES[n-1]}")
            done
        done
        (( bad )) && continue
        (( ${#SELECTED[@]} )) && return
        echo "Nothing selected."
    done
}

# Convert one file. Records the outcome in SKIPPED/FAILED/CONVERTED.
convert_one() {
    local file=$1 out tmp match ans rc
    out="${file%.*}.mp3"
    tmp="$out.part"

    if match=$(find_similar_mp3 "$file"); then
        echo "Similar MP3 already exists: ${match#./}"
        # No tty (or EOF) means nobody can approve an overwrite, so skip.
        read -r -p "  [S]kip or [c]onvert anyway? [S/c] " ans </dev/tty || ans=s
        if [[ ${ans,,} != c* ]]; then
            SKIPPED+=("$file")
            echo "Skipped: ${file#./}"
            return
        fi
    fi

    # Encode to a temp name and rename on success so a failed or interrupted
    # run can't clobber an existing MP3 or leave a truncated one that looks
    # finished. -f mp3 because ffmpeg can't infer the format from ".part".
    # -y is safe: we only get here if there was no similar MP3, or the user
    # just said to convert anyway. -nostdin keeps ffmpeg from eating our
    # terminal input. -vn drops embedded cover-art/video streams.
    # Log level is warning (not quiet) so real problems stay visible.
    ffmpeg -nostdin -hide_banner -loglevel warning -stats -y \
        -i "$file" -vn -q:a 0 -f mp3 "$tmp"
    rc=$?

    if (( rc == 0 )) && mv -f -- "$tmp" "$out"; then
        echo "Converted: ${file#./} -> ${out#./}"
        (( CONVERTED++ ))
    else
        echo -e "\e[31mFailed to convert: ${file#./} (ffmpeg exit code $rc)\e[0m" >&2
        rm -f -- "$tmp"
        FAILED+=("$file")
    fi
}

print_summary() {
    local f
    echo
    echo "==== Summary ===="
    echo "Converted: $CONVERTED"
    if (( ${#SKIPPED[@]} )); then
        echo "Skipped (${#SKIPPED[@]}):"
        for f in "${SKIPPED[@]}"; do echo "  ${f#./}"; done
    fi
    if (( ${#FAILED[@]} )); then
        echo -e "\e[31mFailed (${#FAILED[@]}):\e[0m"
        for f in "${FAILED[@]}"; do echo "  ${f#./}"; done
    fi
}

# ---- Main ----

ALL=0
TARGET=""
while (( $# )); do
    case $1 in
        -a|--all)  ALL=1 ;;
        -h|--help) usage; exit 0 ;;
        --)        shift; [[ -n $1 ]] && TARGET=$1; break ;;
        -*)        echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
        *)
            if [[ -n $TARGET ]]; then
                echo "Only one file at a time (or use --all)." >&2
                exit 2
            fi
            TARGET=$1
            ;;
    esac
    shift
done

check_ffmpeg

# Show what we got done even if the user bails with Ctrl-C partway through.
trap 'echo; print_summary; exit 130' INT

if [[ -n $TARGET ]]; then
    if [[ ! -f $TARGET ]]; then
        echo "No such file: $TARGET" >&2
        exit 1
    fi
    SELECTED=("$TARGET")
else
    # Current directory only; the old script recursed, which is a lot to
    # ask someone to pick from interactively.
    MATCHES=(./*.mp4 ./*.m4a)
    if (( ${#MATCHES[@]} == 0 )); then
        echo "No MP4/M4A files in $(pwd)."
        exit 0
    fi
    # NUL-delimited sort so odd filenames (spaces, newlines) survive.
    mapfile -d '' -t MATCHES < <(printf '%s\0' "${MATCHES[@]}" | sort -z)

    if (( ALL )); then
        SELECTED=("${MATCHES[@]}")
    else
        page_list
        select_files
    fi
fi

for f in "${SELECTED[@]}"; do
    convert_one "$f"
done

print_summary
# Non-zero exit if anything failed so this is usable from other scripts.
(( ${#FAILED[@]} )) && exit 1
exit 0
