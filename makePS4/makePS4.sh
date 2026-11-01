#!/bin/bash
# PS4 video helpers: makePS4, batchPS4, check_ps4_compatibility, check_ps4_batch
# Source from ~/.bashrc (or `source makePS4.sh`). Needs bash 5.1+ (wait -n -p), ffmpeg, ffprobe.
#
# PASS FIRST: a file is only converted if it FAILS the check. A pass is a pass, whatever the container
# (MP4 or MKV), and whatever flags/env vars are set; --force overrides. The one thing done to a passing
# file is a rename: it gets a -PS4 suffix (Movie.mkv -> Movie-PS4.mkv) so it's recognisable at a glance in
# the PS4's file browser, and batchPS4 never re-checks it. Never overwrites; --no-rename / PS4_RENAME=0 skips.
#   Video  H.264 Baseline/Main/High, yuv420p, level <= 4.2
#   Audio  stereo AAC or AC-3 (every track, or just the first with --audio=one)
#   Subs   only ENGLISH (or untagged) tracks matter: they must be SRT inside an MKV. Other languages are
#          never a reason to convert, and a file with no/non-English subs passes on A/V alone.
# When a file does fail, EVERYTHING is kept by default and written as MKV (-PS4.mkv): all audio tracks
# (compatible ones copied, others re-encoded to stereo AAC) and all text subtitle tracks (as SRT).
#
# Subtitles (--subs=, or PS4_SUBS):
#   soft  (default) text subs become SRT tracks in the MKV (tested on a PS4: listed and selectable;
#         mov_text in MP4 was not). English subs that only exist as images (PGS/VobSub) are burned in.
#   burn  hard-code one track (English preferred) into the picture; no toggle
#   none  drop subtitles
#   --sub-lang= / PS4_SUB_LANG: "all" (default), or a code like eng to keep only that language (if nothing
#   matches, everything is kept instead).
# Audio (--audio=all|one, --keep-audio, or PS4_AUDIO): "all" (default) keeps every track; "one" keeps a
#   single track, and files with several audio tracks then count as failing.
#   --audio-lang= / PS4_AUDIO_LANG (default eng) decides which track goes first and is flagged default.
#   English is found by language tag, then track title, then by elimination (the lone untagged track
#   among tagged ones); commentary tracks are never preferred. "any" = keep the source's default/first.
#   A WARN line appears if no English audio could be identified (red if no subtitles are kept either).

RESET=$'\033[0m'; RED=$'\033[1;91m'; WHITE=$'\033[1;97m'; GREEN=$'\033[1;92m'; YELLOW=$'\033[1;93m'

PS4_FOUR_GB=$((4 * 1024 * 1024 * 1024))

_ps4_say() { [[ -n $PS4_QUIET ]] || echo "$*"; }

_ps4_help() {
    case $1 in
    makePS4) cat <<EOF
${WHITE}makePS4${RESET}: convert one video for the PS4 Media Player, but only if it fails the check

Usage: makePS4 [options] FILE

  --subs=soft|burn|none    soft SRT tracks in an MKV (default), one burned-in track, or no subtitles
  --sub-lang=CODE|all      subtitle language to keep (default: all)
  --audio=all|one          keep every audio track (default) or a single one; --keep-audio = all
  --audio-lang=CODE|any    language to put first and flag as default (default: eng)
  --force                  convert even if the file already passes
  --no-rename              don't add the -PS4 label to files that already pass (or set PS4_RENAME=0)
  --quiet                  suppress informational output
  -h, --help               show this help

Defaults can be set with PS4_SUBS, PS4_SUB_LANG, PS4_AUDIO and PS4_AUDIO_LANG.
A failing file becomes FILE-PS4.mkv beside the original, which is never changed.
A file that already passes is left as is, except for being renamed FILE-PS4.ext (the "known to play" label).
See also: batchPS4 DIR, check_ps4_compatibility FILE, check_ps4_batch DIR
EOF
    ;;
    batchPS4) cat <<EOF
${WHITE}batchPS4${RESET}: run makePS4 over every video in a folder (recursively), converting only failures

Usage: batchPS4 DIR [options]

  --MAX=N                  concurrent conversions (default: CPU cores, capped at 1.5x cores)
  --show-errors            show the tail of ffmpeg's output for any job that fails
  --list=FILE              write the paths of failed files to FILE, one per line (a to-do list)
  --trust-labels           skip files already named *-PS4.* without checking them (faster re-runs)
  -h, --help               show this help

