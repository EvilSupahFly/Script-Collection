# install.sh - A WINE Game Installer That Grew Up

*(three years of scope creep, and I'm not sorry about it)*

## What This Is

This started three years ago as the dumbest possible way to install my GOG library under WINE - four error checks and a prayer, basically. Somewhere along the way it picked up colour output, automatic WINE installation, self-updating Vulkan/DXVK, GameScope integration, and enough error handling that at least *my* mistakes are documented. This README didn't keep pace - for a while it was just easier to paste in whatever `--help` said when the flags changed. That stops now.

## What It Actually Does For You

- **Installs WINE itself, if you don't have it.** Detects `apt`, `dnf`, `pacman`, or `zypper`, adds the WineHQ repo if it's missing, and installs it. No manual repo-wrangling required.
- **Builds and manages your WINE prefix.** Pick win32 or win64 (win64 by default), point it at a custom path with `-p`, or let it default to `~/Games/<GAME_FOLDER>`.
- **Handles the Microsoft plumbing.** MSVC redistributables, Mono, and Gecko are fetched and installed automatically - no digging through a game installer's submenus for DirectX and hoping for the best.
- **Keeps Vulkan translation current.** Checks GitHub for the latest DXVK/VKD3D/DXVK-NVAPI release every run and grabs it if you're behind.
- **Writes you a launcher when it's done.** One `.exe`? You get a clean starter script. Found a "boxed set" installer with multiple games bundled in (looking at you, Dishonored Collection)? You get a numbered menu instead.
- **Wraps launches in GameScope automatically**, if it's installed - including auto-detecting your primary display, so multi-monitor setups don't need manual config.
- **Won't let you run it as root.** It'll tell you so and exit rather than let you shoot yourself in the foot.

## Getting Started

```
./install.sh "GAME_FOLDER" [options]
```

| Flag | What It Does |
|---|---|
| `-h`, `--help` | Show help and quit, ignoring everything else. |
| `"GAME_FOLDER"` | Folder containing the game's `.exe`. Omit it and the script lists your options interactively. Quote it, even without spaces. |
| `-m`, `--skip-msvc` | Skip the MSVC redistributable install. |
| `-v`, `--skip-vulkan` | Skip the Vulkan/DXVK check-and-update. |
| `-p`, `--prefix "PREFIX"` | Use this WINE prefix instead of the default `~/Games/GAME_FOLDER`. Quote it. |
| `-32`, `--win32` | Create a 32-bit prefix. |
| `-64`, `--win64` | Create a 64-bit prefix (default). |

Wine prefixes can't be converted between 32- and 64-bit after the fact, so pick deliberately if you're overriding the default.

## Terminology

- **script** - the BASH script doing the actual work.
- **installer** - the Windows `.exe` (often `setup.exe`) that the game's publisher shipped.

## Folder Conventions (Read This Part)

Drop your installer `.exe` into a subfolder of wherever you're running the script from. The script assumes that subfolder's name *is* the game's install-folder name, and creates `C:\Games\<SOURCE_FOLDER_NAME>\` inside the WINE prefix to match.

MSVC redistributables are handled separately, from a `.redist` folder at the top level, alongside `install.sh` itself (included in this [repo](./.redist) for convenience). You won't need this for every game - most installers already bundle their own redists - but it's there to cover the ones that don't.

That works fine as long as the installer agrees with you about naming. Sometimes it doesn't - say you named your folder "The Game 2" but the installer defaults to "The Game - Game II". When that happens, the installer's own "Advanced Options" almost always let you override the destination path to match. The script isn't psychic; it's just consistent.

## Boxed Sets / Multi-Game Installers

Some installers install more than one game at once. If the script finds more than one `.exe` after install, it builds a menu instead of a single launcher:

```
Select a game to launch:
1) Dishonored
2) Dishonored 2
3) Dishonored: Death of the Outsider
```

The menu labels are just `echo` lines - rename them to something friendlier any time. Leave the `do_gameScope` wrapper calls alone unless you know exactly what you're changing. And if you *DO* change something, *PLEASE* make a backup first!

## Known Quirks

- The naming convention above is a convenience, not magic - mismatches happen, and you fix them via Advanced Options.
- Windows-side installer failures (bad exit codes from the actual `.exe`) aren't something the script can diagnose for you. It'll report the error code and get out of your way.
- This assumes a baseline comfort with WINE, prefixes, and reading error messages. It explains itself as it goes, but it isn't going to teach you what a WINE prefix *is* from scratch.