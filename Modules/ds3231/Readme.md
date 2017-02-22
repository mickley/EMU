
# DS3231 Real Time Clock Module

The [DS3231](https://www.maximintegrated.com/en/products/digital/real-time-clocks/DS3231.html) is an extremely accurate battery-backed Real Time Clock.  It provides a way to accurately get the current time, and provides alarms to schedule actions at specific times.  

While the module is built for the DS3231, it should also work on the [DS3232](https://www.maximintegrated.com/en/products/digital/real-time-clocks/DS3232.html).  See this [comparison of Maxim Real Time Clocks](https://www.maximintegrated.com/en/app-notes/index.mvp/id/5143) for more information  


### Features
* Two alarms that when triggered can send either a low output or a square wave over the alarm pin
* A 32khz square wave output
* Battery-backed operation using a 2032 battery that lasts years, and can run the alarm outputs
* Leap year compensation up to 2100
* An 8-bit temperature sensor
* This module can return the date and time in a variety of formats

### Required Firmware Modules
* i2c

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
| [ds3231.format()](#ds3231format)                     | Convert a numeric time into a formatted timestamp string |
| [ds3231.setAlarm()](#ds3231setalarm)                 | Set one of the two alarms                                |
| [ds3231.reloadAlarms()](#ds3231reloadalarms)         | Re-enable both alarms                                    |
| [ds3231.changeAlarmState()](#ds3231changealarmstate) | Enable or disable an alarm                               |
| [ds3231.getTemp()](#ds3231gettemp)                   | Gets the current temperature                             |

