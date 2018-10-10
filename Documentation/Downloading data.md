# Downloading Data From EMUs

For most simple cases, ESPlorer works fine for downloading data files that an EMU generates. 

## ESPlorer Instructions

1. Connect ESPlorer to the EMU (see [EMU Programming](EMU%20programming.md) )
2. Click on the Reload button in the right sidebar.  This should list the files on the EMU.
3. Right click on a filename in the sidebar and select Download
2. Note: downloading a file sometimes fails in ESPlorer, especially with larger files. Sometimes trying again works, as does using View or Edit instead of Download, or changing the baud rate in ESPlorer from 115200 to 230400 for faster download.

## Nodemcu-uploader Instructions
We often find that using [nodemcu-uploader](https://github.com/kmpm/nodemcu-uploader/blob/master/doc/USAGE.md) from a command prompt or terminal is more efficient for downloading files from many EMUs. To download a file run: `nodemcu-uploader --port COM7 --baud 230400 download EMU-data.csv` (replace COM7 and the filename with whatever port and file is required for your setup). One could also script this process.
