# makePS4 – PlayStation-Compatible Media Converter

`makePS4` and `batchPS4` are Bash functions that check video files against what the **PS4 Media Player** will actually play, and convert **only the ones that fail**. They're meant to be sourced from `~/.bashrc` (or `/etc/bash.bashrc`) so the commands are always on hand, though you can also `source makePS4.sh` ad hoc.

The design favours **boring but correct**: a file that already plays is never touched, and a file that needs fixing gets the smallest fix that works. When it does convert, it **keeps everything** (all audio tracks, all text subtitle tracks) rather than guessing what you'll want.

---

## Features

* **Pass-first:** every file is probed before anything happens. If it already passes, the script exits cleanly, whatever the container (MP4 or MKV) and whatever flags are set
* Re-encodes only what fails: compatible video and audio streams are copied, so many fixes are a quick remux
* Keeps **all audio tracks** and **all text subtitle tracks** by default, with language tags intact
* Finds the English audio track even when it is untagged or mislabelled, and makes it the default track
* Soft subtitles that actually show up on the PS4: **SRT inside MKV**
* Scales anything wider than 1080p down to 1080p; applies a bitrate cap to large (≥ 4 GB) sources
* Batch mode with controlled concurrency, per-job logs, a summary, and clean Ctrl-C handling
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

---

## What a conversion produces

A failing file is written next to the original as **`Name-PS4.mkv`**. The original is never modified or deleted. Output is written to a `.part` file and renamed on success, so an interrupted run never leaves a half-written `-PS4.mkv`.

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
| `--force` | off | Convert even if the file already passes |
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

---

## `batchPS4`: whole folders

```bash
batchPS4 "MediaFolder"
batchPS4 "MediaFolder" --MAX=2 --show-errors
```

* Scans recursively for `.mp4`, `.mkv`, `.mov`, `.avi` and `.wmv` files, skipping existing `*-PS4.mp4` / `*-PS4.mkv` outputs
* Runs `makePS4` on each, passing through `--subs=`, `--sub-lang=`, `--audio=`, `--keep-audio`, `--audio-lang=` and `--force`
* Prints `[done/total]` progress, and re-prints any `WARN:` lines from each finished job
* Ends with a summary and the list of failed files, and returns non-zero if any failed
* Ctrl-C stops the active conversions cleanly
* Run with no arguments (or `-h` / `--help`) to print the full help text; unknown options are rejected rather than ignored

| Option | Description |
| ------ | ----------- |
| `--MAX=N` | Maximum concurrent conversions. Defaults to the CPU core count and is capped at 1.5× cores. x264 already uses every core per job, so `--MAX=2` is usually just as fast |
| `--show-errors` | Show the tail of ffmpeg's output for any job that fails |

Files that already pass count as "done" immediately, so re-running a batch on a finished folder is quick and safe.

---

## Compatibility checks (no conversion)

```bash
check_ps4_compatibility "Movie.mkv"   # prints PASS, or every FAIL reason, for one file
check_ps4_batch "MediaFolder"         # reports OK/FAIL with reasons for a whole folder
```

Both print a one-line usage when run with no arguments. `check_ps4_batch` checks every video file it finds (including old `-PS4` outputs, which makes it a good way to audit earlier conversions), then offers to run `batchPS4` on the folder if anything failed. It never changes a file itself.

---

## Known limitations

* Only the PS4 Media Player's documented limits are targeted; PS5 playback has not been verified
* Non-English subtitles inside an MP4 are ignored by the check. If a file like that ever disappears from the PS4's listing, make any subtitle track in an MP4 count as a failure
* Burn-in of image-based subtitles (PGS/VobSub) is implemented but untested; text-based burn-in (`--subs=burn`) has been tested
* Surround audio is not preserved when it needs re-encoding (the output is stereo AAC)
* MKV attachments (such as fonts) are not carried into converted files
* AVI, WMV and MPEG-TS sources are always converted

---

## Philosophy

> *Boring but correct.*

* No experimental codecs
* Leave working files alone
* Keep everything when converting; let the player's menus do the choosing
* Built around what the console demonstrably plays, not what it theoretically supports
