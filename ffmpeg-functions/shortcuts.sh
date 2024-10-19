#!/bin/bash

#Add these functions to either $HOME/.bashrc or to /etc/bash.bashrc

mix() {
    echo -e "${WHITE}Merging $1 and $2 into $3.${RESET}"
    ffmpeg -i "$1" -i "$2" -c:v copy -map 0:v -map 1:a -y "$3"
}

ffmp4() {
    echo -e "${WHITE}Converting $1 to ${1%.*}.mp4.${RESET}"
    ffmpeg -i "$1" -codec copy "${1%.*}.mp4"
}

ffmkv() {
    echo -e "${WHITE}Converting $1 to ${1%.*}.mkv.${RESET}"
    ffmpeg -i "$1" -codec copy "${1%.*}.mkv"
}

fftrim() {
    echo -e "${WHITE}Trimming $3 between $1 and $2 and saving as $4.${RESET}"
    ffmpeg -ss "$1" -to "$2" -i "$3" -c copy "$4"
}

ffps4() {
    #OG="OG_$1"; mv -v "$1" "$OG";
    echo -e "${WHITE}$1 will be converted to ${1%.*}_PS4.mkv with no subtitles, AAC formatted audio, and x264 video.${RESET}"
    ffmpeg -i "$1" -c:v libx264 -profile:v high -level:v 4.2 -c:a aac -map 0:s? -sn "${1%.*}_PS4.mp4"
    #ffmpeg -i "$OG" -map 0:v -c:v copy -map 0:a:m:language:eng -c:a aac -map 0:s? -sn "${1%.*}.mp4"
}

ffmerge() {
    echo -e "${WHITE}Generating list of all $1 files, and concatenating to \""output.$1\"".${RESET}"
    for f in $1; do echo "file '$f'" >> list.txt; done
    ffmpeg -f concat -safe 0 -i list.txt -c copy output.$1
    rm -f list.txt
}

