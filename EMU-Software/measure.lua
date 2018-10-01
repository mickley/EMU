--[[ 

Main EMU field data collection script
This script reads the BME280, BH1750, and Soil Moisture sensors
It saves the data to CSV

Module requirements:
ads1115, bh1750, csv, ds3231, logging

Firmware Module requirements (including init.lua)
adc, bme280, file, gpio, http, i2c, net, node, 
rtctime, tmr, uart, wifi

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

- 4/3/2017   JGM - Version 2.0:
    - Fiddled with BME280 parameters to minimize self-heating
    - Added code to send data via Coap
    - Now saves a unix timestamp instead of formatted date to csv

- 4/3/2017   JGM - Version 2.1:
    - Changed Coap code to send data when D7 is connected to Gnd
      This minimizes the "on" time a bit more, and is more controllable.

- 4/12/2017  JGM - Version 2.2:
    - Improved Coap code.  Now sends slower and allows more tries
    - Also doesn't give up if the server is receiving from another 

- 4/13/2017  JGM - Version 2.3:
    - Now runs startup() and main() functions with pcall and turns off
      or sleeps if something fails.

- 4/14/2017  JGM - Version 2.4:
    - Coap improvements

- 5/10/2017  JGM - Version 2.5:
    - Removed Coap code
    - Added a second soil moisture sensor
    - Logs text timestamp instead of unix timestamp

- 4/22/2018  JGM - Version 3.0:
    - Full rewrite
    - Now uses firmware modules for BH1750, ADS1115, and DS18B20

- 5/14/2018  JGM - Version 3.1: 
    - Added code to support WS2812 RGB LED with different colors for error codes

- 9/28/2018  JGM - Version 3.2:
    - Adapted for publication
    - Removed code firmware modules for BH1750, ADS1115
    - Removed support for soil temp and WS2812 error LED

--]]


-- Keep all functions local to save memory
local startup, main, off

local sda, scl, bme, lux, tempC, humid, soil, volts, data


-- Set the SDA and SCL pins
sda = 1 -- GPIO5
scl = 2 -- GPIO4

-- Get the name to use on files.  This is set as the emu_name in config.lua
emu_name = emu_name ~= nil and emu_name or "NoName"

-- Make sure interval is set correctly, and set to 1 minute otherwise
-- For this script, intervals of more than an hour are not supported
interval = interval ~= nil and interval <= 60 and interval or 1

-- Make sure timezone is set and default to UTC-5
timezone = timezone ~= nil and timezone or -5

-- Make sure the logging level is set and default to 3: Normal
log_level = log_level ~= nil and log_level or 3


-- ########## Startup Routine ##########


