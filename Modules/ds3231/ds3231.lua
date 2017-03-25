--[[ 

##### DS3231/DS3232 Real Time Clock module #####

These are temperature-compensated and highly accurate real time clocks.
They have two alarms with interrupt support and can also output a square wave
Very low current draw when on battery

See the Datasheets for more information:
https://datasheets.maximintegrated.com/en/ds/DS3231.pdf
https://datasheets.maximintegrated.com/en/ds/DS3232.pdf

Based on the nodemcu lua module for DS3231, but with many improvements:
https://github.com/nodemcu/nodemcu-firmware/tree/master/lua_modules/ds3231

##### Public Function Reference #####
* init()
* config()
* setTime()
* getTime()
* format()
* rearmAlarms()
* changeAlarmState()
* getTemp()


##### Required Firmware Modules #####
i2c, rtctime

##### Max RAM usage: 14.7Kb #####

##### Version History #####
- 12/11/2016 JGM - Version 0.1:
    - Initial version

- 12/12/2016 JGM - Version 0.5:
    - New format() function that POSIX formats times and dates
    - Timestamp() is now part of format()
    - Small optimizations

- 1/14/2017 JGM - Version 1.0:
    - Got rid of the chip-version of 12-hr time format. 
      Using the format() function means we can keep the chip in 
      24-hr time and still return 12-hr time.  
    - Also, this maintains code compatibility with the nodemcu 
      ds3231 module

- 2/22/2017 JGM - Version 1.1:
    - Fixed several small bugs

- 3/9/2017 JGM - Version 1.2:
    - Added module version printout

--]]


-- ############### Module Initiation ###############


-- Make a table called M, this becomes the class
local M = {}


-- ############### Local variables ###############


-- Local variables to store various settings
local address, timezone
local i2c_id = 0
local version = 1.2


-- ############### Alarm Type Constants ###############


-- Possible alarm types
M.EVERYSECOND = 1
M.EVERYMINUTE = 2
M.SECOND = 3
M.MINUTE = 4
M.HOUR = 5
M.DAY = 6
M.DATE = 7


-- ############### Private Functions ###############


-- I²C function to write up to 7 bytes to a register on the device
-- We use this to write time, alarm, and configuration options
local function writeRegister(register, byte1, byte2, byte3, byte4, byte5, byte6, byte7)

    -- Send an I²C start condition
    i2c.start(i2c_id)

    -- Setup I²C address in write mode
    i2c.address(i2c_id, address, i2c.TRANSMITTER)

    -- Write the register address we'd like to write to
    i2c.write(i2c_id, register)
    
    -- Write the first byte
    i2c.write(i2c_id, byte1)

    -- Write the additional bytes if specified
    if byte2 then i2c.write(i2c_id, byte2) end
    if byte3 then i2c.write(i2c_id, byte3) end
    if byte4 then i2c.write(i2c_id, byte4) end
    if byte5 then i2c.write(i2c_id, byte5) end
    if byte6 then i2c.write(i2c_id, byte6) end
    if byte7 then i2c.write(i2c_id, byte7) end

    -- Send an I²C stop condition
    i2c.stop(i2c_id)

end


-- I²C function to read values from a register on the device
-- We use this to read time, alarm, status, and configuration
local function readRegister(register, numBytes)

    -- Send an I²C start condition
    i2c.start(i2c_id)

    -- Setup I²C address in write mode
    i2c.address(i2c_id, address, i2c.TRANSMITTER)

    -- Write the register address we'd like to read from
    i2c.write(i2c_id, register)

    -- Send an I²C stop condition
    i2c.stop(i2c_id)

    -- Send an I²C start condition again
    i2c.start(i2c_id)

    -- Setup I²C address in read mode
    i2c.address(i2c_id, address, i2c.RECEIVER)

    -- Receive bytes from the register specified
    local bytes = i2c.read(i2c_id, numBytes)

    -- Send an I²C stop condition
    i2c.stop(i2c_id)

    -- Return the string of bytes received
    return bytes

end


-- Converts numbers to binary coded decimal format
-- This is how times are stored in the registers
local function decToBCD(val)

    -- If a value isn't defined, return 0
    if val == nil then return 0 end

    -- Put the tens in the first 4 bits, and the ones in the last 4 bits
    local tens = val / 10
    return (tens - tens % 1) * 16 + val % 10
end


-- Converts binary coded decimal format to numbers
-- This is how times are stored in the registers
local function bcdToDec(val)

    -- Convert val to number as it'll usually be a string coming from string.byte()
    val = tonumber(val)

    -- Get the tens from the first 4 bits, and the ones from the last 4 bits
    local tens = val / 16
    return (tens - tens % 1) * 10 + val % 16
end


-- ############### Public Functions ###############


