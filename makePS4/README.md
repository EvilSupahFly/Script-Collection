
# makePS4 – PlayStation-Compatible Media Converter

`makePS4` and `batchPS4` are Bash functions designed to convert video files into a **PlayStation-safe MP4 format** that plays reliably on **PS4 and PS5** via **DLNA or USB**, avoiding buffering, crashes, and codec incompatibilities, and meant to be added to a user's `~/.bashrc` or to `/etc/bash.bashrc` for easy access, though you could make stand-alone scripts out of them, if you wanted.

The design favours **boring but correct** defaults: predictable playback, stable bitrates, and formats Sony’s media players actually like.

---

## Features

* Guaranteed playback on **PS4 and PS5**
* Outputs **MP4 (H.264 + AAC)** with strict compatibility
* Automatically constrains bitrate for large source files
* Skips files that already meet compatibility requirements
* Preserves original directory structure
* Batch processing with controlled concurrency
* Optional compatibility-check pass before conversion

---

## Supported Output Format

| Component    | Value                                |
| ------------ | ------------------------------------ |
| Container    | MP4                                  |
| Video        | H.264 (High, Level 4.0, 8-bit)       |
| Pixel format | yuv420p                              |
| Audio        | AAC-LC (stereo)                      |
| Subtitles    | mov_text (if present and compatible) |

This format is intentionally conservative and works reliably across Sony firmware updates.

---

## `makePS4()` – Single File Conversion

Convert one media file into a PS4/PS5-compatible MP4.

### Usage

```bash
makePS4 "input_file.mkv"
```

### Behavior

* Converts the file to `*-PS4.mp4` in the same directory
* Skips conversion if the file already matches PS4 compatibility
* Uses:

  * CRF-based encoding for small/medium files
  * Bitrate-constrained encoding for large files
* Prompts to delete the original file (single-file mode only)

---

## `batchPS4()` – Batch Conversion

Recursively process all supported media files in a directory.

### Usage

```bash
batchPS4 "MediaFolder"
batchPS4 "MediaFolder" --MAX=6
```

### Options

| Option    | Description                                               |
| --------- | --------------------------------------------------------- |
| `--MAX=N` | Maximum concurrent conversions (default: ~1.5× CPU cores) |

### Behavior

* Scans for `.mp4`, `.mkv`, and `.mov` files
* Skips files already compatible with PS4
* Runs conversions sequentially or with limited parallelism
* No deletion prompts (safe for unattended runs)
* Writes a log file in the processed directory
* Prints a summary of passed/failed jobs on completion

---

## Compatibility Check Mode (Optional)

A compatibility-check pass can be run to identify files that will **fail PS4 playback** before conversion.

* Detects:

  * 10-bit video
  * Unsupported H.264 profiles
  * Unsupported subtitle/data streams
* Optionally offers to convert failed files automatically
* Files previously named `*-PS4.mp4` but found incompatible are safely renamed and reprocessed

---

## Why This Exists

Sony consoles are **extremely strict** about media playback, especially over DLNA.
Many files that "should" work will buffer, stutter, or crash.

This tool avoids guesswork by enforcing:

* Known-safe codecs
* Predictable bitrates
* Conservative container choices

The result is **reliable playback**, not theoretical compatibility.

---

## Philosophy

> *Boring but correct.*

* No experimental codecs
* No fragile parsing
* No assumptions about Sony firmware behavior
* Designed to keep working years from now
