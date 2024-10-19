#!/bin/bash

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

# Function to convert files with user feedback
convert_files() {
    local dir=${1:-.}
    local total_files=$(find "$dir" -type f \( -iname "*.mp4" -o -iname "*.m4a" \) | wc -l)
    local processed_files=0

    find "$dir" -type f \( -iname "*.mp4" -o -iname "*.m4a" \) | while read -r file; do
        local output="${file%.*}.mp3"
        if ffmpeg -i "$file" -q:a 0 "$output"; then
            echo "Converted: $file to $output"
        else
            echo -e "\e[31mFailed to convert: $file\e[0m"
        fi
        ((processed_files++))
        echo "Progress: $processed_files/$total_files files processed."
    done
}

# Main script execution
check_ffmpeg
convert_files "$1"
