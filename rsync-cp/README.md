# Use rsync instead of cp or mv!
Yes, that's right! Now you can replace the `cp` and `mv` commands in your terminal with `rsync` instead!

Why? There are many situations in which `rsync` is faster or more advantageous, such as network shares. And even when it's not faster, it's still more informative.

To use, paste the snipet in `use-rsync-for-cp.sh` either into your `/etc/bash.bashrc` for system-wide replacement, or `$HOME/.bashrc` for single-user funcationality.

Reminder that

### Usage

Command structure is mostly the same as with `cp` but with with the "trailing slash behaviour" of `rsync`.

This will copy the contents of `SOURCE` into a folder named `SOURCE` over at `DEST`:
```
cp "SOURCE" "DEST"
```



This will copy the contents of `SOURCE` directly into the folder named `DEST` without making a `SOURCE` subfolder:
```
cp "SOURCE/" "DEST"
```


This will copy multiple `SOURCE` arguments to a single `DEST`:
```
cp -m "SOURCE_1" "SOURCE_2" "SOURCE_3" "SOURCE_4" "SOURCE_5" ... "SOURCE_n" -d "DEST"
```

Command structure for the `mv` cheat is mostly the same as with `cp`:

This will move the contents of `SOURCE` into a folder named `SOURCE` over at `DEST` and perform `rm -rf` on the original source:
```
cp "SOURCE" "DEST"
```



This will move the contents of `SOURCE` directly into the folder named `DEST` without making a "SOURCE" subfolder, and also perform `rm -rf` on the original source:
```
cp "SOURCE/" "DEST"
```


This will move multiple `SOURCE` arguments to a single `DEST`:
```
cp -m "SOURCE_1" "SOURCE_2" "SOURCE_3" "SOURCE_4" "SOURCE_5" ... "SOURCE_n" -d "DEST"
```

There's no limit for source count imposed by the wrapper itself or by bash. Building the `args`/`ARGS` array from `"$@"` never touches the kernel, so it's just memory. The actual ceiling only appears at the very last line, `rsync "${EXCLUDES[@]}" "${args[@]}"`, because that's the one point where bash does a real `execve()` to launch the external `rsync` binary. That syscall is bound by the kernel's `ARG_MAX`, and past it you get a hard `Argument list too long` failure (exit 126) before rsync even starts. I've confirmed this directly rather than reciting it from theoretical publications.

**What bounds it, concretely:**

```
getconf ARG_MAX          # kernel's total argv+environ budget, in bytes
env | wc -c               # current environment already eats into that budget
```

On my virtual test system `ARG_MAX` = 2,097,152 bytes (2 MiB), environment ≈ 680 bytes. I binary-searched the actual breaking point using 40-byte dummy path strings (a reasonable stand-in for a nested NAS directory path) against the real `rsync` binary:

- **42,780 arguments** of 40 bytes each succeeded.
- **42,781** failed with `bash: /usr/bin/rsync: Argument list too long` (exit 126).

That matches the expected accounting as each argv entry costs its string length + 1 (NUL) + 8 bytes (pointer table entry, 64-bit) against the budget, plus whatever the environment is already using.

**The Formula:**

```
max_sources ≈ (ARG_MAX − environ_bytes) / (avg_path_len_bytes + 9)  − 1
```

(the `−1` accounts for the destination itself also consuming a slot)

**Caveats worth stating:**

- `ARG_MAX` is a per-system kernel value, not a script constant. It can differ between my Mint box and something like an embedded NAS OS if the wrapper is ever invoked there directly rather than against a mounted share. Anyone using the script should run `getconf ARG_MAX` locally rather than trust a hardcoded number, assuming anyone actually has that many things they need to copy or move from the terminal.
- Environment size counts against the same budget as argv, so a heavily-populated shell environment (lots of exported functions/vars like this entire repo sconsists of) shaves a bit off the usable total.
- This is a limit on the *final rsync invocation's* combined `-x` excludes + sources + destination, not on how many sources you can list conceptually.
- For actual usage: usually just a handful of directory trees at a time. This is nowhere near reachable and it only matters if the source list were ever generated programmatically (e.g. from a `find`/glob expansion over thousands of entries).
- If someone ever did need to exceed it, the documented escape hatch is rsync's own `--files-from=FILE` (or `-`, reading from stdin), which passes source paths through a file instead of argv and sidesteps `ARG_MAX` entirely, even though I haven't wired it into the `-m` functionality.