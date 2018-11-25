
# ADS1115 Module

The ADS1115 is a precision analog to digital converter (ADC).  It reads the voltage at an analog pin (A0-A3) and converts that voltage into a number.  

### Features
* Up to four single inputs, or compare the difference between up to 2 sets of inputs.  
* A 15 bit range (0-32767), with the 16th bit denoting sign (+ or -)
* A [programmable gain](#ads1115setgain) setting to change sensitivity
* [Sampling rate](#ads1115setrate) up to 860 samples per second 
* A [comparator](ads1115setcomparator) which can set an alert when measurements cross either a high or low threshhold. 

### Required Firmware Modules
* gpio, i2c, tmr

Further information can be found in the [Datasheet](http://www.ti.com/lit/ds/symlink/ads1115.pdf)

This module uses a lot of RAM: 12-14kB.  Always release the module as soon as you're done with it to free up that memory.  See below for example:

```Lua
-- Release the module to free up memory
ads1115 = nil
package.loaded["ads1115"] = nil
```

### ADS1115 Module Functions

| Function                                         | Reference                                    |
|--------------------------------------------------|----------------------------------------------|
| [ads1115.init()](#ads1115init)                   | Initialize ADS1115 module                    |
| [ads1115.readADC()](#ads1115readadc)             | Read a value from one of the channels        |
| [ads1115.mvolts()](#ads1115mvolts)               | Convert a value into millivolts              |
| [ads1115.setAddress()](#ads1115setaddress)       | Set the I²C address to communicate with      |
| [ads1115.setMode()](#ads1115setmode)             | Set the sampling mode (continuous or single) |
| [ads1115.setPGA()](#ads1115setpga)               | Set the voltage range to measure             |
| [ads1115.setRate()](#ads1115setrate)             | Set the sampling rate                        |
| [ads1115.setComparator()](#ads1115setcomparator) | Enable and configure the comparator          |


## ads1115.init()
Initializes I²C communication with an ADS1115 module.  Sets which pins to use for I²C sets up default measurement configuration.

and tries to automatically find the I²C address the sensor is using.

Also sets default 

#### Syntax
`ads1115.init(SDA, SCL, [i2c_address])`

#### Parameters
- `SDA` The GPIO pin to use for SDA
- `SCL` The GPIO pin to use for SCL
- `i2c_address` The I²C address of the sensor.  Valid addresses are below:

| I²C Address    | ADDR pin connection  |
|----------------|----------------------|
| 0x48 (default) | Ground (or floating) |
| 0x49           | VDD (+)              |
| 0x4A           | SDA                  |
| 0x4B           | SCL                  |

#### Returns
`true` if a sensor is found, `false` if no sensor is present on the I²C pins and address specified.

## ads1115.readADC()
Reads the ADC pins configured by `channel` and returns a 15 bit signed number that signifies the voltage.

The channel can be either single-ended (comparing an ADC pin to Ground) or differential (comparing two ADC pins).  ADC pins are those labeled A0, A1, A2, and A3.  

The number returned ranges between -32767 and 32767, with single-ended channels only returning 0-32767.  The number a voltage corresponds with is determined by the voltage range set in [setPGA()](#ads1115setpga).  For example, if the voltage range is set to +/- 4.096, then +3.3 volts on channel 0 will return 3.3 / 4.096 * 32767 = 26399.  Alternatively, if you multiply the [resolution](#ads1115setpga) by the number returned by readADC(), you will get the voltage.  

Because there is only one register on the sensor to store results in, only one channel can be read at a time.  readADC() takes care of reconfiguring the sensor to read another channel, therefore the following code (below) will work if multiple channels are required.

```Lua
-- Read channel 0
val0 = ads1115.readADC(0)

-- Read channel 1
val1 = ads1115.readADC(1)
```

Because the ADS1115 needs some time to finish measuring a sample, readADC() will not return the latest sample value in single-shot mode unless a callback function is specified.  This allows readADC() to wait until conversion is finished before returning a value through the callback function.

#### Syntax
`ads1115.readADC(channel, [function(value)])`

#### Parameters
- `channel` The ADC channel to measure.  See below for channel options.
- (optional) `function(value)` A callback function to run after conversion is finished.  This function gets the ADC value as an argument.  The amount of time before the callback function runs is dictated by the sampling rate, e.g. a sampling rate of 8 samples/second would run after 1/8 second (125 ms).  

| channel | (+) | (-)    | Type         |
|---------|:---:|:------:|--------------|
| 0       | A0  | Ground | Single       |
| 1       | A1  | Ground | Single       |
| 2       | A2  | Ground | Single       |
| 3       | A3  | Ground | Single       |
| 10      | A0  | A1     | Differential |
| 30      | A0  | A3     | Differential |
| 31      | A1  | A3     | Differential |
| 32      | A2  | A3     | Differential |


#### Returns
the value as a 15 bit signed number (-32767 to 32767), `false` if the channel was invalid, or `nil` if a callback function is specified. 

#### Example
```Lua
-- Load the module
ads1115 = require("ads1115")

-- Initialize the module with SDA = 2, SCL = 1
ads1115.init(2, 1)

-- Get a value from channel A0 and make a callback function to print the result
ads1115.readADC(0, function(val)
    print(val)
end)

-- Release the module to free up memory
ads1115 = nil
package.loaded["ads1115"] = nil
```


## ads1115.mvolts()
Converts the value passed to it to millivolts using the resolution of the current PGA setting (see [setPGA()](#ads1115setpga)).

#### Syntax
`ads1115.mvolts(value)`

#### Parameters
- `value` A value between -32767 and 32767 

#### Returns
value converted into millivolts 

#### Example
```Lua
-- Get a value from channel A0
val = ads1115.readADC(0)

-- Convert to millivolts and print
mvolts = ads1115.mvolts(val)
print(mvolts)
```


## ads1115.setMode()
Sets the sampling mode to either continuous or single shot.  

In continuous mode, the sensor repeatedly measures the configured channel, starting a new measurement as soon as the previous is finished and storing the result in the conversion register.

In single shot mode, the sensor measures the configured channel once, and then goes into power down/sleep mode where it uses minimal power.  

#### Syntax
`ads1115.setMode(mode)`

#### Parameters
- `mode` The mode to use: `"single"` for single-shot mode or `"continuous"` for continuous mode.  If anything else is specified, it defaults to continuous

#### Returns
`nil`

#### Example
```Lua
-- Set the sensor to use continuous mode
ads1115.setMode("continuous")
```


## ads1115.setPGA()
The ADS1115 has a built-in programmable gain amplifier (PGA).  This means that the sensitivity can be adjusted to measure smaller ranges of voltages at higher accuracy.  The PGA can be set anywhere from a gain of 2/3 (corresponding to +/- 6.144 volts) to a gain of 16 (corresponding to +/- 256 millivolts).  This allows for a resolution as low as 7.8 microvolts per bit at a gain of 16.  

Note that this is independent of the voltage range that the ADS1115 can actually handle.  That is specified as 0.3 volts more than the voltage the sensor is running on (VDD) or less than Gnd.  **Anything beyond VDD + 0.3 V or GND - 0.3V can damage the sensor**.  

If, for example, the sensor is configured with a gain of 16 and the ADC pin is fed 3.3V, the ADC will simply return the highest value possible (32767)

#### Syntax
`ads1115.setPGA(setrange)`

#### Parameters
- `setrange` The voltage range to set the PGA to.  See below for possible setrange settings:

| setrange        | Gain | Voltage range   | Resolution |
|:---------------:|:----:|:---------------:|:----------:| 
| 6.144 (default) | 2/3  | +/- 6.144 Volts | 0.18750 mV |
| 4.096           | 1    | +/- 4.096 Volts | 0.12500 mV |
| 2.048           | 2    | +/- 2.048 Volts | 0.06250 mV |
| 1.024           | 4    | +/- 1.024 Volts | 0.03125 mV |
| 0.512           | 8    | +/- 0.512 Volts | 0.01563 mV |
| 0.256           | 16   | +/- 0.256 Volts | 0.00781 mV |

#### Returns
`true` if the setrange was valid, `false` if the setrange was invalid

#### Example
```Lua
-- Set the PGA to use +/- 1.024 volts
ads1115.setPGA(1.024)
```


## ads1115.setRate()
This sets the number of samples to acquire per second (in continuous mode), or the length of time to take a sample (in single shot mode).  Slower rates are more precise, but use more power in single shot mode since the ADS1115 spends less time in sleep mode.  See [setMode()](#ads1115setmode) for more on the modes.  

#### Syntax
`ads1115.setRate(sampling_rate)`

#### Parameters
- `sampling_rate` The sampling rate.  See below for the possible rate settings:

| Rate<br/>(samples/second) | Sampling time<br/>(milliseconds) |
|:-------------------------:|:--------------------------------:|
| 8                         | 125                              |
| 16                        | 63                               |
| 32                        | 32                               |
| 64                        | 16                               |
| 128 (default)             | 8                                |
| 250                       | 4                                |
| 475                       | 3                                |
| 860                       | 2                                |

#### Returns
`true` if the rate was valid, `false` if the rate was invalid

#### Example
```Lua
-- Set the sampling rate to 860 samples per second
ads1115.setRate(860)
```


## ads1115.setComparator()
Enables and configures the comparator.  

The ADS1115 has a comparator function, which compares the output of one of the ADC channels to a low and high threshold.  It controls the ALERT pin, which can output a signal when certain conditions are met.  This signal can be programmed to be either HIGH (+) or LOW (-).

Two modes are provided:
* Hysteresis mode will activate when the high threshold is met and deactivate when the low threshold is met
* Window mode will activate when either the high threshold or the low threshold are met.

Both thresholds take the form of a number between -32767 and 32767 that corresponds to a voltage at the given [PGA](#ads1115setpga) setting.  For example, at +/- 6.144 Volts, a 3 volt threshold would correspond to 3 / 6.144 * 32767 = 16000.

Additionally, there is a latch function, that when enabled will keep the ALERT pin activated even after the comparator conditions are no longer met.  When latched, it can only be deactivated by taking another reading via [readADC()](#ads1115readadc) when comparator conditions are within the thresholds. 

#### Syntax
`ads1115.setComparator(mode, [low, high, latch, queue, alert])`

#### Parameters
- `mode` Comparator mode.  Set to `"hysteresis"` for hysteresis mode, `"window"` for window mode, or `"disable"` to disable the comparator.
- (optional) `low` The lower threshold for the comparator.  Must be between -32767 and 32767 and < the high threshold. Default is 0
- (optional) `high` The higher threshold for the comparator.  Must be between -32767 and 32767 and > the low threshold. Default is 32767
- (optional) `latch` Set to `true` to enable a latch or `false` (default) to disable.
- (optional) `queue` Set how many measurements must cross the threshold to trigger activation.  Valid options are `1` (default), `2`, and `4`.
- (optional) `alert` Set to `"high"` or `"low"` (default) to set whether the ALERT pin is activated as HIGH (+) or Low (-) when triggered by the comparator.


#### Returns
`true` if comparator enabled, `false` if comparator disabled and settings invalid


#### Example
```Lua
-- Load the module
ads1115 = require("ads1115")

-- Initialize the module with SDA = 2, SCL = 1
ads1115.init(2, 1)

-- Set the sensor to measure continuously
ads1115.setMode("continuous")

-- Trigger when voltage goes above 3V (3 / 6.144 * 32767 = 15999)
-- Turn off trigger when voltage goes below 2V (2 / 6.144 * 32767 = 10666)
-- Only require one measurement to cross threshold to trigger
-- Alert pin will go low when activated
-- No latching, hysteresis mode
ads1115.setComparator("hysteresis", 10667, 16000)

-- Get a value from channel A0 and print
val = ads1115.readADC(0)
print(val)

-- Release the module to free up the memory
ads1115 = nil
package.loaded["ads1115"] = nil
```