-- Initialize the RTC module
function M.init(sda, scl, addr, tz)

    -- If address is specified, check if it's between 0x68 and 0x6F
    -- Defaults to 0x68
    address = addr ~= nil and addr or 0x68

    -- Check if it's a valid timezone, default to -5 (EST/NY)
    timezone = tz ~= nil and tz or -5

    -- Initialize the I²C bus using the specified pins
    i2c.setup(i2c_id, sda, scl, i2c.SLOW)

    -- Send an I²C start condition
    -- Test to see if the I²C address works
    i2c.start(i2c_id)

    -- Setup the I²C address in write mode and return any acknowledgment
    local test = i2c.address(i2c_id, address, i2c.TRANSMITTER)

    -- Send an I²C start condition
    i2c.stop(i2c_id)

    -- If we got an acknowledgement (test = true) then we've found the device
    return test

end


-- Configure options for the RTC: mostly square wave and interrupt outputs
function M.config(mode, SQRate, BBSQW, disableOnBatt, disable32KHz, BB32KHz, TCRate)

    local cfg, status

    -- Set the config register bits

    -- Get the current config register, and remove all but the alarm enable bits
    cfg = string.byte(readRegister(0x0E, 1), 1) % 4

    -- Bit 2: When 1, alarm interrupts are enabled, when 0, a square wave is output
    if mode ~= "SQW" then cfg = cfg + 4 end

    -- Bit 3-4: Square wave frequency (1Hz by default)
    -- 8.192 KHz square wave
    if SQRate == 8192 then cfg = cfg + 24

    -- 4.096 KHz square wave
    elseif SQRate == 4096 then cfg = cfg + 16

    -- 1.024 KHz square wave
    elseif SQRate == 1024 then cfg = cfg + 8 end

    -- Bit 5: Force temp. conversion

    -- Bit 6: Enable square wave on battery
    if BBSQW then cfg = cfg + 0x40 end

    -- Disable the oscillator (clock) while on battery power
    if disableOnBatt then cfg = cfg + 0x80 end

    -- Write the configuration settings to the register
    writeRegister(0x0E, cfg)

    -- Set the status register bits

    -- Get the status register
    status = string.byte(readRegister(0x0F, 1), 1)

    -- Bit 6: Battery-backed 32HZz enable

    -- Bit 4-5: Temperature Conversion Rate

    -- Enable/Disable bit 3: Enable 32KHz output on the 32KHz pin
    status = disable32KHz and math.floor(status / 8) % 2 == 1 and status - 8 or status -- Disable
    status = not disable32KHz and math.floor(status / 8) % 2 == 0 and status + 8 or status -- Enable

    -- Write the status settings to the register
    writeRegister(0x0F, status)

    --print(cfg)

    --print(status)

end


-- Set the current time on the RTC
function M.setTime(second, minute, hour, day, date, month, year)

    -- Make sure year is on a 0-99 scale
    if year > 99 then year = year % 100 end

    -- Write the 7 values to the time registers: (0x00-0x06)
    writeRegister(0x00, decToBCD(second), decToBCD(minute), decToBCD(hour), 
        decToBCD(day), decToBCD(date), decToBCD(month), decToBCD(year))

end


-- Get the current time from the RTC
function M.getTime(format, sync)

    local bytes, second, minute, hour, dayofweek, date, month, year, ampm, output

    -- Get the 7 time bytes from registers 0x00-0x06
    bytes = readRegister(0x00, 7)

    -- Convert the bytes to numbers
    second = bcdToDec(string.byte(bytes, 1))
    minute = bcdToDec(string.byte(bytes, 2))
    hour = bcdToDec(string.byte(bytes, 3))
    dayofweek = bcdToDec(string.byte(bytes, 4))
    date = bcdToDec(string.byte(bytes, 5))
    month = bcdToDec(string.byte(bytes, 6))
    year = bcdToDec(string.byte(bytes, 7)) + 2000 -- Convert to a 4-digit year

    
    -- Check if any values are nil or invalid
    -- Return nil in that case
    if second == nil or minute == nil or hour == nil or 
        date == nil or month == nil or year == nil or 
        second == 165 or minute == 165 or hour == 165 or 
        date == 165 or month == 165 or month == 0 then

        -- Return nil
        return nil
    end

    -- Sync with the rtctime module if format = raw and sync is set
    if sync == true and (format == "raw" or format == nil) then

        -- Run through the formatter to sync with RTC
        M.format("%s", second, minute, hour, dayofweek, date, month, year, timezone, sync)

    end

    -- If format is undefined or "raw" then just return the raw numbers
    if format == nil or format == "raw" then

        return second, minute, hour, dayofweek, date, month, year, timezone

    else
    
        -- Run it through the POSIX formatter and return the output
        return M.format(format, second, minute, hour, dayofweek, date, month, year, timezone, sync)

    end