local function startup()

    -- Local variables that aren't needed outside of startup()
    local status, minute, hour


    -- ########## Initialize the logging module  ##########


    -- Load the logging module
    status, log = pcall(require, "logging")

    -- Log an error and sleep for the programmed interval if loading failed
    if not status then 
        print("Loading logging failed.")

         -- Go to sleep for the interval
        node.dsleep(interval * 60 * 1000000, 2)
        return
    end     
         
    -- Specify a filename, logging only warnings and errors
    log.init(emu_name .. "-logfile.txt", timezone, log_level)

    -- Log the start
    log.log("Starting up...", 3)

    
    -- ########## Get the time and set a wake-up alarm ##########
 
    
    -- Load the ds3231 module, making sure it loads properly
    status, ds3231 = pcall(require, "ds3231")

    -- Log an error and sleep for the programmed interval if loading failed
    if not status then 

        -- Log an error message
        log.log("Loading ds3231 failed, sleeping", 1)

        -- Go to sleep for the interval
        node.dsleep(interval * 60 * 1000000, 2) 
        return
    end
    
    -- Initialize the DS3231 real time clock
    status = ds3231.init(sda, scl, 0x68, timezone)

    -- Check to see if the DS3231 clock was detected
    if not status then

        -- Log an error message
        log.log("No DS3231 clock found", 1)

        -- Go to sleep for the interval
        node.dsleep(interval * 60 * 1000000, 2) 
        return
    end

    -- Get the current minute, hour, and year
    _, minute, hour, _, _, _, year = ds3231.getTime("raw")

    -- Return the formatted date/time (In R's native format) and sync with rtctime module
    timestamp = ds3231.getTime("%R", true)

    -- Check if we got a valid time and log an error and sleep for the programmed interval if not
    if timestamp == nil then 

        -- Go to sleep for the interval
        node.dsleep(interval * 60 * 1000000, 2)
        return
    end

    -- Check to make sure the time is set correctly (year 2000 if unset)
    if  year == 2000 then
        log.log("Clock time not set", 2)
        Err_time = true
    end

    -- Check if the interval is an hour or less, and a factor of 60
    if 60 % interval == 0 and interval <= 60 then

        -- Calculate the minute to wake up and log again
        -- Interval should be a factor of 60:
        nextlog = (math.floor(minute / interval) + 1) * interval % 60

    else 

        -- Just log at the next appropriate time
        nextlog = (minute + interval) % 60
    end
    
    -- Calculate the time that the next log will happen & format it
    nextlogtime = ds3231.format("%T", 0, nextlog, 
        nextlog < minute and (hour + 1) % 24 or hour, 1, 1, 1, 1, 1)

    -- Unload the DS3231 real time clock module
    ds3231 = nil
    package.loaded.ds3231 = nil

    -- Garbage collect RAM after unloading ds3231
    collectgarbage()
    

    -- ########## Initialize Temp/Humidity sensor ##########


    -- Initialize I2C bus
    i2c.setup(0, sda, scl, i2c.SLOW) 
    
    -- Initialize BME280 temp/humidity/pressure sensor
    -- Settings:
        -- x16 oversampling for temp and humidity
        -- x1 oversampling for presssure (faster measurements)
        -- forced mode
        -- 125 ms between samples
        -- IIR Filter = 0
    bme = bme280.setup(5, 1, 5, 1, 2, 0)

    -- Log a message on whether the sensor was found
    if bme == nil or bme == 1 then
        log.log("No BME280 sensor found", 1)
    else
        log.log("found BME280", 4)
    end


    -- ########## Run the main code to measure ##########
    

    -- Finished starting up.  
    -- Exit the function first to free up memory by waiting to run main()
    tmr.create():alarm(50, tmr.ALARM_SINGLE, function()
    
        -- Run garbage collection to get back memory
        collectgarbage()
        
        -- run the main code to take a measurement
        status = pcall(main)

        -- Check if there was an error while running main
        if not status then
            log.log("main function failed", 1)

            -- Turn off the EMU via clock alarm until the next logging time
            off()
            return
        end

    end) -- End of timer to run main code file

end -- End of startup() function


-- ########## Main Code: Measure and Process ##########


-- The main() function measures all our sensors and writes to display & csv
function main()

    -- Local variables that aren't needed outside of main()
    local status, temp, humidity


    -- ########## Read Temp & Humidity from BME280  ##########

    -- Check if a bme280 sensor was found
    if bme then
    
        -- Start a measurement from the BME280 #1 sensor and read out after 150ms
        bme280.startreadout(150, function()
    
            -- Get temperature and humidity from the BME280
            temp, _, humidity = bme280.read()
    
            -- Check if temperature was set
            if temp == nil then
    
                -- Log a warning
                log.log("BME280 did not return temperature measurement", 2)
            
            end

            -- Check if humidity was set
            if humidity == nil then
    
                -- Log a warning
                log.log("BME280 did not return humidity measurement", 2)
            
            end
    
            -- Unit conversions
            -- To Celsius (2 decimal places)
            tempC = temp ~= nil and temp / 100 or -100
            
            -- To relative humidity percentage
            humid = humidity ~= nil and humidity / 1000 or -100
    
        end) -- End of BME280 Readout

    -- No bme280 sensor found
    else

        -- Set temperature and humidity to -100 (no data)
        tempC, humid = -100, -100

    end -- End of bme280 sensor check
    

    -- ########## Read Lux from the BH1750FVI sensor ##########
    
    
    -- Wait 200 ms
    tmr.create():alarm(200, tmr.ALARM_SINGLE, function()

        -- Set lux to -100 in case we never get a value
        lux = -100
    
        -- Load the BH1750 sensor module
        status, bh1750 = pcall(require, "bh1750")   

        -- Check to see if the module loaded successfully
        if status then

            -- Initialize the bh1750 sensor
            test = bh1750.init(sda, scl, 0x23, "OneTime_H")

            -- Test whether the sensor was detected
            if test then

                -- Log a success message
                log.log("bh1750 sensor found", 4)

                -- Set the measurement time for maximum range: 121,556 lux
                bh1750.setMeasurementTime(31)

                -- Start getting a lux measurement
                bh1750.getLux(function(lx, valid)

                    -- Check value returned
                    if not lx then

                        -- Log a warning
                        log.log("No measurement for BH1750", 2)

                    elseif not valid then

                        -- Log a warning that even though lux was returned, the value is questionable
                        log.log("BH1750 lux measurement out of range", 2)

                        -- Save the value
                        lux = lx

                    else

                        -- Save the value
                        lux = lx

                    end

                    -- Done with bh1750, so we can unload it 
                    bh1750 = nil
                    package.loaded.bh1750 = nil

                end) -- End of getLux callback

            -- Sensor not detected
            else

                -- Log a warning if the module fails to load
                log.log("No bh1750 sensor found", 2)

                -- Done with bh1750, so we can unload it 
                bh1750 = nil
                package.loaded.bh1750 = nil

            end -- End of bh1750 sensor check

        -- Module didn't load
        else
            -- Log a warning if the module fails to load
            log.log("Loading bh1750 failed", 2)

        end -- End of bh1750 module load check

    end) -- End of bh1750 timer


    -- ########## Read Soil Moisture from ADS1115 Ch0 ##########


    -- Wait 500 ms
    tmr.create():alarm(500, tmr.ALARM_SINGLE, function()

        -- Set soil to -100 in case we never get a value
        soil = -100

        -- Load the ads1115 module
        status, ads1115 = pcall(require, "ads1115")   

        -- Check to see if the module loaded successfully
        if status then

            -- Initialize ADS1115 module, sets up configuration
            test = ads1115.init(sda, scl, 0x48)

            -- Test whether the sensor was detected
            if test then

                -- Log a success message
                log.log("ads1115 sensor found", 4)

                -- Maximum voltage to measure is 4.096 volts
                ads1115.setPGA(4.096)

                -- Read channel A0 using callback function
                ads1115.readADC(0, function(val)

                    -- Check value returned
                    if val ~= nil then

                        -- Save the value
                        soil = val

                    end

                end) -- End of readADC callback

            -- Sensor not detected
            else

                -- Log a warning if the module fails to load
                log.log("No ads1115 sensor found", 2)

            end -- End of bh1750 sensor check

        -- Module didn't load
        else
            -- Log a warning if the module fails to load
            log.log("Loading ads1115 failed", 2)


        end -- End of ads1115 module load check

    end) -- End of ads1115 timer


    -- Set a timer to wait for everything to be measured
    tmr.create():alarm(1000, tmr.ALARM_SINGLE, function()


        -- ########## Read Battery Voltage ##########


        -- Read the voltage before turning everything off.  
        -- Max 6.5 volts with 330k resistor on Lolin D1 mini
        volts = math.floor((adc.read(0) / 1024 * 6.5) * 1000 + 0.5) / 1000


        -- ########## Check that measurements were successful ##########


        -- Final data check
        -- If any of our values are not set then exit without saving the data
        if tempC == nil or humid == nil or lux == nil or soil == nil or volts == nil then

            -- Log an error message
            log.log("Some measurements nil, not logging", 1)
            
            -- Turn off the EMU via clock alarm until the next logging time
            off()
            return
        end

        -- Print out the information
        -- Log the time
        log.log("Time: " .. timestamp, 3)

        -- Log the results
        log.log( tempC .. " deg C | " .. humid .. " %RH | " .. lux .. " lux", 3)    
        log.log("Soil: " .. soil .. "  | Batt: " .. volts .. " V", 3)

        -- Make a new data table to store stuff in
        data = {}

        -- Set the CSV header
        data["header"] = {"Timestamp", "Temp", "Humid", "Lux", "Soil", "Volts"}
                    
        -- Set the CSV data
        data[1] = {timestamp, tempC, humid, lux, soil, volts}
            
        -- Load the CSV module
        status, csv = pcall(require, "csv")
        
        -- Check to see if the module loaded successfully
        if not status then 

            -- Log a warning if the module fails to load
            log.log("Loading csv failed", 2)
            
        -- If the module loaded, write to CSV
        else
         
            -- Write the CSV
            csv.writeCSV(data, emu_name .. "-data.csv")

            -- Unload the CSV module
            csv = nil
            package.loaded.csv = nil

        end

        -- Turn off
        off()

    end) -- End of measurement wait timer

end -- End of main() function


-- ########## SFinishing Routine ##########


-- Function to turn off the ESP by reloading the alarm on the DS3231
function off()

    -- Garbage collect RAM 
    collectgarbage()

    -- Give some time for everything to complete and then turn off
    tmr.create():alarm(10, tmr.ALARM_SINGLE, function()
    
        -- Load the ds3231 module, making sure it loads properly
        status, ds3231 = pcall(require, "ds3231")
    
        -- Log an error and sleep for the programmed interval if loading failed
        if not status then 

            -- Log an error message
            log.log("Loading ds3231 failed, sleeping", 1)

            -- Go to sleep for the interval
            node.dsleep(interval * 60 * 1000000, 2) 
            return
        end
        
        -- Initialize the DS3231 real time clock
        status = ds3231.init(sda, scl, 0x68, timezone)

        -- Check to see if the DS3231 clock was detected
        if not status then

            -- Log an error message
            log.log("No DS3231 clock found", 1)

            -- Go to sleep for the interval
            node.dsleep(interval * 60 * 1000000, 2) 
            return
        end

        -- Set a timer to wait for the LED to finish
        tmr.create():alarm(300, tmr.ALARM_SINGLE, function()
        
            -- Finished message
            log.log("Finished in " .. (tmr.now()/1000) .. " ms", 3)
            
            -- Set the next alarm to wake up the ESP at
            -- Setting this alarm will turn everything off until the DS3231 
            -- turns it back on
            ds3231.setAlarm(1, ds3231.MINUTE, 0, nextlog)
        
            -- Just to be safe, we'll unload the module.  
            -- ESP should already be off already, though.
            ds3231 = nil
            package.loaded.ds3231 = nil

        end) -- End of LED timer
    
    end) -- End of turn off timer
    
end -- End of off() function


-- ########## Startup  ##########


-- Run the startup function()
status = pcall(startup)

-- Check if there was an error while running startup().  
-- If so, sleep for the programmed interval
if not status then

    -- Log an error message
    print("startup() function failed, sleeping")

    -- Go to sleep for the interval
    node.dsleep(interval * 60 * 1000000, 2) -- Go to sleep for the interval
    return
end
