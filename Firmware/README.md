# Firmware

The D1 Mini needs a firmware to run the EMU code we provide. This firmware called [NodeMCU](https://nodemcu.readthedocs.io) provides a command prompt, filesystem, and lua processor. The NodeMCU firmware contains more modules than are needed, and to save space, generally a subset of those modules are picked. We provide a pre-built firmware (see below) with modules selected for EMU use.

## Firmware Flashing

We recommend reading the [NodeMCU documentation](https://nodemcu.readthedocs.io/en/master/en/flash/) on firmware flashing, as the procedure may change.  


For Windows and OSX users, there is a firmware flashing tool called [nodemcu-pyflasher](https://github.com/marcelstoer/nodemcu-pyflasher), that is generally the best option for flashig the firmware to a D1 Mini.  Just download the tool, start it, select 115200 or 230400 baud, dual flash mode, and erase the flash.

Sometimes the D1 Mini will not go into flash mode while plugged into the breadboard.  In this case, removing it will allow it to flash. The nodemcu-pyflasher should put it into firmware flash mode automatically, but if this doesn't happen, it can be coerced by connecting pin D3 to Gnd and pressing the reset button on the D1 mini.

The nodemcu-pyflasher tool is just a wrapper for [esptool](https://github.com/themadinventor/esptool). On Linux, there is no release of nodemcu-pyflasher, and esptool is required instead. However, it can also be used on Windows or OSX. 

Example commands using esptool for Linux are below.  You'll have to change the port to whatever it is on your computer. See [Computer Setup](/Documentation/Computer%20Setup.md) for additional help.

```bash
# Erase the flash first
python esptool.py --port /dev/ttyUSB0 erase_flash 

# Write the firmware file to 0x0000
python esptool.py --port /dev/ttyUSB0 write_flash -fs 32m -fm dio 0x0000 
```

## Firmware Options

### nodemcu-master-17-modules-2018-09-28-14-42-18-float.bin

```
Modules: adc, bit, bme280, ds18b20, file, gpio, http, i2c, net, 
		 node, ow, rtctime, sntp, tmr, uart, wifi, ws2812

LFS disabled
SSL disabled
FatFS disabled
```

### Custom firmware

Custom firmware versions can be made easily at [nodemcu-build.com](https://nodemcu-build.com) (though there is a limit on the number of modules), or can be [built from source](https://nodemcu.readthedocs.io/en/master/en/build/).
