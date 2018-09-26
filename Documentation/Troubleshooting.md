# Troubleshooting

Through experience, we have found that the complicated nature of EMU circuitry and frequent use of students without prior electronics experience often leads to problems.  Nearly all of these are apparent before deploying in the field, even with multiple testing. We find that the best defense is frequent quality checks at each step: this is often more efficient than troubleshooting, which is not always trivial. A wire plugged in the wrong address can produce complex symptoms, and is not easy to spot.

The following are common problems we have encountered, and some suggestions on how to fix them. We provide a [sensor-tester.lua](/Useful%20Scripts/Testers/sensor-tester.lua) script, that can run a number of checks on a completed EMU.  Additionally, there are individual [tester scripts](/Useful%20Scripts/Testers/) for each of the sensors.

We also recommend running a completed EMU in the lab, or even ourdoors for up a few days to a week before deploying in the field.

## Problems Identified by [sensor-tester.lua](/Useful%20Scripts/Testers/sensor-tester.lua)

- **D1 Mini resets while running sensor-tester**
  - Suspect a sensor wiring problem shorting out one of the sensors
    - Remove all sensors, and plug in one at a time.  
    - Check that the wiring colors are as they should be
  - A sensor may also be defective
- **BME280**
  - BME280: FAIL - No sensor detected
    - Check the wiring to the BME280, and to the clock and other sensors (shared wiring)
    - The BME280 may be defective
  - BME280: FAIL - Sensor detected, some measurements invalid
    - The BME280 may be defective
    - Humidity measurements (and temperature to a lesser extent) sometimes fail when the sensor is wet.
  - BME280: FAIL - BMP280 detected instead
    - The BME280 module you are using has the wrong chip installed.  The BMP280 chip (which is rectangular, not square) does not include humidity measurements, but is otherwise the same.
- **BH1750**
  - BH1750: FAIL - Lua Module not present
    - Upload and compile the lua module
  - BH1750: FAIL - No Sensor Found
    - Check the wiring to the BH1750, and to the clock and other sensors (shared wiring)
    - The BH1750 may be defective
  - BH1750: FAIL - Lux out of Range
    - Unless the sensor is in very bright light, the sensor is defective, it is returning the max reading.
- **DS3231**
  - DS3231: FAIL - Lua Module not present
    - Upload and compile the lua module
  - DS3231: FAIL - No Clock Detected
    - Check the wiring to the clock, and to the sensors (shared wiring)
    - The clock may be defective
  - DS3231: FAIL - Time Not Set
    - Set the time on the clock
    - Check to make sure the clock is maintaining time after setting it
    - Check the clock battery
- **ADS1115**
  - ADS1115: FAIL - No Sensor Found
    - Check the wiring to the ADS1115, and to the clock and other sensors (shared wiring)
    - The ADS1115 may be defective
  - ADS1115: Ch0 FAIL - Measurement low:
    - The soil moisture probe module may not be connected to the breadboard/ADS1115
      - This results in readings in the 5000 range
      - Connect the wiring to the soil moisture module
    - The breadboard connections or wiring may be loose
      - This results in readings in the 20000-24000 range
      - Rewire or replace the breadboard
      - Make sure the voltage to the soil moisture module is ~3.3v
  - ADS1115: Ch0 FAIL - Measurement high:
    - Usually this is caused by supplying the wrong voltage to the soil moisture module
      - It should get 3.3v from F21, not the battery voltage of 5-6v


## Errors and Warnings in the EMU's Logfile

- **Code errors:** An unforseen error in the code was caught
  - Often these are coding/syntax errors
  - main() function failed, sleeping
    - The error is in the main function
  - startup() function failed, sleeping
    - The error is in the startup function
- **Module loading errors:** various effects.  
  - Make sure the module is saved and compiled on the D1 Mini. Sometimes they can get corrupted, so re-save.
  - Loading logging module failed, sleeping
    - This error cannot be saved to the logfile and is only printed out on the terminal
    - It puts the D1 Mini to sleep without measuring
  - Loading ds3231 module failed, sleeping
    - It puts the D1 Mini to sleep without measuring
  - Loading csv module failed
    - Measurements are taken, but the data will not be logged
  - Loading bh1750 module failed
    - Measurements will not be taken for the BH1750 sensor
  - Loading ads1115 module failed
    - Measurements will not be taken for the soil moisture sensor
- **Clock errors:** All of these will result in no measurement, and the D1 Mini will go to sleep rather than turn off
  - No DS3231 clock found
    - Defective clock or improper wiring
    - Check the clock wiring for incorrect or loose connections
  - Clock time not set
    - Set the clock time
    - Check that the clock isn't faulty.  Does it keep time and maintain time via battery when power is off?
    - Check that the clock battery is not dead
