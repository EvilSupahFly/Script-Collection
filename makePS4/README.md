# makePS4 – PlayStation-Compatible Media Converter

`makePS4` and `batchPS4` are Bash functions that check video files against what the **PS4 Media Player** will actually play, and convert **only the ones that fail**. They're meant to be sourced from `~/.bashrc` (or `/etc/bash.bashrc`) so the commands are always on hand, though you can also `source makePS4.sh` ad hoc.

The design favours **boring but correct**: a file that already plays is never touched, and a file that needs fixing gets the smallest fix that works. When it does convert, it **keeps everything** (all audio tracks, all text subtitle tracks) rather than guessing what you'll want.

---

## Features

* **Pass-first:** every file is probed before anything happens. If it already passes, the file is left alone (apart from the `-PS4` label below), whatever the container (MP4 or MKV) and whatever flags are set
* **Passing files get a `-PS4` label** (`Movie.mkv` becomes `Movie-PS4.mkv`) so you can see at a glance, in the console's file browser, which files are known to play. They are renamed, never converted
* Re-encodes only what fails: compatible video and audio streams are copied, so many fixes are a quick remux
* Keeps **all audio tracks** and **all text subtitle tracks** by default, with language tags intact
* Finds the English audio track even when it is untagged or mislabelled, and makes it the default track
* Soft subtitles that actually show up on the PS4: **SRT inside MKV**
* Scales anything wider than 1080p down to 1080p; applies a bitrate cap to large (≥ 4 GB) sources
* Batch mode with controlled concurrency, a summary, and clean Ctrl-C handling
* `--list=FILE` leaves a plain-text to-do list of failed files behind, so a multi-hour run doesn't depend on your terminal's scrollback
* A report-only compatibility checker for whole folders

---

## Requirements

* Bash 5.1 or newer (batch mode uses `wait -n -p`)
* `ffmpeg` and `ffprobe`, with `libx264` (and `libass` if you want subtitle burn-in)
* GNU coreutils / findutils (`realpath`, `stat -c`, `find -print0`, `sort -z`), as found on any mainstream Linux distro

---

## Install

```bash
# in ~/.bashrc
source /path/to/makePS4.sh
```

Or paste the file's contents into `~/.bashrc` directly.

---

## What counts as a PASS

Limits come from Sony's [PS4 Media Player format list](https://manuals.playstation.net/document/gb/ps4/videos/mp_format_v.html). A file passes when **all** of these hold:

| Component | Requirement |
| --------- | ----------- |
| Container | MP4 (including `.mov`) or MKV |
| Video | H.264, Baseline / Main / High profile, `yuv420p`, level 4.2 or lower |
| Audio | Every track is AAC (stereo) or AC-3. With `--audio=one`, a file with more than one audio track fails |
| Subtitles | Only **English or untagged** tracks matter, and they must be **SRT inside an MKV**. No subtitles, or only non-English ones, is a pass |
| Other | No data streams (MKV font attachments are fine) |

A pass is a pass: flags such as `--subs=burn` or `--sub-lang=` do not cause a passing file to be converted. Use `--force` if you really want a re-conversion.

AVI, WMV and MPEG-TS files are always converted, since the check only recognises MP4 and MKV containers.

### The `-PS4` label

The `-PS4` suffix means **"checked, and known to play on the PS4"**. It's meant as a visual flag for anyone scrolling the files in the console's Media Player (kids and their friends included), and as a marker so you never waste time re-checking or re-converting files that already work.

* A file that **passes** the check is left exactly as it is, except that it is renamed with the suffix: `Movie.mkv` becomes `Movie-PS4.mkv`, `Clip.mov` becomes `Clip-PS4.mov`. The rename happens in place and is instant.
* A file that is **converted** gets the suffix on its output (`Movie-PS4.mkv`).
* Files already ending in `-PS4` are never renamed again.
* Nothing is ever overwritten: if `Movie-PS4.mkv` already exists, the passing `Movie.mkv` keeps its name and a `WARN:` line says why.
* Don't want your files renamed? Use `--no-rename`, or set `PS4_RENAME=0` in your environment. Conversions still produce `-PS4` outputs.
* `--force` converts a passing file instead of labelling it.

