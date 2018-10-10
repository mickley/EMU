# EMU Software

Here, we provide the software for the EMUs.  These should be uploaded to the EMU (see [EMU Programming](Documentation/EMU%20programming.md).  The config.lua (below) should be customized for each EMU.

There are three EMU-specific code files:

1. [init.lua](init.lua) - This runs at startup automatically
2. [config.lua](config.lua) - This stores configuration information, and can be edited by the user for each EMU
3. [measure.lua](measure.lua) - This reads the sensors and logs the data

In addition to these EMU-specific code files, five [lua modules](/Modules/) are required: [ads1115](/Modules/ads1115), [bh1750](/Modules/bh1750), [csv](/Modules/csv), [ds3231](/Modules/ds3231), and [logging](/Modules/logging).

The code requires a [firmware](/Firmware) with the following firmware modules: adc, bme280, file, gpio, i2c, node, rtctime, tmr, and uart. We provide a [pre-built firmware](/Firmware/nodemcu-master-17-modules-2018-09-28-14-42-18-float.bin) with all of these included.
