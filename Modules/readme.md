# Lua Modules

The following are Lua modules we have written that are not incorporated in NodeMCU firmware. They function as libraries, allowing the EMU code to import functionality or talk to sensors, with minimal programming on the part of the user.

## Modules

* [ads1115](/Modules/ads1115/) - Analog to digital converter module for soil moisture
* [bh17150](/Modules/bh1750/) - Lux sensor module for PFD
* [csv](/Modules/csv/) - CSV module for writing data files
* [ds3231](/Modules/ds3231/) - Clock module for keeping time and waking up the EMU to measure
* [logging](/Modules/logging/) - Logging module to for keeping a log file in addition to the data file

For the EMU code to work, all five of these modules must also be uploaded to the EMU.  We also recommend [compiling them](https://nodemcu.readthedocs.io/en/dev/en/modules/node/#nodecompile) to .lc files and removing the original .lua source files, so that they take up less space and RAM while being used. You can do this in ESPlorer or via a handy [compile script](/Useful Scripts/module-compiler.lua)
