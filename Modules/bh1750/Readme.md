
# BH1750FVI Module

The BH1750FVI is a digital 16-bit ambient light sensor with a dynamic range up to 121,556 lux, and a sensitivity as fine as 0.11 lux.

The BH1750FVI has a spectral response of 400–720 nm with peak sensitivity between 470–650 nm, that provides a good approximation of the range of PFD sensors for measuring PAR.

It uses the I²C protocol [BH1750FVI Datasheet](https://www.mouser.com/ds/2/348/bh1750fvi-e-186247.pdf)

### Features
* Maximum range of 121,556 lux
* Maximum sensitivity of 0.11 lux
* Minimum measurement time of 11 ms
* Adjustable range, sensitivity, and measurement time
* Continuous or single measurements


### LCD Module Functions

| Function                                                 | Reference                                   |
|----------------------------------------------------------|---------------------------------------------|
| [bh1750.init()](#bh1750init)                             | Initialize the BH1750 sensor                |
| [bh1750.getLux()](#bh1750getlux)                         | Get a light measurement from the sensor     |
| [bh1750.setMode()](#bh1750setmode)                       | Set the sampling mode for the sensor        |
| [bh1750.setMeasurementTime()](#bh1750setmeasurementtime) | Set the sensor measurement time/sensitivity |
| [bh1750.on()](#bh1750on)                                 | Turn on the sensor                          |
| [bh1750.off()](#bh1750off)                               | Turn off the sensor                         |
| [bh1750.reset()](#bh1750reset)                           | Reset the stored light measurement          |


## bh1750.init()
Initializes I²C communication with a BH1750 sensor.  Sets which pins and address to use for I²C communication.

Also turns on the sensor, and sets the default settings.

#### Syntax
`bh1750.init(SDA, SCL, [i2c_addr], [sensor_mode])`

#### Parameters
- `SDA` The GPIO pin to use for SDA
- `SCL` The GPIO pin to use for SCL
- (optional) `i2c_addr` The I²C address to use.  Default is 0x23, and must be either 0x23 or 0x5C
- (optional) `sensor_mode` The sensor measurement mode, see table below. Defaults to Continuous_H

| Mode          | Measurement |Resolution | Neasurement Time |
|---------------|-------------|-----------|------------------|
| Continuous_H  | continuous  | 1 lux     | 180 ms           |
| Continuous_H2 | continuous  | 0.5 lux   | 180 ms           |
| Continuous_L  | continuous  | 4 lux     | 24 ms            |
| OneTime_H     | single      | 1 lux     | 180 ms           |
| OneTime_H2    | single      | 0.5 lux   | 180 ms           |
| OneTime_L     | single      | 4 lux     | 24 ms            |

#### Returns
`true` if a bh1750 sensor is found, `false` if no sensor is present on the I²C pins and address specified.


## bh1750.getLux()

Prints text to the LCD.  You can optionally specify a start position to start printing.  Printing otherwise defaults to [0,0] or the next position in the current row.

#### Syntax
`bh1750.getLux([callback_func])`

#### Parameters
- (optional) `callback_func` A callback function to run after the measurement is completed. The amount of time before the callback function runs is dictated by the sensor mode and measurement time settings, and follows the max value from the datasheet for measurement time, scaled by the MT setting (180 ms default).

#### Returns
Three parameters: `lux, validity, raw`, or `nil` if a callback function is specified. `lux` is the value in lux rounded to 2 decimals that is `false` if the sensor cannot be read. `validity` is a true/false value on whether the sensor value can be trusted (not out of range). `raw` is the raw 16-bit value from the sensor (see datasheet).

When a callback function is run, it is passed the same three parameters: `lux, validity, and raw`.

#### Example
```Lua
-- Load the module
bh1750 = require("bh1750")

-- Initialize the module with SDA = 1, SCL = 2, 0x23 I2C address, and OneTime_H mode
bh1750.init(1, 2, 0x23, OneTime_H)

-- Get the lux value, validity, and raw value from the sensor
bh1750.getLux(function(lx, validity, raw)
    print(lx, validity, raw)
end)

-- Release the module to free up memory
bh1750 = nil
package.loaded["bh1750"] = nil
```


## bh1750.setMode()
Sets the measurement mode of the sensor.  There are three measurement modes that can be configured to either measure continuously, or once on request.

#### Syntax
`bh1750.setMode(sensor_mode)`

#### Parameters
- `sensor_mode` The sensor measurement mode, see table below. Defaults to Continuous_H

| Mode          | Measurement |Resolution | Neasurement Time |
|---------------|-------------|-----------|------------------|
| Continuous_H  | continuous  | 1 lux     | 180 ms           |
| Continuous_H2 | continuous  | 0.5 lux   | 180 ms           |
| Continuous_L  | continuous  | 4 lux     | 24 ms            |
| OneTime_H     | single      | 1 lux     | 180 ms           |
| OneTime_H2    | single      | 0.5 lux   | 180 ms           |
| OneTime_L     | single      | 4 lux     | 24 ms            |


#### Returns
`nil`


## bh1750.setMeasurementTime(MT)

The BH1750 has a setting to adjust the sensor measurement time.  This affects the sensitivity of the sensor, allowing fine-tuning of the sensor's tradeoff between resolution and dynamic range.

By adjusting this setting, resolution can be increased to 0.11 lux, range to 121,556 lux, and measurement time can be decreased to ~11 ms

#### Syntax
`bh1750.setMeasurementTime(MT)`

#### Parameters
- `MT` A scaling parameter for the measurement time.  The default in all modes is 69, and the range can be any integer between 31 (shorter measurement time, less sensitive) and 254 (longer time, more sensitive).  See the table below for examples of how these extremes affect resolution and range.  

| Mode           | MT  | Resolution | Range         | Measurement Time | Default |
|----------------|-----|------------|---------------|------------------|---------|
| Continuous_H   | 69  | 0.83 lux   |  54612.50 lux | 180 ms           | Default |
| Continuous_H   | 31  | 1.85 lux   | 121556.85 lux | 81 ms            |         |
| Continuous_H   | 254 | 0.23 lux   |  14835.68 lux | 663 ms           |         |
| Continuous_H2  | 69  | 0.42 lux   |  27306.85 lux | 180 ms           | Default |
| Continuous_H2  | 31  | 0.93 lux   |  60778.43 lux | 81 ms            |         |
| Continuous_H2  | 254 | 0.11 lux   |   7417.84 lux | 663 ms           |         |
| Continuous_L   | 69  | 3.33 lux   |  54610.00 lux | 24 ms            | Default |
| Continuous_L   | 31  | 7.42 lux   | 121551.29 lux | 11 ms            |         |
| Continuous_L   | 254 | 0.91 lux   |  14835.00 lux | 89 ms            |         |


Parameters for additional values of MT can be calculated with the following formulae:
Measurement time: `180 * MT / 69`
Resolution (H): `1 / 1.2 * 69 / MT`
Range (H): `65535 / 1.2 * 69 / MT`

For H2 mode, resolution and range are further divided by 2. For L mode, resolutions are multiplied by 4, measurement time is scaled from 24 ms instead of 180, and the max raw value for calculating range is 65532.


#### Returns
`nil`


## bh1750.on()
Powers on the sensor the sensor, current draw when on is 120-190 µA.

#### Syntax
`bh1750.on()`

#### Parameters
- None

#### Returns
`nil`


## bh1750.off()
Powers down the sensor, current draw when off is less than 1.0 µA. When powered down, the reset command will not work.

#### Syntax
`bh1750.off()`

#### Parameters
- None

#### Returns
`nil`


## bh1750.reset()
Resets the light measurement stored on the sensor to 0.

#### Syntax
`bh1750.reset()`

#### Parameters
- None

#### Returns
`nil`