These are passed through to makePS4:
  --subs=  --sub-lang=  --audio=  --keep-audio  --audio-lang=  --force  --no-rename

Looks at .mp4 .mkv .mov .avi .wmv. Every file is checked, labelled or not. Files that pass are renamed
*-PS4.* (the console-visible label). A file already labelled -PS4 that FAILS is reported as MISLABELLED,
added to --list, and left untouched: delete it and reconvert from the original.
See also: makePS4 --help, check_ps4_batch DIR (report only)
EOF
    ;;
    esac
}

# --list=FILE support: start with an empty file (fail early if it can't be written), then write the
# absolute paths of the failed files, one per line, so a long run leaves a to-do list behind.
_ps4_list_init() {
    [[ -z $1 ]] || { : > "$1"; } 2>/dev/null || { echo "${RED}Can't write to list file: $1${RESET}" >&2; return 1; }
}
_ps4_list_write() {
    local out=$1 f; shift
    [[ -n $out ]] || return 0
    for f in "$@"; do realpath -- "$f"; done > "$out"
    echo "${WHITE}Wrote $# path(s) to $out${RESET}"
}

# Give a file that passed the check the -PS4 label. Never overwrites; skips files already labelled.
_ps4_label() {
    [[ ${PS4_RENAME:-1} == 0 ]] && return 0
    local f=$1 dir base ext new
    dir=$(dirname "$f"); base=$(basename "$f")
    [[ $base == *.* ]] || return 0
    ext=${base##*.}; base=${base%.*}
    [[ ${base,,} == *-ps4 ]] && return 0
    new="$dir/${base}-PS4.${ext}"
    if [[ -e $new ]]; then
        echo "${YELLOW}WARN: not renaming '$f': '$new' already exists.${RESET}"
    elif command mv -n -- "$f" "$new"; then     # `command` bypasses any mv() wrapper; same-dir rename is instant
        echo "${GREEN}RENAMED: $new${RESET}"
    else
        echo "${YELLOW}WARN: could not rename '$f'.${RESET}"
    fi
}

_ps4_need_tools() {
    [[ -n $_PS4_TOOLS_OK ]] && return 0
    local t
    for t in ffmpeg ffprobe; do
        command -v "$t" >/dev/null || {
            echo "${RED}Missing: $t (try: sudo apt install ffmpeg)${RESET}" >&2
            return 1
        }
    done
    _PS4_TOOLS_OK=1
}

# find <dir> [skip_outputs]  ->  NUL-separated list of video files
_ps4_find() {
    local -a skip=()
    if [[ -n $2 ]]; then local e; for e in mp4 mkv mov avi wmv; do skip+=(! -iname "*-PS4.$e"); done; fi
    find "$1" -type f \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.mov' \
                         -o -iname '*.avi' -o -iname '*.wmv' \) "${skip[@]}" -print0 | sort -z
}

# Probe a file once and fill these globals (1 = fine, 0 = needs work):
#   _v_ok _a_ok _c_ok _x_ok _has_a   and parallel arrays _sub_idx _sub_codec _sub_lang
_ps4_inspect() {
    local f=$1 out key val
    local re='^(Constrained Baseline|Baseline|Main|High)$'
    local idx ctype codec prof pix lvl lang ch title disp vseen=0
    _v_ok=0 _a_ok=0 _c_ok=0 _x_ok=1 _has_a=0 _container=""
    _sub_idx=() _sub_codec=() _sub_lang=()
    _aud_idx=() _aud_codec=() _aud_lang=() _aud_title=() _aud_ch=() _aud_def=()

    out=$(ffprobe -v error \
        -show_entries "stream=index,codec_type,codec_name,profile,pix_fmt,level,channels:stream_tags=language,title:stream_disposition=default:format=format_name" \
        -of default "$f" 2>/dev/null) || { echo "ffprobe could not read: $f" >&2; return 1; }

    while IFS='=' read -r key val; do
        case $key in
            '[STREAM]')   idx= ctype= codec= prof= pix= lvl= lang= ch= title= disp= ;;
            index)        idx=$val ;;
            codec_type)   ctype=$val ;;
            codec_name)   codec=$val ;;
            profile)      prof=$val ;;
            pix_fmt)      pix=$val ;;
            level)        lvl=$val ;;
            channels)     ch=$val ;;
            TAG:language) lang=${val,,} ;;
            TAG:title)    title=${val,,} ;;
            DISPOSITION:default) disp=$val ;;
            format_name)  case $val in
                              *mp4*)      _c_ok=1; _container=mp4 ;;
                              *matroska*) _c_ok=1; _container=mkv ;;
                          esac ;;
            '[/STREAM]')
                case $ctype in
                    video)
                        [[ $codec == mjpeg || $codec == png ]] && continue   # cover art
                        if (( ! vseen )); then
                            vseen=1
                            if [[ $codec == h264 && $pix == yuv420p && $prof =~ $re && $lvl =~ ^[0-9]+$ ]] \
                               && (( lvl <= 42 )); then
                                _v_ok=1
                            fi
                        fi ;;
                    audio)
                        _has_a=1
                        _aud_idx+=("$idx"); _aud_codec+=("$codec"); _aud_lang+=("$lang")
                        _aud_title+=("$title"); _aud_ch+=("${ch:-0}"); _aud_def+=("${disp:-0}") ;;
                    subtitle)
                        _sub_idx+=("$idx"); _sub_codec+=("$codec"); _sub_lang+=("$lang") ;;
                    attachment) ;;   # MKV fonts etc. are harmless
                    *)  _x_ok=0 ;;   # data streams
                esac ;;
        esac
    done <<< "$out"

    (( vseen )) || { echo "No video stream in: $f" >&2; return 1; }
    return 0
}

