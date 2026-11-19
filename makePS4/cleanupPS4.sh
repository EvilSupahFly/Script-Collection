#!/bin/bash
# cleanupPS4: verify a converted copy and, only after you type "delete", remove the ORIGINAL file.
#
# DESTRUCTIVE, so it is deliberately hard to automate:
#   * one file at a time; directories and multiple files are refused (no batch mode)
#   * interactive terminal only; refuses to run from scripts, loops in scripts, or other functions
#   * always asks, via /dev/tty, and wants the word "delete"; there is no --yes
#   * nothing is deleted unless EVERY verification check passes
#   * the --list report is read-only and only exists as the FIRST argument (see below)
#
# Needs makePS4.sh sourced first (it reuses that script's probing and naming code). Keeping this in its own
# file means the destructive function only exists in shells where you chose to load it.
#
#   source makePS4.sh
#   source cleanupPS4.sh

_ps4_cleanup_help() {
    cat <<EOF
${WHITE}cleanupPS4${RESET}: verify a -PS4 conversion, then (after confirmation) delete the original

Usage: cleanupPS4 [--verify-only] [--quick] ORIGINAL_FILE
       cleanupPS4 --list[=FILE] FOLDER

  --verify-only    run the checks and report; never offers to delete
  --quick          skip the full decode test (faster, but the output is NOT proven readable end to end)
  -h, --help       show this help

Give it the ORIGINAL (e.g. Movie.mkv); it finds Movie-PS4.mkv beside it. Checks, all of which must pass:
  - the converted file passes the same PS4 compatibility check makePS4 uses
  - same duration as the original (within 0.2%, minimum 1 second)
  - every audio track is present, with the same languages
  - every text subtitle track is present, with the same languages
  - the original has no image-based subtitles (burn-in can't be verified automatically, so check by eye)
  - video width matches (or was scaled down to 1920)
  - the whole file decodes without a single error (unless --quick)

List mode (read-only; never deletes anything):
  cleanupPS4 --list[=FILE] FOLDER
  Scans FOLDER recursively and writes to FILE (default: ./ps4-cleanup-candidates.txt) the original files whose
  converted -PS4.mkv copy exists, passes the compatibility rules and has the same duration. These are the
  candidates worth running cleanupPS4 on; each still gets the full verification and its own confirmation.
  --list only counts as the FIRST argument, and then everything except the folder is ignored. Anywhere else it
  is ignored and the rest of the command runs normally. That way a deleting command can never turn into a list
  run, or the other way round.

External subtitles: sidecar files (Movie.srt, Movie.en.srt, ...) that makePS4 copied beside the converted file
are deleted along with the original, but only if they are byte-for-byte identical to the copy, and they are
listed in the confirmation. Any others are left alone.

One file at a time. No batch mode and no automatic confirmation, by design.
EOF
}

# prints: width height duration  (first video stream; 0 when unknown)
_ps4_dims() {
    local key val w="" h="" d=""
    while IFS='=' read -r key val; do
        case $key in width) w=$val ;; height) h=$val ;; duration) d=$val ;; esac
    done < <(ffprobe -v error -select_streams v:0 -show_entries stream=width,height:format=duration \
                -of default=nw=1 "$1" 2>/dev/null)
    echo "${w:-0} ${h:-0} ${d:-0}"
}

# same duration within 0.2% (minimum 1 second)?
_ps4_dur_ok() {
    [[ $1 =~ ^[0-9.]+$ && $2 =~ ^[0-9.]+$ ]] && awk -v a="$1" -v b="$2" \
        'BEGIN { if (a <= 0 || b <= 0) exit 1; d = a - b; if (d < 0) d = -d; t = a * 0.002; if (t < 1) t = 1; exit !(d <= t) }'
}

