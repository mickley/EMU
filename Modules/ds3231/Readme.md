
# DS3231 Real Time Clock (RTC) Module

The [DS3231](https://www.maximintegrated.com/en/products/digital/real-time-clocks/DS3231.html) is an extremely accurate battery-backed Real Time Clock (RTC).  It provides a way to accurately get the current time, and provides alarms to schedule actions at specific times.  

While the module is built for the DS3231, it should also work on the [DS3232](https://www.maximintegrated.com/en/products/digital/real-time-clocks/DS3232.html).  See this [comparison of Maxim Real Time Clocks](https://www.maximintegrated.com/en/app-notes/index.mvp/id/5143) for more information.


### Features
* Two alarms that when triggered can send either a LOW output or a square wave over the alarm pin (INT/SQW)
* A 32khz square wave output on the 32kHz pin
* Battery-backed timekeeping using a CR2032 battery that lasts years, and can run the alarm outputs and square waves
* An 8-bit temperature sensor with 0.25 °C resolution and 3 °C accuracy
* This module can return the date and time in a variety of formats

### Required Firmware Modules
* i2c, rtctime

Further information on the DS3231 can be found in the [Datasheet](https://datasheets.maximintegrated.com/en/ds/DS3231.pdf)

**Note:** This module uses a lot of RAM: 12-15kB.  Always release the module as soon as you're done with it to free up that memory.  See below for example:

```Lua
-- Release the module to free up memory
ds3231 = nil
package.loaded["ds3231"] = nil
```

### DS3231 Module Functions

| Function                                             | Reference                                                |
|------------------------------------------------------|----------------------------------------------------------|
| [ds3231.init()](#ds3231init)                         | Initialize the DS3231 module                             |
| [ds3231.config()](#ds3231readadc)                    | Configure options, mostly for the outputs                |
| [ds3231.setTime()](#ds3231settime)                   | Set the current time                                     |
| [ds3231.getTime()](#ds3231gettime)                   | Get the current time                                     |
| [ds3231.setAlarm()](#ds3231setalarm)                 | Set one of the two alarms                                |
| [ds3231.changeAlarmState()](#ds3231changealarmstate) | Enable or disable an alarm                               |
| [ds3231.reloadAlarms()](#ds3231reloadalarms)         | Re-arm both alarms                                       |
| [ds3231.format()](#ds3231format)                     | Convert a numeric time into a formatted timestamp string |
| [ds3231.getTemp()](#ds3231gettemp)                   | Gets the current temperature                             |


## ds3231.init()

Initializes I²C communication with the RTC module. Sets which pins and address to use for I²C communication.

Also optionally sets the timezone offset to use for time formatting.  

#### Syntax
`ds3231.init(sda, scl, [i2c_address], [timezone])`

#### Parameters
- `sda` The GPIO pin to use for SDA
- `scl` The GPIO pin to use for SCL
- (optional) `i2c_address` The I²C address to use. Default is 0x68, and must be between 0x68 and 0x6F
- (optional) `timezone` The timezone offset to use.  Default is -5 (EST)

#### Returns
`true` if a RTC is found, `false` if no RTC is present on the I²C pins and address specified.


## ds3231.config()

Configures various settings on the DS3231 dealing with what to run while only on battery power, how to handle alarms, and set up outputs on the two output pins: INT/SQW and 32kHz.  

#### Syntax
`ds3231.config([mode], [SQRate], [BBSQW], [disableOnBatt], [disable32kHz], [BB32kHz], [TCRate])`

#### Parameters
- (optional) `mode` The alarm output mode for the INT/SQW pin.  `"INT"` will make the pin LOW if an alarm triggers.  `"SQW"` will output a square wave with the frequency set in `SQRate`.  The default is `"INT"`
- (optional) `SQRate` The frequency of the square wave for alarm-triggered square wave output.  See SQRate table below.  The default is `1`
- (optional) `BBSQW` Enables square wave output while only powered by the battery.  This applies only to the INT/SQW pin.  `true` to enable, `false` to disable.  The default is `false`
- (optional) `disableOnBatt` Disables the clock while only powered by the battery. `true` to disable, `false` to enable.  The default is `false`.  If the clock is disabled, it will stop keeping time when the main power is removed, even if a battery is present.
- (optional) `disable32kHz` Disables the constant 32.768 kHz output on the 32kHz pin. `true` to disable, `false` to enable.  The default is `false`
- (optional) `BB32kHz` **Not yet implemented** On the DS3232 this enables the 32kHz functionality while powered only by the battery.  For the DS3231, the 32kHz output works regardless of power supply when enabled.  
- (optional) `TCRate` **Not yet implemented** On the DS3232, allows changing of the interval between temperature conversions.  On the DS3231, the interval is fixed at 64 seconds.  

| SQRate | Frequency        |
---------|------------------|
| 1      | 1 Hz output      |
| 1024   | 1.024 kHz output |
| 4096   | 4.096 kHz output |
| 8192   | 8.19 2kHz output |

#### Returns
`nil`

#### Example
```Lua
-- Set alarms to trigger a LOW interrupt on the INT/SQW pin instead of a square wave
-- Disable square wave output but enable timekeeping while only on battery power
-- Disable the 32kHz output
ds3231.config("INT", nil, false, false, true)
```


## ds3231.setTime()

Sets the current date and time on the DS3231 based on the date/time parameters given.  If a 2032 battery is not installed, then the time will be lost as soon as the DS3231 loses power.  However, if a battery is installed, the DS3231 will continue keeping time from this set point.  

Ideally, set up the command for 30 seconds ahead of time and run it right as the seconds of your reference clock reachs your set point to sync to your reference clock.

#### Syntax
`ds3231.setTime(second, minute, hour, day, date, month, year)`

#### Parameters
- `second` The current seconds (0-59)
- `minute` The current minutes (0-59)
- `hour` The current hour in 24-hour time (0-23)
- `day` The current day of the week (1-7), with 1 = Sunday and 7 = Saturday
- `date` The current day of the month (1-31)
- `month` The current month (1-12)
- `year` The current year in either 2-digit or 4-digit format.


#### Returns
`nil`

#### Example
```Lua
-- Set the current date and time to Wednesday Feb 22nd 2017 16:45:15 (Wednesday = day 4 of the week)
ds3231.setTime(15, 45, 16, 4, 22, 2, 2017)
```


## ds3231.getTime()

Gets the current date and time and returns either raw numbers for seconds, minutes, hours, day of week, day of month, month, and year, or a formatted string using a modified subset of [POSIX/strftime formatting codes](https://www.gnu.org/software/libc/manual/html_node/Formatting-Calendar-Time.html).

Optionally, it can also sync the current time from the DS3231 to the [rtctime](https://nodemcu.readthedocs.io/en/master/en/modules/rtctime/) firmware module in a similar way to [sntp.sync()](https://nodemcu.readthedocs.io/en/master/en/modules/sntp/#sntpsync).  For this to work, the rtctime module is required, however if no syncing takes place, it can be left off the firmware.

#### Syntax
`ds3231.getTime([format], [sync])`

#### Parameters
- (optional) `format` The format to return the date/time in.  The default is `"raw"`.  See the format table below. With the exception of `"raw"` formats can be strung together in a string along with other characters, e.g. `"Current Time: %H:%M:%S"`.
- (optional) `sync` Sync the time with the firmware rtctime module `true` or don't sync `false`.  The default is `false`.

| format | Description                                                                                     |
---------|-------------------------------------------------------------------------------------------------|
| raw    | Returns the raw values (7 numbers starting with seconds) instead of a formatted string.         |
| %D     | Returns the date in mm/dd/yy format.  Equivalent to %m/%d/%y                                    |
| %r     | Returns the time in 12-hour AM/PM format.  Equivalent to %i:%M:%S %p                            |
| %T     | Returns the time in 24-hour format.  Equivalent to %H:%M:%S                                     |
| %f     | Returns the ISO-8601 standard format YYYY-mm-ddTHH:MM:SS+tz.  Equivalent to %Y-%m-%dT%H:%M:%S%z |
| %a     | Abbreviated day of week (3 letters)                                                             |
| %A     | Full day of week                                                                                |
| %b     | Abbreviated month name                                                                          |
| %B     | Full month name                                                                                 |
| %c     | Day of the month without leading zeros                                                          |
| %d     | Day of the month with leading zeros                                                             |
| %h     | 24-hour hours without leading zeros                                                             |
| %H     | 24-hour hours with leading zeros                                                                |
| %i     | 12-hour hours without leading zeros                                                             |
| %I     | 12-hour hours with leading zeros                                                                |
| %m     | Month with leading zeros                                                                        |
| %M     | Minutes with leading zeros                                                                      |
| %n     | Month without leading zeros                                                                     |
| %p     | AM/PM indicator (for use with 12-hour time)                                                     |
| %s     | Unix Timestamp: number of seconds since the Unix epoch: 1/1/1970 00:00:00                       |
| %S     | Seconds with leading zeros                                                                      |
| %w     | Day of week as a number (0-6) with Sunday = 0                                                   |
| %y     | 2-digit year                                                                                    |
| %Y     | 4-digit year                                                                                    |
| %z     | Timezone offset                                                                                 |
| %%     | The `%` character                                                                               |

#### Returns
`seconds, minutes, hours, day, date, month, year` if format is `"raw"` or `nil`.  Or a formatted string according to the format argument.

#### Example
```Lua
-- Load the module
ds3231 = require("ds3231")

-- Initialize the module with SDA = 1, SCL = 2
ds3231.init(1, 2)

-- Get the raw numbers for all of the date/time parameters
seconds, minutes, hours, day, date, month, year = ds3231.getTime("raw")

-- Print out the raw numbers
print(seconds, minutes, hours, day, date, month, year)

-- Only get the hours, not saving the other values
_, _, hours = ds3231.getTime("raw")

-- Print out the hours
print(hours)

-- Get a formatted time string, also syncing the current time to the rtctime module
timestring = ds3231.getTime("%D %T", true);

-- Print the formatted time string
print(timestring)

-- Don't forget to release it after use
ds3231 = nil
package.loaded["ds3231"]=nil
```


## ds3231.setAlarm()

This sets one of the two alarms on the DS3231.  Alarm #1 supports seconds precision and Alarm #2 only supports minutes precision.  

When either of the alarms trigger, they either set the INT/SQW pin LOW (INT mode) or output a square wave of 1 Hz to 8.192 kHz (SQW mode).  This behavior can be configured using [ds3231.config()](#ds3231config).  

Regardless of which trigger they use, the trigger continues to be active until [ds3231.setAlarm()](#ds3231setalarm) is called again or both alarms are re-armed using [ds3231.rearmAlarms()](#ds3231rearmalarms).

#### Syntax
`ds3231.setAlarm(alarm, alarmType, [second], [minute], [hour], [daydate])`

#### Parameters
- `alarm` The alarm to set: `1` or `2`
- `alarmType` The type/frequency of alarm to set.  See the alarmType table below.  
- (optional) `seconds` The seconds to trigger at (0-59).  Required for all alarmTypes but `ds3231.EVERYSECOND` or `ds3231.EVERYMINUTE`.  Ignored for alarm #2.  
- (optional) `minutes` The minutes to trigger at (0-59).  Required for all alarmTypes but `ds3231.EVERYSECOND`, `ds3231.EVERYMINUTE`, and `ds3231.SECOND`
- (optional) `hours` The hours to trigger at (0-23).  Required for the alarmTypes `ds3231.HOUR`, `ds3231.DAY`, `ds3231.DATE`
- (optional) `weekday/date` For the `ds3231.DAY` alarmType, this is the day of the week (1 = Sunday, 7 = Saturday).  For the `ds3231.DATE` alarmType, this is the day of the month (1-31). Only required for alarmTypes `ds3231.DAY` and `ds3231.DATE`

| alarmType          | Description                                                                                |
|--------------------|--------------------------------------------------------------------------------------------|
| ds3231.EVERYSECOND | Only works with alarm 1 and triggers every second                                          |
| ds3231.EVERYMINUTE | Only works with alarm 2 and triggers every minute (00 seconds)                             |
| ds3231.SECOND      | Triggers when time matches the seconds parameter                                           |
| ds3231.MINUTE      | Triggers when time matches the seconds and minutes parameters                              |
| ds3231.HOUR        | Triggers when time matches the seconds, minutes, and hours parameters                      |
| ds3231.DAY         | Triggers when time matches the seconds, minutes, hours, and weekday parameters             |
| ds3231.DATE        | Triggers when time matches the seconds, minutes, hours, and date (day of month) parameters |


#### Returns
`nil`

#### Example
```Lua
-- Set alarm 1 to trigger hourly at 30 minutes past the hour
ds3231.setAlarm(1, ds3231.MINUTE, 0, 30)

-- Set alarm 2 to trigger on Mondays at 8 AM
ds3231.setAlarm(2, ds3231.DAY, 0, 0, 8, 2)
```


## ds3231.changeAlarmState()

This enables or disables an alarm.  It will not reset an alarm that has already triggered.  

#### Syntax
`ds3231.changeAlarmState(alarm, enable)`

#### Parameters
- `alarm` The alarm to enable or disable: `1` or `2`
- `enable` Enable the alarm if `true`, disable if  `false`

#### Returns
`nil`

#### Example
```Lua
-- Disable alarm #1
ds3231.changeAlarmState(1, false)

-- Enable alarm #2
ds3231.changeAlarmState(2, true)
```


## ds3231.rearmAlarms()

This resets both alarms, turning off the alarm output if they have triggered.  The alarms need to remain enabled to re-trigger.

#### Syntax
`ds3231.rearmAlarms()`

#### Returns
`nil`



## ds3231.format()

Takes raw date/time values and formats them, returning a formatted date/time string.  

#### Syntax
`ds3231.format(format, second, minute, hour, dayofweek, date, month, year, [timezone], [sync])`

#### Parameters
- `format` The format to use.  Uses the same POSIX/strftime formats detailed in [ds3231.getTime()](#ds3231gettime)
- `second` The number of seconds (0-59)
- `minute` The number of minutes (0-59)
- `hour` The number of hours (0-23)
- `dayofweek` The day of the week (1 = Sunday, 7 = Saturday)
- `date` The day of the month (1-31
- `month` The month (1-12)
- `year` The year in 4-digit format
- (optional) `timezone` The timezone offset. The default is `0`
- (optional) `sync` Sync the time with the firmware rtctime module `true` or don't sync `false`.  The default is `false`.

#### Returns
`nil`

#### Example
```Lua
-- Only get the minutes, not saving the other values
seconds, minutes, hours = ds3231.getTime("raw")

-- Add 15 to the minutes
minutes = minutes + 15

-- Get the formatted time 15 minutes from now.  Doesn't matter what the last 4 values are
timestring = format("%T", seconds, minutes, hours, 1, 1, 1, 2017)
```


## ds3231.getTemp()

The DS3231 has a temperature sensor that it uses to temperature-correct its timekeeping.  This temperature sensor has ±3°C accuracy and 0.25 °C resolution, and can be be read.  

The latest temperature value is updated every 64 seconds.  On the DS3232, this is configurable from 64-512 seconds, conserving some of power with less frequent updates.  

#### Syntax
`ds3231.getTemp()`

#### Returns
The latest temperature reading in °C

#### Example
```Lua
-- Get the temperature
temp = ds3231.getTemp()

-- Print out the temperature
print(temp)
```