The label is **verified, not trusted**. `batchPS4` and `makePS4` still check the codecs of files that already carry it, because a mislabelled file would fail on the console. If a `-PS4` file fails the check (for example, output from an older version of this script), it is reported as **`MISLABELLED`**, added to the `--list` file if you asked for one, and **left completely untouched**: nothing is renamed, converted or deleted. Delete it yourself and reconvert from the original, so you never re-encode an already-lossy copy. (`makePS4` exits with status 3 in this case.) `--force` converts it anyway; the output drops the old label first, so you don't end up with `-PS4-PS4`.

---

## What a conversion produces

A failing file is written next to the original as **`Name-PS4.mkv`**. The original is never modified or deleted, and if `Name-PS4.mkv` already exists, the source is skipped (use `--force` to redo it). Output is written to a `.part` file and renamed on success, so an interrupted run never leaves a half-written `-PS4.mkv`.

| Component | Output |
| --------- | ------ |
| Container | MKV |
| Video | Copied if already compatible; otherwise H.264 High, level 4.2, `yuv420p`, CRF 20, preset `medium`, scaled down to at most 1920 px wide |
| Audio | **All tracks kept.** AAC stereo / AC-3 tracks are copied; anything else (E-AC-3, DTS, 5.1 AAC, …) becomes stereo AAC at 192 kb/s. The preferred track (English by default) goes first and is flagged default; the rest keep their original order and language tags |
| Subtitles | **All text tracks kept** (SRT, ASS/SSA, `mov_text`, WebVTT, …) and converted to SRT, with language tags intact |

Sources of 4 GB or more also get `-maxrate 8000k -bufsize 16000k`.

### Subtitle notes

* In testing on a PS4, **SRT inside an MKV** and an MP4 with a same-named `.srt` file both showed up in the Media Player's subtitle menu. An MP4 with embedded `mov_text` subtitles did not even appear in the file listing. That is why the script writes MKV.
* ASS/SSA styling (fonts, colours, positioning) is lost in the SRT conversion.
* **Image-based subtitles** (Blu-ray PGS, DVD VobSub) can't be converted to text. In theory, if English subtitles exist only as images, the best English track is **burned into the picture** and other image tracks are dropped with a `WARN:` line. *This path is as yet untested against real PGS/VobSub files.*
* `--subs=burn` hard-codes one track (English preferred) into the video, which always shows but can't be turned off.

### Audio notes

English is identified by, in order: language tag (`en`, `eng`, `english`, with optional region), track title, and finally elimination (the lone untagged track among tagged ones, flagged as a best guess). Commentary, descriptive and karaoke tracks are never preferred. If no English audio can be identified, a `WARN:` line says so: yellow if subtitles are being kept, red if there are none.

---

## `makePS4`: single file

```bash
makePS4 "Movie.mkv"
makePS4 --subs=burn "Movie.mkv"
makePS4 --audio=one --audio-lang=jpn "Anime.S01E01.mkv"
```

Run with no arguments (or `-h` / `--help`) to print the full help text. Passing a directory prints a pointer to `batchPS4`.

### Options

| Option | Default | Description |
| ------ | ------- | ----------- |
| `--subs=soft\|burn\|none` | `soft` | Soft SRT tracks, one hard-coded track, or no subtitles |
| `--sub-lang=CODE` | `all` | Keep only this subtitle language (e.g. `eng`), or `all`. If nothing matches, everything is kept instead |
| `--audio=all\|one` | `all` | Keep every audio track, or just one. `--keep-audio` is shorthand for `--audio=all` |
| `--audio-lang=CODE` | `eng` | Language to put first and flag as default. `any` skips the language logic and puts the source's default (or first) track first |
| `--force` | off | Convert even if the file already passes (it is then not labelled) |
| `--no-rename` | off | Don't add the `-PS4` label to files that already pass |
| `--quiet` | off | Suppress progress and informational output (used by batch mode) |
| `-h`, `--help` | | Show the help text |

### Environment variables

Set these in `~/.bashrc` to change the defaults. Command-line flags override them.

