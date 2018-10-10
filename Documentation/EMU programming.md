# Programming EMUs

Programming an EMU requires two steps
1. the D1 Mini must have a firmware operating system flashed to it
2. Our code must be uploaded, generally using ESplorer

## Flashing the firmware

Using nodemcu-pyuploader or esptool (see [Computer setup](Computer%20setup.md)), flash the firmware to the D1 Mini while connected to the computer. See the [firmware flashing instructions](/firmware/Readme.md) for more details.

Note: Sometimes a D1 Mini is not able to set itself in firmware flashing mode when connected to the rest of the EMU.  We recommend taking it off the breadboard first. You can also force it into firmware-flashing mode by connecting pin D3 to GND and pressing the reset switch. Remove the connection when finished.

## Connecting to the EMU with ESPlorer

1. Click the blue circle-arrow button at the top right side of ESPlorer.  This refreshes the list of available serial/COM ports
2. Select the COM port that corresponds to the connected EMU (see [Computer setup](/Documentation/Computer%20setup.md)) for how to identify which one this is. 
3. Ensure that the baud/connection speed beside the Open button is set to 115200
4. Click open.  You may have to reset the EMU (press the tiny button beside the USP connector) for any output to show up on the screen
5. Note: if the EMU already has code on it, that code will begin to run when you reset the EMU.  In that case, click the Abort Snippet button below the commandline output (this needs to be set up manually, [Computer setup](/Documentation/Computer%20setup.md)), or connect a wire between D7 and Ground.

Once these steps are completed, you are connected to the EMU.  You can run code directly by typing it in the box at the bottom right of the ESPlorer window and clicking Send.  Or, you can open or create a script file in the left pane, type code in there, and send it to the EMU using the Block or Line buttons below the Settings tab.  You can send a whole script file to the EMU for execution using the Send to ESP button, or upload a file using the Save to ESP or Upload buttons.

## Uploading Code

The software to run an EMU consists of [Modules](/Modules/), libraries that we have written to interface with sensors or write out data, a script that takes measurements from all the sensors, and a startup system.  All of the following files need to be uploaded to an EMU in order for it to work correctly.  We recommend uploading them in the order they appear below to minimize problems.

**[Modules](/Modules/)**
* [ads1115](/Modules/ads1115/) - Analog to digital converter module for soil moisture
* [bh17150](/Modules/bh1750/) - Lux sensor module for PFD
* [csv](/Modules/csv/) - CSV module for writing data files
* [ds3231](/Modules/ds3231/) - Clock module for keeping time and waking up the EMU to measure
* [logging](/Modules/logging/) - Logging module to for keeping a log file in addition to the data file

After you have uploaded a module, compile it by clicking the Save&Compile button or by running `node.compile("modulename.lua")`.  You can then delete the .lua file

**[EMU-Software](/EMU-Software/)**
* [config.lua](/EMU-Software/config.lua) - This script just sets a few configuration variables that are available for the main script.  We use it to set the time interval for measurements, the timezone, logging verbosity, and the data and log filenames for each EMU. This should be customized for each EMU.
* [init.lua](/EMU-Software/init.lua) - This is a special script, that if present, is run by default by the firmware.  Ours is carefully written to prevent errors and to give the user some ways to exit the code in case there is a problem (connecting D7 to ground or setting abort=1).  Without these failsafes, code could crash, restart, and crash again endlessly, requiring a new firmware.
* [measure.lua](/EMU-Software/measure.lua) - This script does all the work of taking a measurement: reading the sensors and logging the data

The init.lua file should not be compiled.  The other two scripts: config.lua and measure.lua are assumed to not be compiled, though they could be.  One would just need to change the name to .lc where they are loaded in init.lua.

Once all code is uploaded, and the D1 Mini is connected to the EMU breadboard, resetting the D1 Mini should result in it taking a measurement.  If logging is enabled, there should be output shown on the command prompt of ESPlorer
