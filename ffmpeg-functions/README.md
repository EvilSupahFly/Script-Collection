## FFMPEG custom scripting functions for /etc/bash.bashrc or $HOME/.bashrc:
Why memorize a bunch of command-line options when you can just make a BASH function instead?

### [[shortcuts.sh](https://github.com/EvilSupahFly/Script-Collection/blob/main/ffmpeg-functions/shortcuts.sh)]:
```
    mix: Combine a video file with an audio file. Usage:
        mix VFILE_IN AFILE_IN COMBOFILE_OUT

    ffmp4: Converts any input to MP4. Usage:
        ffmp4 FILE_IN

    ffmkv: Converts any input to MKV. Usage:
        ffmkv FILE_IN

    fftrim: trims media between two timecodes. Usage:
        fftrim START_TIME END_TIME FILE_IN FILE_OUT

    ffmerge: generates list of all files of a specific for concat (i.e., .MP4). Usage:
        ffmerge TYPE
```
### [[convert-to-ps4.sh](https://github.com/EvilSupahFly/Script-Collection/blob/main/ffmpeg-functions/convert-to-ps4.sh)]:
This is a WAAAAAAAAAY more elabourate script which takes a "known good on PS4" file, saves the codec format to a text file (if the file doesn't already exist), then uses it as a dictionary to convert a second file to the same format. Why? Because I got tired of trying to play stuff from my media server on my PlayStaion 4 only to have it complain that the media isn't supported. Initially, I was using the "convert to PS4" function in `shortcuts.sh` but that didn't always work, and I never understood why. So I came up with the idea of doing this instead.

Note that for this to work properly when filenames or pathnames contain spaces, special characters, or multiple punctuation marks, you should enclose your filenames in double quotes.

If the conversion is successful, you have the option of verifying in VLC and if you're happy with the results, you can delete the original - which I would **NOT** recommend unless storage space is a problem. **THIS SCRIPT MAKES NO ATTEMPT TO VERIFY YOUR STORAGE CAPACITY. IF THERE STORAGE SPACE IS INSUFFICIENT, FFMPEG WILL FAIL DURING THE CONVERSION, CAUSING THE SCRIPT TO EXIT AUTOMATICALLY. THIS SCRIPT DOES NOT RECORD THE ERROR NUMBER GIVEN IF SOMETHING FAILS SO YOU WILL NEED TO CHECK THE APP'S OWN MESSAGES IN THE TERMINAL WINDOW.**

This script checks for both FFMPEG and VLC, and will attempt to install what's missing using some fairly thorough "What Distro Is This?" logic which theoretically supports most versions of Linux, and even MacOS, though I haven't tested it to be sure.

Function 'makePS4' takes two filenames are arguments and copies the codec metadata of SOURCE, which should be 'known good' on the PS4, and saves it to a template which it uses to convert TARGET using FFMPEG to match, ideally making a 'known-good-on-PS4' copy of TARGET.
```
     makePS4 "SOURCE" "TARGET"
```
Alternatively, if you've run 'makePS4' before, and you already have a working template, specifiying only one file will use the existing" template to convert TARGET to match the format of the file the template was originally built against.
```
     makePS4 "TARGET"
```

Usage Example using realistic paths and filenames:
```
makePS4 "/home/evilsupahfly/Movies/Attack Of The Killer Tomatoes (1978)/Attack Of The Killer Tomatoes - 1978 1080p [H264-mp4].mp4"
```
   --[ or ]--
```
makePS4 "/home/evilsupahfly/Movies/Avatar (2009)/Avatar.2009.EXTENDED.720p.BluRay.H264.AAC-RARBG.mp4" "/home/evilsupahfly/Movies/Batteries Not Included (1987)/Batteries Not Included (1987).mkv"
```

Essentially, here's how this works when you run it:
  - Checks for template.
  - If template exists, check parameters:
    - If one file is given, use template
    - If two files are given ask to update or reuse template
  - If template doesn't exist, check parameters:
    - If one file is provided, exit with fail
    - If two files are provided, create template
  - Check to be sure specified file(s) exist, and if not, exit with fail
  - Check to be sure FFMPEG and VLC are both installed:
    - If not, check distro, install accordingly, exit with fail if unsupported (unlikely but possible on Linux variants)
  - Run FFMPEG to perform conversion
  - If FFMPEG fails, exit with fail
  - If FFMPEG succeeds, check for the converted copy:
    - If missing, exit with fail
    - If present: Prompt to play in VLC, ask to delete original, act accordingly
