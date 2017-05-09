## Firmware Flashing

I recommend reading the [NodeMCU documentation](https://nodemcu.readthedocs.io/en/master/en/flash/) on firmware flashing, as it may change.  

Using [esptool](https://github.com/themadinventor/esptool) seems to be the best option.  There is a wrapper GUI program called [NodeMCU Flasher](https://github.com/mickley/Ecological-Sensors/releases) for both windows and osx that you can download.

You can build custom firmwares here: [https://nodemcu-build.com/](https://nodemcu-build.com/).  There is a limit of 24 modules.

The commands I'm using with esptool on OSX are below.  You'll have to change the port to whatever it is on your computer. 

```bash
# Erase the flash first
python esptool.py --port /dev/cu.wchusbserialfd120 erase_flash 

# Write the firmware file to 0x0000
python esptool.py --port /dev/cu.wchusbserialfd120 write_flash -fs 32m -fm dio 0x0000 nodemcu_mickley_float_dev_2017-05-08_25-modules.bin
```

## Firmware Options

### nodemcu_mickley_float_dev_2017-05-08_25-modules.bin
This is the firmware we're currently using
```
Modules: adc, bit, bme280, coap, cron, crypto, file, gpio, 
         hdc1080, http, hx711, i2c, net, node, ow, pwm, rtctime,
         si7021, sjson, sntp, spi, tmr, u8g, uart, wifi

u8g: ssd1306_128x64_i2c display (though it works on the 64x48)
u8g fonts: font_5x8, font_6x10, font_7x13, font_9x15

SSL disabled
FatFS disabled
```