# cleanupPS4 --list[=FILE] FOLDER: read-only report of originals that have a ready converted copy.
_ps4_cleanup_list() {
    local list_file=ps4-cleanup-candidates.txt dir="" arg f out i=0 total sd od
    local -a ignored=() ready=() notready=() files=()
    [[ $1 == --list=* ]] && list_file=${1#--list=}
    [[ -n $list_file ]] || list_file=ps4-cleanup-candidates.txt
    shift
    for arg in "$@"; do
        if [[ -z $dir && $arg != -* ]]; then dir=$arg; else ignored+=("$arg"); fi
    done
    [[ -n $dir ]] || { echo "${RED}List mode needs a folder: cleanupPS4 --list[=FILE] FOLDER${RESET}" >&2; return 1; }
    [[ -d $dir ]] || { echo "${RED}Not a folder: $dir${RESET}" >&2; return 1; }
    (( ${#ignored[@]} )) && echo "${YELLOW}List mode ignores everything except the folder; ignoring: ${ignored[*]}${RESET}"
    _ps4_need_tools || return 1
    _ps4_list_init "$list_file" || return 1

    mapfile -d '' -t files < <(_ps4_find "$dir" skip)      # originals only: -PS4 outputs are skipped
    total=${#files[@]}
    local _aud_mode=all
    for f in "${files[@]}"; do
        (( i++ ))
        out=$(_ps4_outname "$f")
        [[ -f $out ]] && ! [[ $f -ef $out ]] || continue      # no converted copy: not a candidate
        [[ -t 1 ]] && printf '\r\033[K[%d/%d] checking %s' "$i" "$total" "${f##*/}"
        read -r _ _ sd <<< "$(_ps4_dims "$f")"
        if ! _ps4_inspect "$out"; then notready+=("$f  (converted copy unreadable)"); continue; fi
        _ps4_pick_audio eng
        if ! _ps4_verdict "$out" >/dev/null; then notready+=("$f  (converted copy fails the compatibility check)"); continue; fi
        read -r _ _ od <<< "$(_ps4_dims "$out")"
        if ! _ps4_dur_ok "$sd" "$od"; then notready+=("$f  (converted copy has a different duration)"); continue; fi
        ready+=("$f")
    done
    [[ -t 1 ]] && printf '\r\033[K'

    _ps4_list_write "$list_file" "${ready[@]}"
    echo "${GREEN}${#ready[@]} original(s)${RESET} in '$dir' have a converted copy that passes the checks."
    if (( ${#notready[@]} )); then
        echo "${YELLOW}${#notready[@]} original(s) have a converted copy that is NOT ready:${RESET}"
        printf '  - %s\n' "${notready[@]}"
    fi
    echo "These are candidates only: cleanupPS4 still runs the full verification and asks before each deletion."
    echo "Work through them at the prompt (each one asks you to type 'delete'):"
    echo "  mapfile -t todo < '$list_file'; for f in \"\${todo[@]}\"; do cleanupPS4 \"\$f\"; done"
}

cleanupPS4() {
    if ! declare -F _ps4_inspect >/dev/null || ! declare -F _ps4_outname >/dev/null; then
        echo "cleanupPS4 needs makePS4.sh sourced first." >&2
        return 1
    fi

    # Safeguard: --list is honoured ONLY as the very first argument, and then nothing else is.
    if [[ ${1:-} == --list || ${1:-} == --list=* ]]; then
        _ps4_cleanup_list "$@"; return
    fi

    local verify_only=0 quick=0 orig="" arg n=0
    for arg in "$@"; do
        case $arg in
            --verify-only) verify_only=1 ;;
            --quick)       quick=1 ;;
            --list|--list=*) echo "${YELLOW}Ignoring $arg: --list only works as the first argument.${RESET}" ;;
            -h|--help)     _ps4_cleanup_help; return 0 ;;
            -*)            echo "${RED}Unknown option: $arg${RESET}" >&2; return 1 ;;
            *)             orig=$arg; (( n++ )) ;;
        esac
    done
    (( n )) || { _ps4_cleanup_help; return 1; }
    if (( n > 1 )); then
        echo "${RED}One file at a time: cleanupPS4 is deliberately not a batch tool.${RESET}" >&2
        return 1
    fi
    if [[ -d $orig ]]; then
        echo "${RED}'$orig' is a directory. cleanupPS4 only works on a single file, on purpose.${RESET}" >&2
        return 1
    fi
    [[ -f $orig ]] || { echo "${RED}File not found: $orig${RESET}" >&2; return 1; }

    # ---- gates for the destructive path (--verify-only is harmless, so it skips them) ----
    if (( ! verify_only )); then
        if (( ${#FUNCNAME[@]} > 1 )); then
            echo "${RED}Refusing: cleanupPS4 can't be called from a script or another function.${RESET}" >&2
            return 1
        fi
        if [[ $- != *i* || ! -t 0 || ! -t 1 ]] || ! { : < /dev/tty; } 2>/dev/null; then
            echo "${RED}Refusing: cleanupPS4 only runs interactively, at a terminal you're typing in.${RESET}" >&2
            return 1
        fi
    fi

    _ps4_need_tools || return 1

    local name out
    name=$(basename "$orig"); name=${name%.*}
    if [[ ${name,,} == *-ps4 ]]; then
        echo "${RED}'$orig' carries the -PS4 label, so it's the converted copy. Pass the ORIGINAL instead.${RESET}" >&2
        return 1
    fi
    out=$(_ps4_outname "$orig")
    [[ -f $out ]] || { echo "${RED}No converted copy found at: $out${RESET}" >&2; return 1; }
    if [[ $orig -ef $out ]]; then
        echo "${RED}Original and converted copy are the same file; refusing.${RESET}" >&2
        return 1
    fi

    echo "${WHITE}Original:  $orig${RESET}"
    echo "${WHITE}Converted: $out${RESET}"
    echo

    local -a problems=()
    local i
    [[ -e $out.part ]] && problems+=("a leftover '$out.part' exists (an interrupted conversion?)")

    # ---- facts about the original ----
    _ps4_inspect "$orig" || { echo "${RED}Can't read the original.${RESET}" >&2; return 1; }
    local -a s_alang=() s_slang=()
    local s_text=0 s_bitmap=0
    for ((i = 0; i < ${#_aud_lang[@]}; i++)); do s_alang+=("${_aud_lang[i]:-und}"); done
    for ((i = 0; i < ${#_sub_codec[@]}; i++)); do
        case ${_sub_codec[i]} in
            hdmv_pgs_subtitle|dvd_subtitle|dvb_subtitle|xsub) (( s_bitmap++ )) ;;
            *) (( s_text++ )); s_slang+=("${_sub_lang[i]:-und}") ;;
        esac
    done
    local sw sh sd ow oh od
    read -r sw sh sd <<< "$(_ps4_dims "$orig")"

    # ---- facts about the converted copy, judged by the converter's own rules ----
    _ps4_inspect "$out" || { echo "${RED}Can't read the converted copy.${RESET}" >&2; return 1; }
    _ps4_pick_audio eng
    local _aud_mode=all verdict
    if verdict=$(_ps4_verdict "$out"); then
        echo "  ${GREEN}PASS${RESET}  converted copy meets the PS4 compatibility rules"
    else
        echo "  ${RED}FAIL${RESET}  converted copy fails the compatibility check"
        problems+=("compatibility: ${verdict//$'\n'/; }")
    fi
    read -r ow oh od <<< "$(_ps4_dims "$out")"

    # duration
    if _ps4_dur_ok "$sd" "$od"; then
        echo "  ${GREEN}PASS${RESET}  duration matches (${sd%.*}s vs ${od%.*}s)"
    else
        echo "  ${RED}FAIL${RESET}  duration differs or is unknown (original ${sd}s, converted ${od}s)"
        problems+=("duration mismatch")
    fi

    # audio tracks
    local -a o_alang=()
    for ((i = 0; i < ${#_aud_lang[@]}; i++)); do o_alang+=("${_aud_lang[i]:-und}"); done
    if [[ ${#s_alang[@]} -eq ${#o_alang[@]} && \
          "$(printf '%s\n' "${s_alang[@]}" | sort)" == "$(printf '%s\n' "${o_alang[@]}" | sort)" ]]; then
        echo "  ${GREEN}PASS${RESET}  all ${#s_alang[@]} audio track(s) present"
    else
        echo "  ${RED}FAIL${RESET}  audio tracks differ (original: ${s_alang[*]:-none}; converted: ${o_alang[*]:-none})"
        problems+=("audio tracks differ")
    fi

    # subtitle tracks
    local -a o_slang=()
    for ((i = 0; i < ${#_sub_lang[@]}; i++)); do o_slang+=("${_sub_lang[i]:-und}"); done
    if (( s_bitmap )); then
        echo "  ${RED}FAIL${RESET}  the original has $s_bitmap image-based subtitle track(s); burn-in can't be verified automatically"
        problems+=("image-based subtitles need a manual check")
    elif [[ ${#s_slang[@]} -eq ${#o_slang[@]} && \
            "$(printf '%s\n' "${s_slang[@]}" | sort)" == "$(printf '%s\n' "${o_slang[@]}" | sort)" ]]; then
        echo "  ${GREEN}PASS${RESET}  all ${#s_slang[@]} text subtitle track(s) present"
    else
        echo "  ${RED}FAIL${RESET}  subtitle tracks differ (original: ${s_slang[*]:-none}; converted: ${o_slang[*]:-none})"
        problems+=("subtitle tracks differ")
    fi

    # picture size
    local ew=$(( sw > 1920 ? 1920 : sw ))
    if (( sw > 0 && ow > 0 )) && (( ow - ew <= 2 && ew - ow <= 2 )); then
        echo "  ${GREEN}PASS${RESET}  video width as expected (${ow}px)"
    else
        echo "  ${RED}FAIL${RESET}  video width is ${ow}px, expected about ${ew}px"
        problems+=("video size mismatch")
    fi

    # full decode
    if (( quick )); then
        echo "  ${YELLOW}SKIP${RESET}  full decode test (--quick)"
    else
        echo "  ...    decoding the entire converted file; this can take a while"
        local errlog start=$SECONDS rc
        errlog=$(mktemp)
        ffmpeg -v error -nostdin -xerror -i "$out" -map 0:v:0 -map '0:a?' -f null - 2> "$errlog"
        rc=$?
        if (( rc == 0 )) && [[ ! -s $errlog ]]; then
            echo "  ${GREEN}PASS${RESET}  decoded cleanly end to end ($(( SECONDS - start ))s)"
        else
            echo "  ${RED}FAIL${RESET}  decode errors:"
            head -n 5 "$errlog" | sed 's/^/           /'
            problems+=("decode errors")
        fi
        rm -f "$errlog"
    fi

    # external subtitle files of the original, and whether an identical copy sits beside the converted file
    local -a sc_del=() sc_keep=()
    local sc sc_sfx sc_stem
    sc_stem=$(realpath -m -- "${orig%.*}")
    while IFS= read -r sc; do
        sc_sfx=${sc#"$sc_stem"}
        if [[ -f ${out%.*}$sc_sfx ]] && cmp -s -- "$sc" "${out%.*}$sc_sfx"; then sc_del+=("$sc"); else sc_keep+=("$sc"); fi
    done < <(_ps4_sidecars "${orig%.*}")
    if (( ${#sc_del[@]} + ${#sc_keep[@]} )); then
        echo "  ${WHITE}INFO${RESET}  external subtitle files: ${#sc_del[@]} copied identically beside the converted file, ${#sc_keep[@]} not"
        (( ${#sc_keep[@]} )) && echo "        (run makePS4 on the original again to copy the missing ones; they are left alone either way)"
    fi

    echo
    if (( ${#problems[@]} )); then
        echo "${RED}NOT verified. Nothing was deleted.${RESET}"
        printf '  - %s\n' "${problems[@]}"
        return 1
    fi
    echo "${GREEN}VERIFIED: the converted copy checks out.${RESET}"
    (( verify_only )) && return 0

    # ---- confirmation: typed by a human at the terminal, never from stdin ----
    local osz nsz ans
    osz=$(stat -c %s -- "$orig"); nsz=$(stat -c %s -- "$out")
    echo
    echo "${RED}About to PERMANENTLY DELETE the original:${RESET}"
    echo "    $orig  ($(numfmt --to=iec --suffix=B "$osz"))"
    echo "${WHITE}Keeping the converted copy:${RESET}"
    echo "    $out  ($(numfmt --to=iec --suffix=B "$nsz"))"
    if (( ${#sc_del[@]} )); then
        echo "${RED}Also deleting the identical external subtitle copies:${RESET}"
        printf '    %s\n' "${sc_del[@]}"
    fi
    (( quick )) && echo "${YELLOW}(--quick: the converted file was NOT fully decoded.)${RESET}"
    read -r -p "Type 'delete' to confirm; anything else cancels: " ans < /dev/tty
    if [[ $ans != delete ]]; then
        echo "Cancelled. Nothing was deleted."
        return 1
    fi
    [[ -f $out ]] || { echo "${RED}The converted copy vanished; not deleting.${RESET}" >&2; return 1; }
    if command rm -- "$orig"; then
        for sc in "${sc_del[@]}"; do command rm -- "$sc"; done
        if (( osz > nsz )); then
            echo "${GREEN}Deleted.${RESET} Freed $(numfmt --to=iec --suffix=B $(( osz - nsz ))) net."
        else
            echo "${GREEN}Deleted.${RESET}"
        fi
    else
        echo "${RED}Could not delete '$orig'.${RESET}" >&2
        return 1
    fi
}
