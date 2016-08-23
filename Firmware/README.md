## Firmware Flashing

Firmware flashing is tricky.  I recommend reading the [NodeMCU documentation](https://nodemcu.readthedocs.io/en/master/en/flash/) on this, as it may change.  

Using [esptool](https://github.com/themadinventor/esptool) seems to be the best option.  

You can build custom firmwares here: [https://nodemcu-build.com/](https://nodemcu-build.com/).  There seems to be a limit of 29 modules, and really large firmwares (> 580kb) may not work.

The commands I'm using with esptool are below.  You'll have to change the port to whatever it is on your computer

```bash
# Erase the flash first
python esptool.py --port /dev/cu.wchusbserialfa130 erase_flash 

# Write the firmware file to 0x0000 and the esp_init_data_default file to 0x3fc000
python esptool.py --port /dev/cu.wchusbserialfa130 write_flash -fs 32m -fm dio 0x0000 Firmware/nodemcu-1.5.4.1-master-29-modules-floatSSL.bin 0x3fc000 Firmware/esp_init_data_default-1.5.4.1.bin 

```

The current firmware we're using has the following setup:
```
Modules: adc, bit, bme280, bmp085, cjson, crypto, encoder, enduser_setup, file, gpio, http, i2c, mdns, mqtt, net, node, perf, pwm, rtcfifo, rtcmem, rtctime, sntp, spi, tmr, tsl2561, u8g, uart, ucg, wifi.

u8g: ssd1306_128x64_i2c display (though it works on the 64x48)
u8g fonts: font_5x8, font_6x10, font_7x13, font_9x15_78_79, font_9x15, font_chikita

ucg: ILI9341 display
```
