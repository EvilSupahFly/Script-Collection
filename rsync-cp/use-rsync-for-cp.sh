#!/bin/bash

# Replace "cp" with "rsync"
cp() {
    if [ "$1" == "-r" ]; then
        shift
        echo -e "rsync -avh --progress -r \"$@\"\n"
        rsync -avh --progress -r "$@"
    else
        echo -e "rsync -avh --progress \"$@\"\n"
        rsync -avh --progress "$@"
    fi
}