- **Sensor errors and warnings**
  - No BME280 sensor found
    - Defective BME280 sensor, or wiring problems
  - No BH1750 sensor found
    - Defective BH1750 sensor, or wiring problems
  - No ADS1115 ADC found
    - Defective ADS1115 module, or plugged in the breadboard at the wrong place
  - Some measurements nil for BME280
    - A BME280 sensor is detected, but did not return values for some or all variables
    - Note: this can happen temporarily when the sensor is wet, especially for humidity readings
  - No measurement for BH1750
    - A BH1750 sensor is detected, but cannot be read. Likely that the sensor is defective, but could also be wiring.
  - BH1750 lux measurement out of range
    - A BH1750 sensor is detected and returned a value, but the value is the max 121556 lux. Unless in very bright sunlight, this indicates a defective sensor.
  - No soil moisture measurement from ADS1115
    - The ADS1115 is detected, but did not return a measurement. Likely a defective module, but could also be wiring between the soil moisture probe module and the ADS1115


## Miscellaneous Problems

- **Connecting to USB immediately shuts down computer, or computer warns about USB port power draw**
  - There is a short circuit somewhere on the breadboard or the D1 Mini itself: (+) and (-) are connected
- **Code starts running and then the D1 Mini resets without finishing the logging**
  - There is a short circuit somewhere, likely with the wires to one of the sensors or the clock
    - Generally, the reset/panic happens when trying to read the sensors
    - One of the sensors may be wired or plugged in incorrectly
- **Nothing turns on when the battery pack is switched on**
  - Check the voltage and switch of the battery pack
    - Voltage should be at least 3.5-4v (4xAA with new batteries should be 6.4v)
    - Switch should turn power on and off
  - Did the box recently log?  Wait until the next 15-minute interval
    - The clock alarm may be armed, turning off the power
    - If this is the case, you can trigger a logging event manually: connect A15 to ground to turn on the MOSFET.
  - Make sure the alarm wire from the clock is plugged into the breadboard at the MOSFET (E15-E18)
  - Check to make sure that the clock's time is set correctly
    - Make sure that it is not off by more than a few seconds
- **Blue LED on D1 Mini flashes rapidly**
  - This is usually an improper grounding/power problem, that can be difficult to fix
    - If you eavesdrop with a usb-to-serial connection without applying power, you'll see a bunch of debug/reset garbage come over the terminal
      - For example, using the CP2102 module mentioned in the parts list
      - Connect ground to ground, TX to RX, and RX to TX.
  - Inspect the ground wires plugged into A2, A11, and C2-C11
  - Inspect the soldering of the ground pin on the D1 Mini
  - Run a dupont wire between the ground rail on the 5V side and the ground pin at the top of the D1 Mini
  - Make sure the voltage of the battery pack is > 4V and ideally > 4.3-4.4v
  - As a last ditch effort, use a different breadboard
  - Another possible problem would be a coding error causing an immediate reset (usually in init.lua)
    - Try eavesdropping with a usb-to-serial connection to diagnose
    - Delete init.lua and save the file to the D1 Mini again, or reflash the firmware
- **After logging measurements, nothing turns off**
  - Check to make sure pin D5 is not connected to ground, which stops code from running
  - Check to make sure there is a 100k pullup resistor between D5 and 3.3V breadboard rail
  - Make sure you're on battery power and not on USB power.  The D1 Mini won't turn off on USB power
  - If the blue light on the D1 Mini flashes sporadically, the D1 Mini is resetting
    - This could be because of code errors or possibly sensor problems/corrosion
  - Several types of errors will cause the D1 Mini to go to sleep, but not the sensors.  Clock and soil moisture LEDs will stay on.
    - Problems with the clock
    - Errors in the lua code or the logfile module
  - You can use a usb-to-serial chip to eavesdrop on the D1 Mini while on battery power
    - Connect ground to ground, TX to RX, and RX to TX.  
    - Don't connect voltage from the usb to serial
- **D1 Mini runs and logs but does not wake up at the next 15-minute interval**
  - Make sure the clock and clock battery are not defective
  - Make sure the clock's time is set and it is maintaining time
  - Inspect and test the clock wiring
  - Make sure the single wire from the clock is plugged into the breadboard in the proper place in front of the MOSFET
  - Check the log file for any errors and make sure it is actually running correctly.  
- **LEDs on clock/soil moisture board glow weakly and don't turn off when on battery power**
  - The clock module has not been prepared properly.  Remove the middle 4.7k resistor block
- **Filesystem problems**
  - These may manifest as panics/crashes when loading the csv or logging modules.
  - Or problems reading or writing to files
  - Or troubles downloading Filesystem
  - Try re-uploading the csv and logging modules and starting fresh with the csv and log files (delete old ones)
  - Sometimes the only way to fix it is to re-flash the firmware and re-upload the software