end


-- Function to format date/time according to POSIX/strftime formatting codes
function M.format(format, second, minute, hour, dayofweek, date, month, year, tz, sync)

    local hour12, hour24, days, months, seconds, leapdays, formats
    
    -- Standard strftime formats
    -- https://www.gnu.org/software/libc/manual/html_node/Formatting-Calendar-Time.html


    -- ##### Setting up ##### 

    -- Check if any values are nil
    if second == nil or minute == nil or hour == nil or dayofweek == nil or
        date == nil or month == nil or year == nil then

        -- Return empty string
        return ""
    end


    -- Make sure timezone is set
    if tz == nil then tz = 0 end


    -- Table of day names
    days = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", 
            "Friday", "Saturday"}

    -- Table of month names
    months = {"January", "February", "March", "April", "May", "June", "July", 
              "August", "September", "October", "November", "December"}

    -- 24-hr time
    hour24 = hour

    -- Convert to 12-hour time
    hour12 = (hour > 12 and hour - 12) or (hour == 0 and 12) or hour 
    ampm = hour < 12 and "AM" or "PM"


    -- ##### Unix Timestamp ##### 

    
    -- Calculate leap days
    leapdays = math.floor((year - 1972) / 4 + 1)

    -- Determine if this is a leap year, and account for whether the leap day has occurred
    if (year - 1972) % 4 == 0 and month <= 2 then leapdays = leapdays - 1 end

    -- Days already elapsed in previous month for each month of the year.  
    local months = {0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334}

    -- Calculate seconds since Unix Epoch in UTC time = Unix Timestamp
    seconds = (365 * 86400 * (year - 1970)) + (months[month] * 86400) + 
        ((date + leapdays - 1) * 86400) + 
        (hour24 * 3600) + (minute * 60) + second - tz * 3600

    -- Sync with the RTC time module if sync is true and the rtctime module is present
    if sync == true and type(rtctime) == "romtable" then rtctime.set(seconds) end


    -- ##### Macros ##### 

    
    -- Replace %D macro with mm/dd/yy date: %m/%d/%y
    format = string.gsub(format, "%%D", "%%m/%%d/%%y")

    -- Replace %r macro with 12-hr time: %i:%M:%S %p
    format = string.gsub(format, "%%r", "%%i:%%M:%%S %%p")

    -- Replace %T macro with 24-hr time: 
    format = string.gsub(format, "%%T", "%%H:%%M:%%S")

    -- Replace %f macro ≥with ISO 8601 standard format YYYY-mm-ddTHH:MM:SS+tz: 
    -- %Y-%m-%dT%H:%M:%S%z
    format = string.gsub(format, "%%f", "%%Y-%%m-%%dT%%H:%%M:%%S%%z")


    -- ##### POSIX formatting codes ##### 


    -- Table of formats
    formats = {}
    formats["%a"] = string.sub(days[dayofweek], 1, 3) -- Abbreviated weekday
    formats["%A"] = days[dayofweek] -- Full weekday
    formats["%b"] = string.sub(months[month], 1, 3) -- Abbreviated month name
    formats["%B"] = months[month] -- Full month name
    formats["%c"] = date -- Day of the month without leading zeros
    formats["%d"] = string.format("%02d", date) -- Day of the month with leading zeros
    formats["%H"] = string.format("%02d", hour24) -- 24-hour with leading zeros
    formats["%h"] = hour24 -- 24-hour without leading zeros
    formats["%I"] = string.format("%02d", hour12) -- 12-hour with leading zeros
    formats["%i"] = hour12 -- 12-hour without leading zeros
    formats["%m"] = string.format("%02d", month) -- Month with leading zeros
    formats["%M"] = string.format("%02d", minute) -- Minute with leading zeros
    formats["%n"] = month -- Month without leading zeros
    formats["%p"] = ampm -- AM/PM
    formats["%s"] = seconds -- Unix Timestamp
    formats["%S"] = string.format("%02d", second) -- Seconds with leading zeros
    formats["%w"] = dayofweek - 1 -- Day of week as a number (0-6)
    formats["%y"] = year % 100 -- 2-digit year
    formats["%Y"] = year -- Full year
    formats["%z"] = (tz < 0 and "-" or "+") .. string.format("%02d", math.abs(tz)) -- Timezone
    formats["%%"] = "%" -- % Character

    -- Replace any occurrences of formatting codes with their entry in the formats table
    str = string.gsub(format, "%%[aAbBcdhHiImMnpsSwyYz%%]", formats)

    return str

end