| Variable | Equivalent flag |
| -------- | --------------- |
| `PS4_SUBS` | `--subs=` |
| `PS4_SUB_LANG` | `--sub-lang=` |
| `PS4_AUDIO` | `--audio=` |
| `PS4_AUDIO_LANG` | `--audio-lang=` |
| `PS4_RENAME` | `--no-rename` when set to `0` |

---

## `batchPS4`: whole folders

```bash
batchPS4 "MediaFolder"
batchPS4 "MediaFolder" --MAX=2 --show-errors
```

* Scans recursively for `.mp4`, `.mkv`, `.mov`, `.avi` and `.wmv` files and checks every one, labelled or not
* Runs `makePS4` on each, passing through `--subs=`, `--sub-lang=`, `--audio=`, `--keep-audio`, `--audio-lang=`, `--no-rename` and `--force`
* Files that pass are labelled with `-PS4`; files that fail are converted; files already labelled `-PS4` that fail are reported as `MISLABELLED` and left alone
* Prints `[done/total]` progress, and re-prints any `WARN:` and `RENAMED:` lines from each finished job
* Ends with a summary and the list of failed files, and returns non-zero if any failed. Nothing is ever prompted for, so long runs can go unattended
* Ctrl-C stops the active conversions cleanly
* Run with no arguments (or `-h` / `--help`) to print the full help text; unknown options are rejected rather than ignored

| Option | Description |
| ------ | ----------- |
| `--MAX=N` | Maximum concurrent conversions. Defaults to the CPU core count and is capped at 1.5× cores. x264 already uses every core per job, so `--MAX=2` is usually just as fast |
| `--show-errors` | Show the tail of ffmpeg's output for any job that fails |
| `--trust-labels` | Skip files already named `*-PS4.*` without checking them. Faster re-runs, but a mislabelled file will go unnoticed |
| `--list=FILE` | Write the absolute paths of failed files to `FILE`, one per line. The file is emptied at the start of the run (and the run refuses to start if it can't be written), so an empty file afterwards means nothing failed |

Files that already pass count as "done" after a quick probe, so re-running a batch on a finished folder is safe. On a very large library, you can add `--trust-labels` to skip anything already named `*-PS4.*` without probing it.

---

## Compatibility checks (no conversion)

```bash
check_ps4_compatibility "Movie.mkv"   # prints PASS, or every FAIL reason, for one file
check_ps4_batch "MediaFolder"         # reports OK/FAIL with reasons for a whole folder
check_ps4_batch "MediaFolder" --list=failing.txt   # ...and saves the failing paths to a file
```

Both print a one-line usage when run with no arguments. With `--list=FILE`, `check_ps4_batch` writes the paths of every failing file (including ones already carrying the `-PS4` label) to `FILE`. `check_ps4_batch` checks every video file it finds (including old `-PS4` outputs, which makes it a good way to audit earlier conversions), then offers to run `batchPS4` on the folder if anything failed (which will also label the files that pass). It never changes a file itself.

### Working through a list of failures

Both `batchPS4` and `check_ps4_batch` accept `--list=FILE`. Because the paths are absolute and one per line, the list is easy to work through a file at a time, with no prompts to sit through:

```bash
batchPS4 "TV Shows" --list=failed.txt

while IFS= read -r f; do
    makePS4 "$f"          # or add flags such as --subs=burn for the stubborn ones
done < failed.txt
```

---

## Known limitations

* Only the PS4 Media Player's documented limits are targeted; PS5 playback has not been verified
* Non-English subtitles inside an MP4 are ignored by the check. If a file like that ever disappears from the PS4's listing, make any subtitle track in an MP4 count as a failure
* Burn-in of image-based subtitles (PGS/VobSub) is implemented but untested; text-based burn-in (`--subs=burn`) has been tested
* A `-PS4` file that fails the check is only reported, never fixed, so cleaning up mislabelled files is a manual job (by design: it avoids re-encoding lossy copies and accidental clobbering)
* Surround audio is not preserved when it needs re-encoding (the output is stereo AAC)
* MKV attachments (such as fonts) are not carried into converted files
* AVI, WMV and MPEG-TS sources are always converted

---

## Philosophy

> *Boring but correct.*

* No experimental codecs
* Leave working files alone, and label them so you can tell
* Keep everything when converting; let the player's menus do the choosing
* Built around what the console demonstrably plays, not what it theoretically supports
