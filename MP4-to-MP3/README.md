## Script to automate converting MP4 and M4A files to MP3 format.

To use the original script:
  * download mp4-to-mp3.sh from here
  * make the script executable
  * open a terminal in a folder with MP4 or M4A files and type:

    `./mp4-to-mp3.sh ./`

Recursively converts all MP3 and M4A files in all folders and subfolders into MP3 files. If errors are encountered, it will leave a message about the problem file and move on to the next (if available).

To use the new script instead:
- download mp4-to-mp3_v2.sh from here
- make the script executable
- open a terminal in a folder with MP4 or M4A files and type one of the following:

    `./mp4-to-mp3_v2.sh`
    `./mp4-to-mp3_v2.sh "FILE"`
    `./mp4-to-mp3_v2.sh --all`
    `./mp4-to-mp3_v2.sh -a`
    `./mp4-to-mp3_v2.sh --help`
    `./mp4-to-mp3_v2.sh -h`

Usage: ./mp4-to-mp3_v2.sh [--all] [FILE]
  FILE       convert a single MP4/M4A file - use double quotes if there are spaces in the file name ("FILE NAME.mp3")
  -a, --all  convert every MP4/M4A in the current directory
  -h, --help show this help and exit

**How it behaves**
- **Single file:** `mp4-to-mp3_v2.sh song.m4a` converts that file and exits.
- **No argument:** lists the MP4/M4A files in the current folder, numbered. It pipes the list through `less` only if it has more than (terminal lines − 1) entries.
- **Selecting:** the prompt takes `1 3 5-7`, commas, `a` for all, `l` to re-show the list, or `q` to quit. I added `l` because once you leave `less` the list is no longer on screen.
- **`--all` / `-a`:** skips the menu and converts everything.
- **Similar-name check:** it compares names case-insensitively and also ignores punctuation and spaces, so `Some Song - Live.mp4` matches `some_song-live.MP3`. When it finds a match, it asks **[S]kip or [c]onvert anyway** and defaults to skip. If there's no match, it just converts.
- **End of run:** it prints a summary with the converted count, the skipped list and the failed list. The failed list is in red, and the script exits 1 if anything failed.

**Changes from the original**
- **Counters:** the original piped `find` into `while`, which runs in a subshell, so counters and lists would never survive the loop. I replaced it with arrays and a plain `for` loop.
- **Temp output file:** ffmpeg now writes to `name.mp3.part` and renames on success. A failed or interrupted run can't leave a truncated MP3 that looks finished, and "convert anyway" can't destroy your existing MP3 if the new encode fails.
- **Visible errors:** ffmpeg runs with `-loglevel warning -stats`, so real problems stay on screen, and its exit code is checked on every file.
- **`-nostdin`:** without it, ffmpeg can swallow your terminal input in a loop. Prompts also read from `/dev/tty` for the same reason. With no terminal at all, the skip prompt defaults to skip.
- **`-vn`:** drops embedded cover-art streams so they don't end up as odd video streams in the MP3.
- **Ctrl-C:** it still prints the summary of what finished.

Currently, as with the original, this only runs on APT and YUM based distros.