-- Set one of the two alarms on time clock
function M.setAlarm(alarm, alarmType, second, minute, hour, daydate)

    -- Convert alarm parameters to binary coded decimal
    second = decToBCD(second)
    minute = decToBCD(minute)
    hour = decToBCD(hour)
    daydate = decToBCD(daydate)

    -- Set the alarm bits in the alarm registers

    -- Set seconds alarm bit 7: 
    -- M.EVERYSECOND, M.EVERYMINUTE
    if alarmType < 2 then second = second + 128 end

    -- Set minutes alarm bit 7: 
    -- M.EVERYSECOND, M.EVERYMINUTE, M.SECOND
    if alarmType < 4 then minute = minute + 128 end

    -- Set hours alarm bit 7: 
    -- M.EVERYSECOND, M.EVERYMINUTE, M.SECOND, M.MINUTE
    if alarmType < 5 then hour = hour + 128 end

    -- Set day/date alarm bit 7: 
    -- M.EVERYSECOND, M.EVERYMINUTE, M.SECOND, M.MINUTE, M.HOUR
    if alarmType < 6 then daydate = daydate + 128 end

    -- Set day/date bit 6:
    -- M.DAY
    if alarmType == 6 then daydate = daydate + 64 end

    -- Write the alarm bytes to the alarm registers
    if alarm == 1 then 
        writeRegister(0x07, second, minute, hour, daydate)
    elseif alarm == 2 then
        writeRegister(0x0B, minute, hour, daydate)
    end

    -- Enable the alarm
    M.changeAlarmState(alarm, true)

    -- ReArm the alarms
    M.rearmAlarms()

end


-- Enable or disable one of the alarms
function M.changeAlarmState(alarm, enable)

    -- Get the status register
    local cfg = string.byte(readRegister(0x0E, 1), 1)  

    -- Enable/Disable bit 0: alarm 1
    cfg = alarm == 1 and enable and cfg % 2 == 0 and cfg + 1 or cfg -- Enable
    cfg = alarm == 1 and not enable and cfg % 2 == 1 and cfg - 1 or cfg -- Disable

    -- Enable/Disable bit 1: alarm 2
    cfg = alarm == 2 and enable and math.floor(cfg / 2) % 2 == 0 and cfg + 2 or cfg -- Enable
    cfg = alarm == 2 and not enable and math.floor(cfg / 2) % 2 == 1 and cfg - 2 or cfg -- Disable

    -- Write to the status register
    writeRegister(0x0E, cfg)

end


-- Rearm both alarms.  Best to do both at once.
function M.rearmAlarms()

    -- Get the status register
    local status = string.byte(readRegister(0x0F, 1), 1)  

    -- Set the last 2 bits to 0
    status = status - (status % 4)

    -- Write to the status register
    writeRegister(0x0F, status)

end


-- Get the temperature from the RTC
function M.getTemp()

    local bytes, integer, fraction

    -- Get the temperature registers
    bytes = readRegister(0x11, 2)

    -- Shift the first byte left 2 bits, and the second byte right 6 bits & combine

    -- The first byte is the integer portion with bit 7 = sign
    integer = string.byte(bytes, 1)

    -- The second byte is the fraction portion in 1/4 degree fractions
    fraction = (string.byte(bytes, 2) / 64) * 0.25

    -- Convert from two's complement if temperature is negative
    -- TODO: does this also apply to fraction???
    if integer > 127 then integer = (-127 + (integer % 128)) - 1 end

    -- Return the temperature
    return integer + fraction

end


-- Get the status of the alarms, the temperature conversion, and the oscillator
--function M.getStatus()
  
    --local status, osc_stopped, busy, alm1, alm2

    -- Get the status register
    --status = string.byte(readRegister(0x0F, 1), 1)

    -- Bit 7: Check whether the oscillator is or was stopped
    --osc_stopped = status > 0x7F

    -- Bit 2: Check whether the device is busy with a temperature conversion
    --busy = math.floor(status / 4) % 2 == 1

    -- Bit 1: Check whether Alarm 2 has triggered
    --alm2 = math.floor(status / 2) % 2 == 1

    -- Bit 0: Check whether Alarm 1 has triggered
    --alm1 = status % 2 == 1 

    -- Return the status values
    --return alm1, alm2, busy, osc_stopped

--end


-- Set the aging offset register
--function M.setAging(offset)

    -- Convert to two's complement if negative
    --if offset < 0 then offset = (offset + 128) + 128 end

    -- Write to the aging register
    --writeRegister(0x10, offset)

--end


-- Set the aging offset register
--function M.getAging()

    -- Get the aging register
    --local offset = string.byte(readRegister(0x10, 1), 1) 

    -- Convert from two's complement if negative
    --if offset > 127 then offset = (-127 + (offset % 128)) - 1 end

    --return offset

--end

-- Print out module version information on load
print("Loaded DS3231 v" .. version)

-- Return the module table
return M
