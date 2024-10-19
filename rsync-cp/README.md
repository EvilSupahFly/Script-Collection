# Use rsync instead of cp!
Yes, that's right! Now you can replace the `cp` command in your terminal with `rsync` instead!

Why? There are many situations in which `rsync` is faster or more advantageous, such as network shares. And even when it's not faster, it's still more informative.

To use, paste the snipet in `use-rsync-for-cp.sh` either into your `/etc/bash.bashrc` for system-wide replacement, or `$HOME/.bashrc` for single-user funcationality.

### Usage

Command structure is mostly the same as with `cp` but with with the "trailing slash behaviour" of `rsync`. 

This will copy the contents of `SOURCE` into a folder named `SOURCE` over at `DEST`:
```
cp SOURCE DEST
```



This will copy the contents of `SOURCE` into the folder named `DEST`:
```
cp SOURCE/ DEST
```


This will recursively copy the contents of `SOURCE` into a folder named `SOURCE` over at `DEST`:
```
cp -r SOURCE DEST
```


This will resursively copy the contents of `SOURCE` into the folder named `DEST`:
```
cp SOURCE/ DEST
```
