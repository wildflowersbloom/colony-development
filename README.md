# colony development
## Overview
![alt text](https://github.com/wildflowers/colony-development/main/overview.png?raw=true)

## Expected input
### Conriguration file. (config.csv)
### Hardcoded parameters (line) number of ants per segmentation area, thresholds
## Output
## Notes to parallelize




### Prerequisites
1. matlab 2015 or later. If you are running in gnu/linux, make sure to use your local version of gclib, by starting matlab like this:
`LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6:/lib/x86_64-linux-gnu/libgcc_s.so.1 ./matlab`

2. Make sure your matlab can read the video files you are going to process. Here we provide an ogv file, and it has also be tested with avi files encoded in mjpeg. To test this, you can do `v=VideoReader('yourvideo.file');` in matlab; which should return no errors.

### Running

Use the script `main.m` in the `behavioral_var_compilation/` folder