_ps4_lang_is() {   # is language tag $1 the wanted language $2?
    local v=$1 want=$2
    [[ -n $v ]] || return 1
    case $want in
        en|eng|english) [[ $v =~ ^(en|eng|english)([-_].*)?$ ]] ;;
        *)              [[ $v == "$want"* ]] ;;
    esac
}

_ps4_title_is() {  # does track title $1 name the wanted language $2?
    local t=$1 want=$2
    [[ -n $t ]] || return 1
    case $want in
        en|eng|english) [[ $t =~ (^|[^a-z])(english|eng|en)([^a-z]|$) ]] ;;
        *)              [[ $t == *"$want"* ]] ;;
    esac
}

# Choose the ONE audio track to keep. Sets _aud_pick (array position, "" if no audio), _a_ok
# (is that track PS4-ready as-is), _aud_note (for display) and _aud_warn (set if not confirmed).
_ps4_pick_audio() {
    local want=${1,,} n=${#_aud_idx[@]} i pick="" how="" warn=0 untagged=0 u=""
    local bad='commentary|descriptive|audio description|visually impaired|karaoke'
    local -a ok=()
    _aud_pick="" _a_ok=1 _a_all_ok=1 _aud_note="none in source" _aud_warn=""
    (( n )) || return 0

    for ((i = 0; i < n; i++)); do [[ ${_aud_title[i]} =~ $bad ]] || ok+=("$i"); done
    (( ${#ok[@]} )) || for ((i = 0; i < n; i++)); do ok+=("$i"); done

    if [[ $want != any ]]; then
        for i in "${ok[@]}"; do
            if _ps4_lang_is "${_aud_lang[i]}" "$want"; then pick=$i; how="language tag"; break; fi
        done
        if [[ -z $pick ]]; then
            for i in "${ok[@]}"; do
                if _ps4_title_is "${_aud_title[i]}" "$want"; then pick=$i; how="track title"; break; fi
            done
        fi
    fi
    if [[ -z $pick ]]; then
        for i in "${ok[@]}"; do
            if [[ -z ${_aud_lang[i]} || ${_aud_lang[i]} == und ]]; then (( untagged++ )); u=$i; fi
        done
        if (( ${#ok[@]} == 1 )); then
            pick=${ok[0]}; how="only track"
            [[ $want != any && -n ${_aud_lang[pick]} && ${_aud_lang[pick]} != und ]] && warn=1
        elif [[ $want != any ]] && (( untagged == 1 )); then
            pick=$u; how="untagged track, best guess"; warn=1
        else
            for i in "${ok[@]}"; do
                [[ ${_aud_def[i]} == 1 ]] && { pick=$i; how="default track"; break; }
            done
            [[ -n $pick ]] || { pick=${ok[0]}; how="first track"; }
            [[ $want != any ]] && warn=1
        fi
    fi

    _aud_pick=$pick
    for ((i = 0; i < n; i++)); do
        [[ ${_aud_codec[i]} == ac3 || ( ${_aud_codec[i]} == aac && ${_aud_ch[i]} -le 2 ) ]] || _a_all_ok=0
    done
    if [[ ${_aud_codec[pick]} == ac3 || ( ${_aud_codec[pick]} == aac && ${_aud_ch[pick]} -le 2 ) ]]; then
        _a_ok=1
    else
        _a_ok=0
    fi
    _aud_note="stream ${_aud_idx[pick]} (${_aud_lang[pick]:-untagged}, ${_aud_codec[pick]}, ${_aud_ch[pick]}ch) via $how"
    (( n > 1 )) && _aud_note+="; dropping $(( n - 1 )) other track(s)"
    (( warn )) && _aud_warn="No '$want' audio identified (kept ${_aud_lang[pick]:-an untagged} track)"
    return 0
}

# Does subtitle track $1 matter for the verdict? Only English or untagged ones do.
_ps4_sub_counts() {
    local l=${_sub_lang[$1]}
    [[ -z $l || $l == und ]] || _ps4_lang_is "$l" eng
}

# Best track to burn in from the given _sub_* positions: English-tagged, then untagged, then the first.
_ps4_best_sub() {
    local i
    for i in "$@"; do _ps4_lang_is "${_sub_lang[i]}" eng && { echo "$i"; return; }; done
    for i in "$@"; do [[ -z ${_sub_lang[i]} || ${_sub_lang[i]} == und ]] && { echo "$i"; return; }; done
    echo "$1"
}

# Print PASS/FAIL reasons from the last _ps4_inspect; return 0 only if everything is fine.
_ps4_verdict() {
    local f=$1 ok=1
    (( _v_ok )) || { echo "$f: [FAIL] video must be H.264 (Baseline/Main/High, yuv420p, level <= 4.2)"; ok=0; }
    if [[ $_aud_mode == all ]]; then
        (( _a_all_ok )) || { echo "$f: [FAIL] every audio track must be stereo AAC or AC-3"; ok=0; }
    else
        (( _a_ok )) || { echo "$f: [FAIL] audio must be stereo AAC or AC-3"; ok=0; }
        (( ${#_aud_idx[@]} > 1 )) && { echo "$f: [FAIL] has ${#_aud_idx[@]} audio tracks (--audio=one asks for a single track)"; ok=0; }
    fi
    (( _c_ok )) || { echo "$f: [FAIL] container must be MP4 or MKV"; ok=0; }
    (( _x_ok )) || { echo "$f: [FAIL] contains data streams"; ok=0; }
    local i
    for ((i = 0; i < ${#_sub_codec[@]}; i++)); do
        _ps4_sub_counts "$i" || continue
        if [[ $_container != mkv ]]; then
            echo "$f: [FAIL] English subtitles inside MP4 aren't shown by the PS4 Media Player (need SRT in an MKV)"; ok=0; break
        elif [[ ${_sub_codec[i]} != subrip ]]; then
            echo "$f: [FAIL] English subtitle format '${_sub_codec[i]}' (needs SRT)"; ok=0; break
        fi
    done
    (( ok )) && echo "$f: [PASS] OK"
    (( ok ))
}

check_ps4_compatibility() {
    [[ -n $1 ]] || { echo "Usage: check_ps4_compatibility FILE"; return 1; }
    local _aud_mode=${PS4_AUDIO:-all}
    _ps4_need_tools && _ps4_inspect "$1" && _ps4_pick_audio "${PS4_AUDIO_LANG:-eng}" && _ps4_verdict "$1"
}

makePS4() {
    local PS4_QUIET=${PS4_QUIET:-} PS4_RENAME=${PS4_RENAME:-1}
    local subs=${PS4_SUBS:-soft} lang=${PS4_SUB_LANG:-all} alang=${PS4_AUDIO_LANG:-eng} audio=${PS4_AUDIO:-all} force=0 target="" arg

    for arg in "$@"; do
        case $arg in
            --subs=*)     subs=${arg#--subs=} ;;
            --sub-lang=*) lang=${arg#--sub-lang=} ;;
            --audio-lang=*) alang=${arg#--audio-lang=} ;;
            --audio=*)    audio=${arg#--audio=} ;;
            --keep-audio) audio=all ;;
            --force)      force=1 ;;
            --quiet)      PS4_QUIET=1 ;;
            --no-rename)  PS4_RENAME=0 ;;
            -h|--help)    _ps4_help makePS4; return 0 ;;
            -*)           echo "${RED}Unknown option: $arg${RESET}" >&2; return 1 ;;
            *)            target=$arg ;;
        esac
    done
    lang=${lang,,}
    case $subs in
        soft|burn|none) ;;
        *) echo "${RED}--subs must be soft, burn or none${RESET}" >&2; return 1 ;;
    esac

    case $audio in
        one|all) ;;
        *) echo "${RED}--audio must be one or all${RESET}" >&2; return 1 ;;
    esac
    local _aud_mode=$audio

    [[ -n $target ]] || { _ps4_help makePS4; return 1; }
    _ps4_need_tools || return 1
    if [[ -d $target ]]; then
        echo "${RED}'$target' is a directory.${RESET}" >&2
        echo "${WHITE}To convert a whole folder: ${YELLOW}batchPS4 \"$target\" --MAX=#${RESET}" >&2
        return 1
    fi
    [[ -f $target ]] || { echo "${RED}File not found: $target${RESET}" >&2; return 1; }

    _ps4_inspect "$target" || return 1
    _ps4_pick_audio "$alang"

    local verdict
    if verdict=$(_ps4_verdict "$target") && (( ! force )); then
        _ps4_say "${WHITE}Already PS4 compatible; skipping: $target${RESET}"
        _ps4_label "$target"
        return 0
    fi
    _ps4_say "${WHITE}$verdict${RESET}"

    # A file wearing the -PS4 label that fails the check: report it and touch nothing (exit 3).
    local tb; tb=$(basename "$target"); tb=${tb%.*}
    if (( ! force )) && [[ ${tb,,} == *-ps4 ]]; then
        echo "${YELLOW}WARN: '$target' carries the -PS4 label but FAILS the check; left untouched. Reconvert from the original.${RESET}"
        echo "${YELLOW}WARN:   ${verdict//$'\n'/$'\n'WARN:   }${RESET}"
        return 3
    fi

    # ---- output name ----------------------------------------------------
    local base outfile real ext=mkv fmt=matroska
    base=$(basename "${target%.*}")
    [[ ${base,,} == *-ps4 ]] && base=${base%????}      # only reached with --force: avoid -PS4-PS4
    base=${base//[!A-Za-z0-9._() -]/_}; base=${base//  / }; base=${base//__/_}
    outfile=$(realpath -m "$(dirname "$target")/${base}-PS4.${ext}")
    real=$(realpath "$target")
    [[ $outfile == "$real" ]] && outfile=${outfile%.$ext}-2.$ext     # never overwrite the source
    local tmpout="$outfile.part"

    if [[ -e $outfile ]] && (( ! force )); then
        _ps4_say "${WHITE}Already converted; skipping (output exists): $outfile${RESET}"
        return 0
    fi

    # ---- subtitle plan -------------------------------------------------
    local n=${#_sub_idx[@]} i
    local -a sel=() pick_text=() pick_bitmap=()
    local burn_i="" burn_kind="" sub_note="none in source"

    if (( n > 0 )); then
        if [[ $subs == none ]]; then
            sub_note="dropped (--subs=none)"
        else
            for ((i = 0; i < n; i++)); do
                [[ $lang == all || -z ${_sub_lang[i]} || ${_sub_lang[i]} == und \
                   || ${_sub_lang[i]} == "$lang"* ]] && sel+=("$i")
            done
            if (( ${#sel[@]} == 0 )); then            # nothing matched: keep everything
                for ((i = 0; i < n; i++)); do sel+=("$i"); done
                echo "${YELLOW}WARN: No '$lang' subtitles found; keeping all ${n} track(s).${RESET}"
            fi
            for i in "${sel[@]}"; do
                case ${_sub_codec[i]} in
                    hdmv_pgs_subtitle|dvd_subtitle|dvb_subtitle|xsub) pick_bitmap+=("$i") ;;
                    *) pick_text+=("$i") ;;
                esac
            done

            if [[ $subs == burn ]]; then
                pick_text=()                      # explicit burn mode: nothing soft, one track hard-coded
                burn_i=$(_ps4_best_sub "${sel[@]}")
            else
                # Text tracks become soft SRT. If English only exists as images (PGS/VobSub), burn it in.
                local has_en_text=0
                for i in "${pick_text[@]}"; do _ps4_sub_counts "$i" && has_en_text=1; done
                if (( ! has_en_text && ${#pick_bitmap[@]} )); then
                    local -a cands=()
                    for i in "${pick_bitmap[@]}"; do _ps4_sub_counts "$i" && cands+=("$i"); done
                    (( ${#cands[@]} == 0 && ${#pick_text[@]} == 0 )) && cands=("${pick_bitmap[@]}")
                    if (( ${#cands[@]} )); then
                        burn_i=$(_ps4_best_sub "${cands[@]}")
                        _ps4_say "${YELLOW}Subtitles are image-based; burning the best track into the video.${RESET}"
                    fi
                fi
                local dropped=${#pick_bitmap[@]}
                [[ -n $burn_i ]] && (( dropped-- ))
                (( dropped > 0 )) && \
                    echo "${YELLOW}WARN: $dropped image-based subtitle track(s) can't be kept as soft subtitles.${RESET}"
            fi

            sub_note=""
            if [[ -n $burn_i ]]; then
                case ${_sub_codec[burn_i]} in
                    hdmv_pgs_subtitle|dvd_subtitle|dvb_subtitle|xsub) burn_kind=bitmap ;;
                    *) burn_kind=text ;;
                esac
                sub_note="burned in (track $burn_i: ${_sub_lang[burn_i]:-untagged}, ${_sub_codec[burn_i]})"
            fi
            if (( ${#pick_text[@]} )); then
                sub_note+="${sub_note:+; }soft SRT:"
                for i in "${pick_text[@]}"; do sub_note+=" ${_sub_lang[i]:-untagged}"; done
            fi
            [[ -n $sub_note ]] || sub_note="none kept"
        fi
    fi
    _ps4_say "${WHITE}Subtitles: $sub_note${RESET}"
    [[ $audio == all ]] && (( ${#_aud_idx[@]} > 1 )) && \
        _aud_note="${_aud_note%%; dropping*}; keeping all ${#_aud_idx[@]} tracks, this one first/default"
    _ps4_say "${WHITE}Audio: $_aud_note${RESET}"
    if [[ -n $_aud_warn ]]; then
        if [[ -n $burn_i ]] || { [[ $subs == soft ]] && (( ${#pick_text[@]} )); }; then
            echo "${YELLOW}WARN: $_aud_warn; relying on the subtitles being kept.${RESET}"
        else
            echo "${RED}WARN: $_aud_warn and no subtitles are being kept; this may be hard to follow.${RESET}"
        fi
    fi


    # ---- ffmpeg arguments -----------------------------------------------
    local size reenc=0 scale="scale='min(1920,iw)':-2" tmp="" in=$target
    size=$(stat -c '%s' -- "$target")
    (( _v_ok )) || reenc=1
    [[ -n $burn_i ]] && reenc=1

    local -a maps=(-map 0:v:0) fc=() vf=() vopts aopts dopts=() sopts=() mopts=(-f "$fmt") loglvl

    if (( reenc )); then
        vopts=(-c:v libx264 -preset medium -crf 20 -profile:v high -level:v 4.2 -pix_fmt yuv420p)
        if (( size >= PS4_FOUR_GB )); then
            _ps4_say "${WHITE}Large file (>= 4GB); enabling bitrate cap.${RESET}"
            vopts+=(-maxrate 8000k -bufsize 16000k)
        fi
        if [[ $burn_kind == text ]]; then
            # The subtitles filter chokes on awkward filenames, so give it a clean symlink.
            tmp=$(mktemp -d) && ln -s "$real" "$tmp/src.media" || return 1
            in=src.media
            vf=(-vf "subtitles=${in}:si=${burn_i},${scale}")
        elif [[ $burn_kind == bitmap ]]; then
            fc=(-filter_complex "[0:v:0][0:s:${burn_i}]overlay[ov];[ov]${scale}[v]")
            maps=(-map "[v]")
        else
            vf=(-vf "$scale")
        fi
    else
        vopts=(-c:v copy)
    fi

    local -a aud_keep=()
    local o=0 k
    if [[ -n $_aud_pick ]]; then
        aud_keep=("$_aud_pick")
        if [[ $audio == all ]]; then
            for ((i = 0; i < ${#_aud_idx[@]}; i++)); do
                [[ $i != "$_aud_pick" ]] && aud_keep+=("$i")
            done
        fi
        for k in "${aud_keep[@]}"; do
            maps+=(-map "0:${_aud_idx[k]}")
            if [[ ${_aud_codec[k]} == ac3 || ( ${_aud_codec[k]} == aac && ${_aud_ch[k]} -le 2 ) ]]; then
                aopts+=(-c:a:$o copy)
            else
                aopts+=(-c:a:$o aac -b:a:$o 192k -ac:a:$o 2)
            fi
            # exactly one default track (the PS4 Media Player plays the default one)
            if (( o == 0 )); then dopts+=(-disposition:a:$o default); else dopts+=(-disposition:a:$o 0); fi
            (( o++ ))
        done
    fi

    if (( ${#pick_text[@]} )) && [[ $subs == soft ]]; then
        for i in "${pick_text[@]}"; do maps+=(-map "0:${_sub_idx[i]}"); done
        sopts=(-c:s srt)
    fi

    if [[ -n $PS4_QUIET ]]; then
        loglvl=(-hide_banner -loglevel error -nostats)
    else
        loglvl=(-hide_banner -loglevel warning -stats)
    fi

    _ps4_say "${WHITE}Converting '$target' -> '$outfile'${RESET}"

    local rc
    ( [[ -z $tmp ]] || cd "$tmp" && exec ffmpeg -nostdin -y "${loglvl[@]}" -i "$in" \
        "${fc[@]}" "${maps[@]}" "${vf[@]}" "${vopts[@]}" "${aopts[@]}" "${dopts[@]}" "${sopts[@]}" \
        "${mopts[@]}" "$tmpout" )
    rc=$?
    [[ -n $tmp ]] && rm -rf "$tmp"

    if (( rc != 0 )); then
        rm -f "$tmpout"
        echo "${RED}Conversion failed (exit $rc): $target${RESET}" >&2
        return 1
    fi
    # `command` bypasses any mv() wrapper: this rename stays inside one directory, so a real mv is
    # instant, whereas an rsync-based mv would re-copy the whole file.
    command mv -f -- "$tmpout" "$outfile" || return 1
    _ps4_say "${GREEN}Created: $outfile${RESET}"
}

# Batch reaper. Deliberately relies on batchPS4's local variables (bash dynamic scope).
_ps4_reap() {
    local pid="" rc f log
    wait -n -p pid; rc=$?
    if [[ -z $pid ]]; then
        (( rc == 127 )) && running=0
        return
    fi
    [[ -n ${job_file[$pid]} ]] || return
    f=${job_file[$pid]}; log=${job_log[$pid]}
    (( running-- )); (( finished++ ))
    if (( rc == 0 )); then
        echo "${GREEN}[$finished/$total] Done: $f${RESET}"
        grep -hE 'WARN:|RENAMED:' "$log" | sed 's/^/    /'
    elif (( rc == 3 )); then
        echo "${YELLOW}[$finished/$total] MISLABELLED (-PS4 but fails the check; untouched): $f${RESET}"
        grep -h 'WARN:' "$log" | sed -n '2,$p' | sed 's/^/    /'
        failed+=("$f")
    else
        echo "${RED}[$finished/$total] FAILED (exit $rc): $f${RESET}"
        failed+=("$f")
        if (( show_err )); then
            echo "---- last lines of ffmpeg output ----"
            tail -n 15 "$log"
            echo "-------------------------------------"
        fi
    fi
    rm -f "$log"
    unset "job_file[$pid]" "job_log[$pid]"
}

batchPS4() {
    local dir="" requested="" show_err=0 list_file="" trust=0 arg
    local -a pass=()

    for arg in "$@"; do
        case $arg in
            --MAX=*)         requested=${arg#--MAX=} ;;
            --show-errors)   show_err=1 ;;
            --list=*)        list_file=${arg#--list=} ;;
            --trust-labels)  trust=1 ;;
            -h|--help)       _ps4_help batchPS4; return 0 ;;
            --subs=*|--sub-lang=*|--audio-lang=*|--audio=*|--keep-audio|--no-rename|--force) pass+=("$arg") ;;
            -*)              echo "${RED}Unknown option: $arg${RESET}" >&2; return 1 ;;
            *)               [[ -d $arg ]] && dir=$arg ;;
        esac
    done
    if [[ -z $dir ]]; then
        (( $# )) && echo "${RED}Error: no valid directory given.${RESET}" >&2
        _ps4_help batchPS4; return 1
    fi
    [[ -z $requested || $requested =~ ^[1-9][0-9]*$ ]] || { echo "${RED}--MAX needs a positive number.${RESET}" >&2; return 1; }
    _ps4_need_tools || return 1
    _ps4_list_init "$list_file" || return 1

    local cpu_count cap max_jobs
    cpu_count=$(nproc --all 2>/dev/null || getconf _NPROCESSORS_ONLN || echo 4)
    cap=$(( cpu_count * 3 / 2 ))
    max_jobs=${requested:-$cpu_count}
    if (( max_jobs > cap )); then
        echo "${YELLOW}--MAX capped to $cap (1.5x $cpu_count cores).${RESET}"
        max_jobs=$cap
    fi

    local -a files=() failed=()
    mapfile -d '' -t files < <(_ps4_find "$dir" $( (( trust )) && echo skip ))
    local total=${#files[@]} finished=0 running=0 aborted=0 f log pid p
    declare -A job_file job_log
    (( total )) || { echo "No video files found in '$dir'."; return 0; }

    echo "${WHITE}Batch mode: '$dir' ($total files, max $max_jobs concurrent jobs)${RESET}"

    # Job control off so Ctrl-C reaches us instead of silently killing background jobs.
    local restore_m=0
    [[ $- == *m* ]] && { restore_m=1; set +m; }
    trap 'aborted=1; echo; echo "Interrupted; stopping active conversions..."
          for p in "${!job_file[@]}"; do pkill -P "$p" 2>/dev/null; kill "$p" 2>/dev/null; done' INT

    for f in "${files[@]}"; do
        while (( running >= max_jobs && ! aborted )); do _ps4_reap; done
        (( aborted )) && break
        log=$(mktemp)
        echo "${WHITE}Starting: $f${RESET}"
        PS4_QUIET=1 makePS4 "${pass[@]}" "$f" > "$log" 2>&1 &
        pid=$!
        job_file[$pid]=$f; job_log[$pid]=$log
        (( running++ ))
    done
    while (( running > 0 )); do _ps4_reap; done

    trap - INT
    (( restore_m )) && set -m

    (( aborted )) && { echo "${YELLOW}Batch interrupted.${RESET}"; return 130; }
    echo "${WHITE}$total files processed.${RESET}"
    _ps4_list_write "$list_file" "${failed[@]}"
    if (( ${#failed[@]} )); then
        echo "${RED}${#failed[@]} file(s) failed or are mislabelled:${RESET}"
        printf '  - %s\n' "${failed[@]}"
        (( show_err )) || echo "(re-run with --show-errors to see ffmpeg's complaints)"
        return 1
    fi
    echo "${GREEN}All conversions complete.${RESET}"
}

check_ps4_batch() {
    local dir="" list_file="" f out ans arg
    for arg in "$@"; do
        case $arg in
            --list=*)  list_file=${arg#--list=} ;;
            -h|--help) echo "Usage: check_ps4_batch DIR [--list=FILE]   (report only; --list writes failing paths to FILE)"; return 0 ;;
            -*)        echo "${RED}Unknown option: $arg${RESET}" >&2; return 1 ;;
            *)         dir=$arg ;;
        esac
    done
    [[ -n $dir ]] || { echo "Usage: check_ps4_batch DIR [--list=FILE]"; return 1; }
    local -a failed=()
    [[ -d $dir ]] || { echo "${RED}Error: not a directory: '$dir'${RESET}" >&2; return 1; }
    _ps4_need_tools || return 1
    _ps4_list_init "$list_file" || return 1

    echo "${WHITE}Checking compatibility in '$dir'...${RESET}"
    while IFS= read -r -d '' f; do
        if out=$(check_ps4_compatibility "$f" 2>&1); then
            echo "${GREEN}OK${RESET}    $f"
        else
            echo "${RED}FAIL${RESET}  $f"
            sed -n 's/^.*: \[FAIL\]/        -/p' <<< "$out"
            failed+=("$f")
        fi
    done < <(_ps4_find "$dir")

    echo
    echo "${WHITE}${#failed[@]} file(s) failed the compatibility check.${RESET}"
    _ps4_list_write "$list_file" "${failed[@]}"
    (( ${#failed[@]} )) || return 0

    local labelled=0
    for f in "${failed[@]}"; do [[ $(basename "$f") == *-[Pp][Ss]4.* ]] && (( labelled++ )); done
    (( labelled )) && echo "${YELLOW}Note: $labelled failing file(s) already carry the -PS4 label. batchPS4 will report them" \
        "as MISLABELLED and leave them alone; delete them and reconvert from the originals.${RESET}"

    [[ -t 0 ]] || return 1        # no prompt when not run from a terminal
    read -rp "Run batchPS4 on '$dir' now? [y/N] " ans
    [[ $ans == [Yy]* ]] && batchPS4 "$dir"
}
