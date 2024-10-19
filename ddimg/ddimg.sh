#!/bin/bash

# Add to $HOME/.bashrc or to /etc/bash.bashrc

# Uses dd to copy a physical or logical disk into a disk image.
ddimg() {
    echo "Using dd to copy $1 to image file $2."
    if [ -z "$3" ]; then
        dd if="$1" of="$2" status=progress
    else
        dd if="$1" of="$2" bs=$3 count=$4 status=progress
    fi
}

