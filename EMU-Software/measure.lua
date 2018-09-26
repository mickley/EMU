--[[ 

This script reads the BME280, BH1750, and Soil Moisture sensors
It saves the data to CSV.
Built specifically for field usage

Module requirements:
ads1115, bh1750, csv, ds3231, logging


Firmware Module requirements:
bit, bme280, file, gpio, i2c, node, rtctime, sntp, tmr, u8g, wifi

##### Version History #####
- 10/13/2016 JGM - Version 0.1:
        - Initial version
        
- 11/22/2016 JGM - Version 1.0:
        - Version for Tim to take to South AFrica
        
- 11/28/2016 JGM - Version 1.1:
    - Now uses dynamic timers for all timer-related stuff.  
      This avoids conflicts, but requires a recent firmware

- 12/1/2016  JGM - Version 1.2:
    - Code is much more memory efficient, and there is much 
      more built-in error checking using pcall() to catch errors
      and prevent panics. Problems with modules loading or not 
      connected should get caught.

- 9/12/2018
    - Complete rewrite

--]]

-- ########## Setup Variables ##########

-- Keep all functions local to save memory
local round, digs, display, timestamp, main, startup

-- Use local variables to save memory
-- These variables are still available to functions, eg startup() & main()
local sda, scl, soilPin, soilDelay, bme, log, disp,
    lux, tempC, humid, kPa, soil, timestr, log, disp, disp_addr

-- Set the SDA and SCL pins to use for I?C communication
sda = 1 -- GPIO4
scl = 2 -- GPIO5

-- Set the pin to turn on the soil sensor
soilPin = 7

-- Set the delay before using the soil sensor
soilDelay = 500

--Set the display's I2C address
disp_addr = 0x3c

-- Make sure interval is set correctly, and set to 1 minute otherwise
interval = interval ~= nil and interval or 1

-- Make sure timezone is set and default to UTC-5
timezone = timezone ~= nil and timezone or -5

-- Make sure log_level is set and default to normal
log_level = log_level ~= nil and log_level or 3


-- ########## Ancillary Functions ##########


-- Function to round floating point numbers
function round(number, digits)
    local mult = 10^(digits or 0)
    return math.floor(number * mult + 0.5) / mult
end


-- Function to display # of digits for date/time
function digs(number, digits)
    return string.format("%0" .. (digits or 0) .. "d", number)
end


-- Function to update the display
-- All the stuff to put on the display goes inside the repeat .. until loop
function display()

    -- Start at the first display page, and draw until the last page is reached
    disp:firstPage()
    repeat
    
        -- Display all our stuff
        disp:drawStr( 5, 10, "Soil Moist.: " .. soil)
        disp:drawStr( 5, 20, "Temp: " .. tempC)

        -- Make sure we have humidity
        if bme == 2 then disp:drawStr( 5, 30, "Humid: " .. humid) end
        disp:drawStr( 5, 40, "Light: " .. lux)
        disp:drawStr( 5, 50, "Pressure: " .. kPa)
        disp:drawStr( 5, 60, timestr)
        
    until disp:nextPage() == false      
  
end


-- Function to get a Unix timestamp, and if specified, sync time with rtctime module
function timestamp(year, month, day, hour, minute, second, sync)

    local seconds, leapdays
    
    -- Calculate leap days
    leapdays = math.floor((year + 28) / 4 + 1)

    -- Determine if this is a leap year, and account for whether the leap day has occurred
    if (year - 1972) % 4 == 0  and month <= 2 then leapdays = leapdays - 1 end

    -- Days already elapsed in previous month for each month of the year.  
    local months = {0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334}

    -- Check for errors from an unconnected or unconfigured DS3231
    if month == nil or month == 165 then
        seconds = 0
    else
        -- Calculate seconds since Unix Epoch = Unix Timestamp
        seconds = (365 * 86400 * (year + 30)) + (months[month] * 86400) + 
            ((day + leapdays - 1) * 86400) + 
            (hour * 3600) + (minute * 60) + second
    end

    -- Sync with the RTC time module if sync is true
    if sync then rtctime.set(seconds) end

    -- Return the timestamp
    return seconds
end


-- ########## Startup Routine ##########


