#!/bin/bash

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
    local multi_source=false
    local dest=""

    # Process arguments. -d takes the next token as an explicit
    # destination, so -m never has to guess one from position.
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -x)
                use_excludes=true
                shift
                ;;
            -m)
                multi_source=true
                shift
                ;;
            -d)
                if [[ -z "$2" ]]; then
                    echo "cp: -d requires a destination argument" >&2
                    return 1
                fi
                dest="$2"
                shift 2
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done

    # If -x was specified and exclude file exists, add it
    if [[ "$use_excludes" == true && -f "$EXCLUDE_FILE" ]]; then
        EXCLUDES+=(--exclude-from="$EXCLUDE_FILE")
    fi

    if [[ "$multi_source" == true ]]; then
        # No -d means we genuinely don't know where this was supposed to
        # go - refuse instead of silently treating the last source as the
        # destination. This is the case that matters when you're remote.
        if [[ -z "$dest" ]]; then
            echo "cp -m: no destination given - use -d DEST. Refusing to guess from the last source." >&2
            return 1
        fi
        if [[ ${#args[@]} -lt 1 ]]; then
            echo "cp -m: need at least one source" >&2
            return 1
        fi
        if [[ -e "$dest" && ! -d "$dest" ]]; then
            echo "cp -m: destination '$dest' exists and is not a directory - refusing" >&2
            return 1
        fi
        args+=("$dest")
    else
        # More than SRC DEST without -m is almost always a mistake - refuse
        # instead of guessing.
        if [[ ${#args[@]} -gt 2 ]]; then
            echo "cp: ${#args[@]} paths given but no -m flag - refusing to guess. Use -m -d DEST for multi-source." >&2
            return 1
        fi
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
    local multi_source=false
    local dest=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -x)
                use_excludes=true
                shift
                ;;
            -m)
                multi_source=true
                shift
                ;;
            -d)
                if [[ -z "$2" ]]; then
                    echo "mv: -d requires a destination argument" >&2
                    return 1
                fi
                dest="$2"
                shift 2
                ;;
            *)
                ARGS+=("$1")
                shift
                ;;
        esac
    done

    if [[ "$multi_source" == true ]]; then
        # Same rule as cp: forgetting -d is a hard stop, since a successful
        # run here also rm -rf's every source afterward.
        if [[ -z "$dest" ]]; then
            echo "mv -m: no destination given - use -d DEST. Refusing to guess from the last source." >&2
            return 1
        fi
        if [[ ${#ARGS[@]} -lt 1 ]]; then
            echo "mv -m: need at least one source" >&2
            return 1
        fi
        if [[ -e "$dest" && ! -d "$dest" ]]; then
            echo "mv -m: destination '$dest' exists and is not a directory - refusing" >&2
            return 1
        fi
        ARGS+=("$dest")
    else
        if [[ ${#ARGS[@]} -gt 2 ]]; then
            echo "mv: ${#ARGS[@]} paths given but no -m flag - refusing to guess. Use -m -d DEST for multi-source." >&2
            return 1
        fi
    fi

    # Fallback to system mv for simple renames (same dir, single file/dir).
    # Only when -m wasn't forced, so an explicit -m always goes through rsync.
    if [[ "$multi_source" != true && ${#ARGS[@]} -eq 2 && -e "${ARGS[0]}" && ! -d "${ARGS[1]}" ]]; then
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