# nuke - pattern-matched, staged deletion for Bash

A small Bash function for clearing out a specific *kind* of clutter at a time - not a bulk "clean everything" tool. You give it a directory and an `-iname` pattern, it shows you exactly what matches, and only deletes after you've either previewed the command with `--dryrun` or typed a literal confirmation.

## Why this exists

Most delete-helper scripts are built for one-shot batch cleanup. That's not how clutter actually gets found. In practice? Usually you notice space has disappeared somewhere, go looking, find *one* category of junk (leftover `.trashed-*` files from an Android backup, orphaned `Thumbs.db`, an old build's cache folder), clear that, then go look for the next thing. `nuke` is built around that loop - one pattern, one look, one decision - which also matters on machines other people share, where you can't assume everything matching a glob is safe to remove without eyeballing it first.

## Usage

```bash
nuke <search_dir> <pattern> [--dryrun]
```

- `search_dir` - where to look (searched recursively)
- `pattern` - an `-iname` glob, matched case-insensitively against files *and* folders
- `--dryrun` - optional. Prints the exact `rm` command that would run, deletes nothing.

## Examples

```bash
# Preview first
nuke "/mnt/backups/phone" ".trashed-*" --dryrun

# Same search, for real
nuke "/mnt/backups/phone" ".trashed-*"
```

```
Found 3 item(s) matching ".trashed-*" in "/mnt/backups/phone":

0: /mnt/backups/phone/DCIM/Camera/.trashed-1653565774-IMG_001.jpg
1: /mnt/backups/phone/DCIM/Camera/.trashed-1653635501-IMG_002.jpg
2: /mnt/backups/phone/Pictures/Screenshots/.trashed-1661637595-shot.png

Type NUKE to permanently delete these 3 item(s):
```

## Safety features

`rm -Rfdv` is permanent, so the function is built to make you look **before** it runs, not **after**:

- **Numbered preview** of every match, before anything is touched.
- **`--dryrun`** prints the literal command - including `%q`-quoted paths, so what you see is exactly what would execute, spaces and all.
- **Typed confirmation**, not `y`/`n`. You have to type `NUKE` - yes, in all CAPS - which is a deliberate act instead of a reflex Enter-mash on a prompt you've scrolled past.
- **`--` before every path argument**, so a filename that happens to start with `-` can't be parsed as an option to `find` or `rm`.

## Requirements

- Bash 3.x+ (uses `read -r -d ''` for NUL-delimited paths, which handles filenames with spaces or newlines correctly - this works on much older bash than `mapfile -d ''` does, which needs 4.4+)
- GNU `find` and GNU `rm` (the `-d` flag in `rm -Rfdv` is a GNU extension; on macOS/BSD, install coreutils or adjust the flags)
- Six color variables - `RED`, `YELLOW`, `GREEN`, `WHITE`, `ULINE`, `RESET` - for the list formatting. If you're dropping this into a fresh shell without them already defined, either source them from elsewhere in your collection or set them to empty strings; the function works fine uncolored.

## Installation

Clone the repo and source the script, or drop the function into your `.bashrc` / `.bash_aliases`:

```bash
source nuke.sh
```
