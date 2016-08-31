## ads1115.init()
Initializes I²C communication with an ADS1115 module.  Sets which pins to use for I²C, tries to automatically find the I²C address the sensor is using, and sets default sensor configuration.

#### Syntax
`ads1115.init(SDA, SCL)`

#### Parameters
- `SDA` The GPIO pin to use for SDA
- `SCL` The GPIO pin to use for SCL

#### Returns
`true` if a sensor is found, `false` if no sensor is present.

## ads1115.readADC()
D

#### Syntax
`ads1115.readADC(channel)`

#### Parameters
- `channel` The ADC channel to measure.  This can be either single-ended (comparing the ADC pin to ground) or differential (comparing two ADC pins).  See below for channel options.

| channel | (+) | (-) | Type         |
|---------|:---:|:---:|--------------|
| 0       | A0  | Gnd | Single       |
| 1       | A1  | Gnd | Single       |
| 2       | A2  | Gnd | Single       |
| 3       | A3  | Gnd | Single       |
| 10      | A0  | A1  | Differential |
| 30      | A0  | A3  | Differential |
| 31      | A1  | A3  | Differential |
| 32      | A2  | A3  | Differential |


#### Returns
`true` if , `false` if 

#### Example
```Lua
-- Load the module
ads1115 = require("ads1115")

-- Initialize the module with SDA = 2, SCL = 1
ads1115.init(2, 1)

-- Get a value from channel 0
val = ads1115.readADC(0)
print(val)

-- Release the module to free up memory
ads1115 = nil
package.loaded["ads1115"] = nil
```



## ads1115.mvolts()
Converts 

####Syntax
`ads1115.mvolts(value)`

####Parameters
- `value` A value between -32767 and 32767 

####Returns
value converted into millivolts according to the resolution of the current PGA setting (see setPGA()).




## ads1115.setAddress()
D

####Syntax
`ads1115.setAddress(i2c_address)`

####Parameters
- `i2c_address` 

####Returns
`true` if , `false` if 



## ads1115.setPGA()
D

####Syntax
`ads1115.setPGA(voltage_range)`

####Parameters
- `voltage_range` 



####Returns
`true` if , `false` if 








## ads1115.setRate()
D

####Syntax
`ads1115.setRate(sampling_rate)`

####Parameters
- `sampling_rate` 

| Rate<br/>(samples/second) | Sampling time<br/>(milliseconds) |
|:-------------------------:|:--------------------------------:|
| 860                       | 2                                |
| 860                       | 2                                |
| 860                       | 2                                |
| 860                       | 2                                |
| 860                       | 2                                |
| 860                       | 2                                |

| 860                       | 2                                |


####Returns
`true` if , `false` if 




## ads1115.setComparator()
D

####Syntax
`ads1115.setComparator(low, high, queue, latch, alert, mode)`

####Parameters
- `low` The lower threshold for the comparator.  Must be between -32767 and 32767 and less than the high threshold
- `high` The higher threshold for the comparator.  Must be between -32767 and 32767 and greater than the low threshold
- `queue` 
- `latch` Set to 1 to enable a latch or 0 to disable.  This keeps the ALERT pin activated until manually turned off.
- `alert` Set to `"high"` or `"low"` to et whether the ALERT pin is activated as HIGH (+) or Low (-) when triggered by the comparator
- `mode` Comparator mode.  Set to `hysteresis` , or set to `window`

####Returns
`true` if , `false` if 

