### FFMPEG custom scripting functions for /etc/bash.bashrc or $HOME/.bashrc:

```
    mix: Combine a video file with an audio file. Usage:
        mix VFILE_IN AFILE_IN COMBOFILE_OUT

    ffmp4: Converts any input to MP4. Usage:
        ffmp4 FILE_IN

    ffmkv: Converts any input to MKV. Usage:
        ffmkv FILE_IN

    fftrim: trims media between two timecodes. Usage:
        fftrim START_TIME END_TIME FILE_IN FILE_OUT

    ffps4: Transcodes files for playback on PS4 (MP4, V=H.264, A=AAC). Usage:
        ffps4 FILE_IN

    ffmerge: generates list of all files of a specific for concat (i.e., .MP4). Usage:
        ffmerge TYPE
```

Why memorize a bunch of command-line options when you can just make a BASH function instead?
