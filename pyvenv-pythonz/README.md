# PythonZ Virtual Environment Creator
This utilizes [PythonZ](https://github.com/saghul/pythonz) to create or use Python Virtual Environments (VENVs). If you have a VENV already established, but it wasn't created by this script, it won't be accessible from this script unless you change the default location this script uses. There are two ways to use this script - you can add it to your BASH source files (either /etc/bash.bashrc or $HOME/.bashrc), or you can run it as a stand-alone script - a program unto itself.

[PythonZ](https://github.com/saghul/pythonz) has a built-in dictionary of most Python releases up to 3.12.1, and even though it may complain about versions not in that dictionary, since Python uses a standardized release structure, any Python version listed [on the official Downloads page](https://www.python.org/downloads/source/), full release or pre-release, can be used.

## Running It Ztand-alone
You can save the script and run it by itself. Just be sure to `chmod +x pyvenv.sh` after downloading as GitHub doesn't save file permissions.

For stand-alone usage:

    bash {SAVE_LOCATION}/pyvenv.sh NAME VERSION

## Running It Zourced
To use as source, copy the relevant lines from the script into either the individual user's `$HOME/.bashrc` file, giving just that user access to the function, or add it to `/etc/bash.bashrc` to give all users access to it. In either case, PythonZ will run at the user level, and will install locally for the user (if not already installed). Installing PythonZ at the system level isn't recommended as it can cause problems for non-sudo-entitled users.

For source usage:

    pyvenv NAME VERSION

When supplying VERSION, it can be alphanumeric, if the version you want is. This really only applies to pre-releases, whose version numbers include "a" for alpha releases, "b" for beta releases, and "rc" for release candidates.

Error checking for versions is supplied by PythonZ, not this script, so asking for a non-existent version may cause problems.

## OptionZ and ParameterZ
For the sake of simplicity in the following examples, we'll assume you've added the relevant parts of the script to your bash source. If you're running stand-alone, simply add the appropriate prefix, noted in the section above.

### Create New VENV
Running with no parameters will prompt for both. Running with one will assume NAME was provided, and will prompt for VERSION. If both are given, the first will be assumed to be NAME and the second VERSION, and no prompt will be given:

`pyvenv`                      - ask for NAME and VERSION

`pyvenv 3.13.0`               - create VENV named "3.13.0" and ask for VERSION

`pyvenv 3120-tester 3.12.0a7` - create VENV named 3120-tester with Python version 3.12.0a7

If more than two parameters are given, the first two are used and the rest are ignored.

### Run Existing VENV
Running with no parameters will prompt for name. Running with one will assume NAME was provided, and will prompt for VERSION. If both are given, the first will be assumed to be NAME and the second VERSION, and no prompt will be given:

`pyvenv`                      - will ask for NAME

`pyvenv 3.11.9`               - enter VENV named "3.11.9"

`pyvenv 3130-tester 3.13.0rc3` - enter VENV named 3130-tester and ignore 3.13.0rc3

If more than one parameter is given, only the first is used, the rest ignored.

### How It WorkZ - The TLDR;
First, the script will check for [pythonz](https://github.com/saghul/pythonz). If it can't find it, it will attempt to install it and restart itself.
Next, it checks for NAME. If NAME doesn't exist, it makes it using Python VERSION, prompting for these values if they weren't given on the command line.
If a VENV with NAME already exists, the script attempts to activate it, and VERSION will be ignored if provided on the command line.

There is limited error checking along the way but it's not 100% fail proof. Consider this script to be in beta.

Cavaet Emptor
### The Z's
Yez, thoze are intentional Z's up there.