function startup()

    -- Local variables that aren't needed outside of startup()
    local status, second, minute, hour, date, month, year, time


    -- ########## Initialize the logging module  ##########


    -- Load the logging module
    status, log = pcall(require, "logging")

    -- Log an error and exit if the module didn't load
    if not status then print("Error: logging module failed to load. Exiting!"); return end
    
    -- Specify a filename and a logging level
    log.init("logfile.txt", log_level)
    
    -- Log the start
    log.log("Starting up ...", 3)


    -- ########## Get the time and set a wake-up alarm ##########


    -- Load the ds3231 module, making sure it loads properly
    status, ds3231 = pcall(require, "ds3231")

    -- Log an error and exit if the module didn't load
    if not status then log.log("DS3231 module failed to load. Exiting!", 1); return end
    
    -- Initialize the DS3231 real time clock
    ds3231.init(sda, scl)
    
    -- Get date and time (don't need to get day of week, so skip that)
    second, minute, hour, _, date, month, year = ds3231.getTime()
    
    -- Make a Unix timestamp and sync with the rtctime module (needed for logging)
    time = timestamp(year, month, date, hour, minute, second, true)
    
    -- Check if we got a valid time and log a warning if not.  
    if time == 0 then log.log("DS3231 module failed to get time", 2) end
    
    -- Creat a formatted date/time string
    timestr = month .. "/" .. digs(date, 2) .. "/" .. digs(year, 2) .. 
        " " .. digs(hour, 2) .. ":" .. digs(minute, 2) .. ":" .. 
        digs(second, 2) .. " UTC" .. timezone
    
    -- Set the next alarm to wake up the ESP at
    -- This will wake up the ESP after the interval specified, on the minute
    ds3231.setAlarm(1, ds3231.MINUTE, 0, minute + interval)

    -- Unload the DS3231 real time clock module
    ds3231 = nil
    package.loaded.ds3231 = nil


    -- ########## Initialize soil moisture pin ##########
    
    
    -- Set the soil pin to output mode so it can send electricity
    gpio.mode(soilPin, gpio.OUTPUT)
    
    -- Set the soil pin to Low (Off)
    gpio.write(soilPin, gpio.LOW)

    
    -- ########## Initialize Temp/Humidity sensor ##########
    
    
    -- Initialize BME280 temp/humidity/pressure sensor in sleep mode (power efficiency)
    bme = bme280.init(sda, scl, nil, nil, nil, 0)
    
    -- Log message
    if bme == nil then
        log.log("No BME/BMP280 sensor found. Exiting!", 1)
        return
    elseif bme == 2 then
        log.log("BME280 sensor found", 3)
    else
        log.log("BMP280 sensor found", 3)
    end


    -- ########## Initialize the display ##########
    
    
    -- Initialize I2C communication with the display
    i2c.setup(0, sda, scl, i2c.SLOW)
    
    -- Start the display driver for this particular display
    disp = u8g.ssd1306_128x64_i2c(disp_addr)
    
    -- Set the display font to use
    -- Options: font_5x8, font_6x10, font_7x13, font_9x15_78_79, font_9x15, font_chikita
    disp:setFont(u8g.font_6x10)


    -- ########## Run the main code to measure ##########


    -- Finished starting up.  
    -- Exit the function first to free up memory by waiting to run main()
    tmr.create():alarm(10, tmr.ALARM_SINGLE, function()
    
        -- Run garbage collection to get back memory
        collectgarbage()

        -- run the main code to take a measurement
        main()
    end)

end


-- ########## Main Code ##########


-- The main() function measures all our sensors and writes to display & csv
function main()

    -- Local variables that aren't needed outside of main()
    local status, pressure, temp, humidity, data

    -- Log message
    log.log("Starting a measurement ...", 3)

    -- Turn on soil moisture sensors
    gpio.write(soilPin, gpio.HIGH)

    -- Load the BH1750 light module
    status, bh1750 = pcall(require, "bh1750")

    -- Log an error if the module fails to load
    if not status then log.log("BH1750 module did not load", 1); return end

    -- Initialize bh1750, high resolution, one time (goes to sleep afterwards)
    bh1750.init(sda, scl, 0x23, "OneTime_H")

    -- Set the measurement time to the minimum: 117,000 lux
    bh1750.setMeasurementTime(32)

    -- Start getting a lux measurement
    bh1750.getLux(function(lx)

        -- Log message
        if lx ~= nil then
            log.log("Got lux measurement: " .. lx, 3)
        else
            log.log("Error measuring lux. Exiting!", 1)
            return
        end

        -- Save the value
        lux = round(lx, 2)

        -- Done with bh1750, so we can unload it 
        bh1750 = nil
        package.loaded.bh1750 = nil

    end)
    

    -- Take readings from BME280 in forced mode, and then go back to sleep
    -- The callback function runs after 113ms by default (or set first arg to # of ms)
    -- This gives time for the sensor to take the readings
    bme280.startreadout(0, function ()

        -- Get pressure & temperature from BME280
        pressure, temp = bme280.baro() -- hectopascals * 1000, tempC * 100

        -- Get humidity from BME280, if BMP280 don't bother
        if bme == 2 then humidity = bme280.humi() end -- RH * 1000

        -- Log message
        if pressure ~= nil and temp ~= nil and (humidity ~= nil or bme == 1) then
            log.log("Got BMP/BME measurements successfully", 3)
        else
            log.log("Error getting measurements from BMP/BME. Exiting!", 1)
            return
        end
        
        -- Unit conversions
        tempC = temp / 100 -- To Celcius

        -- Check to see if humidity is defined first
        if humidity ~= nil then humid = humidity / 1000 end -- To relative humidity percentage
        kPa = pressure / 10000 -- hectopascals * 1000

        --tempF = tempC * 9 / 5 + 32 -- To Fahrenheit
        --inHG = kPa * 0.295301 -- To inches of mercury
        
        -- Barometric correction for inHG by temperature
        -- From http://www.csgnetwork.com/barcorrecttcalc.html
        --correction = inHG * ((tempF - 28.630) / (1.1123 * tempF + 10978))
        --inHG = round(inHG + correction, 3)

        

    end)

    -- Log message
    log.log("Soil moisture sensor equilibrating", 3)


    -- Set a timer to wait until the soil sensors equilibrate
    tmr.create():alarm(soilDelay, tmr.ALARM_SINGLE, function()

        -- Log message
        log.log("Soil moisture sensor ready", 3)

        -- Load ADS1115 module
        status, ads1115 = pcall(require, "ads1115")
    
        -- Log an error if the module fails to load
        if not status then log.log("ADS1115 module did not load.  Exiting!", 1); return end
        
        -- Initialize ADS1115 module, sets up configuration
        ads1115.init(sda, scl)
    
        -- Maximum voltage to measure is 4.096 volts
        ads1115.setPGA(4.096)
    
        -- Read channel A0 using callback function
        ads1115.readADC(0, function(return_val)
    
            -- Get the soil moisture value from the callback
            soil = return_val

            -- Log message
            if soil ~= nil  then
                log.log("Got soil moisture successfully: " .. soil, 3)
            else
                log.log("Error getting soil moisture from ADS1115.  Exiting!", 1)
                return
            end
    
            -- Done with ads1115, so we can unload it 
            ads1115 = nil
            package.loaded.ads1115 = nil

            -- Turn off soil moisture sensor
            gpio.write(soilPin, gpio.LOW)

            -- Print out the information
            log.log("Light Level: " .. lux .. " lux", 3)
            log.log("Temperature: " .. tempC .. " deg C", 3)
            if bme == 2 then log.log("Humidity: " .. humid .. "%", 3) end
            log.log("Soil Moisture: " .. soil, 3)
            log.log("Pressure: " .. kPa .. " kPa", 3)
            log.log("Time: " .. timestr, 3)
                        
            -- Display our measurements on the display
            display()
    
            -- Load the CSV module
            status, csv = pcall(require, "csv")

            -- Log a warning if the module fails to load
            if not status then 
                log.log("CSV module did not load", 2)

            -- If the module loaded, write to CSV
            else
            
                -- Make a new data table to store stuff in
                data = {}
        
                -- Set the CSV header
                -- Include humidity data if it's a BME280
                if bme == 2 then
                    data["header"] = {"Soil_Moisture", "Temperature", "Light", "Pressure", "Humidity", "Time"}
        
                    -- Set the CSV data
                    data[1] = {soil, tempC, lux, kPa, humid, timestr}
                else
                   -- Exclude humidity data for BMP280
                   data["header"] = {"Soil_Moisture", "Temperature", "Light", "Pressure", "Time"}
        
                    -- Set the CSV data
                    data[1] = {soil, tempC, lux, kPa, timestr}
                end
             
                -- Write the CSV
                csv.writeCSV(data, "data.csv")
    
                -- Unload the CSV module
                csv = nil
                package.loaded.csv = nil
    
                -- Delete the data table
                data = nil

            end
            
            
            -- Log message
            log.log("Data saved, going to sleep...", 3)

            -- Give some time for everything to complete and then go to sleep
            tmr.create():alarm(100, tmr.ALARM_SINGLE, function()

                -- Sleep indefinitely until the DS3231 wakes it up
                node.dsleep(0)
            end)
    
        end)
            
    end)



end

-- Run the main() function (which does all the measuring) right away
startup()
