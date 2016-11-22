--[[ 

This script reads the BME280, BH1750, and Soil Moisture sensors
It saves t

Module requirements:
ads1115, csv, logging, bh1750


Firmware Module requirements:
bit, bme280, file, gpio, i2c, node, rtctime, sntp, tmr, u8g, wifi

##### Version History #####
- 10/13/2016 JGM - Version 0.1:
        - Initial version
        
- 11/22/2016 JGM - Version 1.0:
        - Version for Tim to take to South AFrica
        
--]]


-- ########## Local Variables ##########

-- Initialize all the variables we'll be using
-- Local variables are more efficient
--local sda scl
local lux, temp, pressure, humidity, humid, kPa, tempC
local timestr
local soilPin, soilDelay

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


-- Function to draw on the display
-- Put anything you want to show up on the display in here
function draw()

   -- Display all our stuff
    disp:drawStr( 5, 10, "Soil Moist.: " .. soil)
    disp:drawStr( 5, 20, "Temp: " .. tempC)
    disp:drawStr( 5, 30, "Humid: " .. humid)
    disp:drawStr( 5, 40, "Light: " .. lux)
    disp:drawStr( 5, 50, "Pressure: " .. kPa)
    disp:drawStr( 5, 60, timestr)
end


-- Function to update the display
-- U8G is a bit convoluted.  
-- You need to call this function and put whatever you want on the display in draw()
function display()

  -- Start at the first display page, and draw until the last page is reached
  disp:firstPage()
  repeat
       draw()
  until disp:nextPage() == false      
  
end


-- Function to get a Unix timestamp, and if specified, sync time with rtctime module
function timestamp(year, month, day, hour, minute, second, sync)

    -- Calculate leap days
    leapdays = math.floor((year + 28) / 4 + 1)

    -- Determine if this is a leap year, and account for whether the leap day has occurred
    if (year - 1972) % 4 == 0  and month <= 2 then leapdays = leapdays - 1 end

    -- Calculate month seconds
    if month == 1 then
        month_sec = 0
    elseif month == 2 then
        month_sec = 2678400
    elseif month == 3 then
        month_sec = 5097600
    elseif month == 4 then
        month_sec = 7776000
    elseif month == 5 then
        month_sec = 10368000
    elseif month == 6 then
        month_sec = 13046400
    elseif month == 7 then
        month_sec = 15638400
    elseif month == 8 then
        month_sec = 18316800
    elseif month == 9 then
        month_sec = 20995200
    elseif month == 10 then
        month_sec = 23587200
    elseif month == 11 then
        month_sec = 26265600
    elseif month == 12 then
        month_sec = 28857600
    end

    local seconds = (31536000 * (year + 30)) + month_sec + 
        ((day + leapdays - 1) * 86400) + 
        (hour * 3600) + (minute * 60) + second

    if sync then rtctime.set(seconds) end
        
    return seconds
end


-- ########## Get the time ##########

-- Load the ds3231 module
ds3231 = require("ds3231")

-- Initialize the DS3231 real time clock
ds3231.init(sda, scl)

-- Get date and time (don't need to get day of week, so skip that)
second, minute, hour, _, date, month, year = ds3231.getTime()

-- Make a Unix timestamp and sync with the rtctime module (needed for logging)
timestamp(year, month, date, hour, minute, second, true)

-- Creat a formatted date/time string
timestr = month .. "/" .. digs(date, 2) .. "/" .. digs(year, 2) .. 
    " " .. digs(hour, 2) .. ":" .. digs(minute, 2) .. ":" .. 
    digs(second, 2) .. " UTC" .. timezone


-- Set the next alarm to wake up the ESP at
-- This will wake up the ESP after the interval specified, on the minute
ds3231.setAlarm(1, ds3231.MINUTE, 0, minute + interval)

-- Unload the DS3231 real time clock module
ds3231 = nil
package.loaded["ds3231"] = nil


-- ########## Initialize the logging module  ##########

-- Load the logging module
log = require("logging")

-- Specify a filename, logging everything
log.init("logfile.txt")

-- Only log errors
--log.init("logfile.txt", 1)

-- Log the start
log.log("Starting up ...", 3)


-- ########## Initialize soil moisture pin ##########


-- Set the soil pin to output mode so it can send electricity
gpio.mode(soilPin, gpio.OUTPUT)

-- Set the soil pin to Low (Off)
gpio.write(soilPin, gpio.LOW)



-- ########## Initialize Temp/Humidity sensor ##########


-- Initialize BME280 temp/humidity/pressure sensor in sleep mode (power efficiency)
local bme = bme280.init(sda, scl, nil, nil, nil, 0)

-- Log message
if bme ~= nil then
    log.log("BME/BMP sensor found.  Type: " .. bme, 3)
else
    log.log("No BME/BMP sensor found", 1)
end

-- ########## Initialize the display ##########


-- Initialize I2C communication with the display
i2c.setup(0, sda, scl, i2c.SLOW)

-- Start the display driver for this particular display
disp = u8g.ssd1306_128x64_i2c(disp_addr)

-- Set the display font to use
-- Options: font_5x8, font_6x10, font_7x13, font_9x15_78_79, font_9x15, font_chikita
disp:setFont(u8g.font_6x10)


-- ########## Main Code ##########


-- The main() function measures all our sensors and writes to display & csv
function main()

    -- Log message
    log.log("Starting measurement ...", 3)

    -- Turn on soil moisture sensors
    gpio.write(soilPin, gpio.HIGH)

    -- Load the BH1750 light module
    bh1750 = require("bh1750")

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
            log.log("Error measuring lux", 1)
        end

        -- Save the value
        lux = round(lx, 2)

        -- Done with bh1750, so we can unload it 
        bh1750 = nil
        package.loaded["bh1750"] = nil

    end)
    

    -- Take readings from BME280 in forced mode, and then go back to sleep
    -- The callback function runs after 113ms by default (or set first arg to # of ms)
    -- This gives time for the sensor to take the readings
    bme280.startreadout(0, function ()

        -- Get pressure & temperature from BME280
        pressure, temp = bme280.baro() -- hectopascals * 1000, tempC * 100

        -- Get humidity from BME280
        humidity = bme280.humi() -- RH * 1000

        -- Log message
        if humidity ~= nil and pressure ~= nil and temp ~= nil then
            log.log("Got BME measurements successfully", 3)
        else
            log.log("Error getting measurements from BMP/BME", 1)
        end
        
        -- Unit conversions
        tempC = temp / 100 -- To Celcius
        --tempF = tempC * 9 / 5 + 32 -- To Fahrenheit
        humid = humidity / 1000 -- To relative humidity percentage
        kPa = pressure / 10000 -- hectopascals * 1000
        --inHG = kPa * 0.295301 -- To inches of mercury
        
        -- Barometric correction for inHG by temperature
        -- From http://www.csgnetwork.com/barcorrecttcalc.html
        --correction = inHG * ((tempF - 28.630) / (1.1123 * tempF + 10978))
        --inHG = round(inHG + correction, 3)

        

    end)

    -- Log message
    log.log("Waiting for soil moisture sensor to equilibrate", 3)

    -- Set a timer to wait until the soil sensors equilibrate
    tmr.alarm(2, soilDelay, tmr.ALARM_SINGLE, function()

        -- Log message
        log.log("Soil moisture sensor ready", 3)

        -- Load ADS1115 module
        ads1115 = require("ads1115")
        
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
                log.log("Error getting soil moisture from ADS1115", 1)
            end
    
            -- Done with ads1115, so we can unload it 
            ads1115 = nil
            package.loaded["ads1115"] = nil

            -- Turn off soil moisture sensor
            gpio.write(soilPin, gpio.LOW)

            -- Print out the information
            log.log("Light Level: " .. lux .. " lux", 3)
            log.log("Temperature: " .. tempC .. " deg C", 3)
            log.log("Humidity: " .. humid .. "%", 3)
            log.log("Soil Moisture: " .. soil, 3)
            log.log("Pressure: " .. kPa .. " kPa", 3)
            log.log("Time: " .. timestr, 3)
                        
            -- Display our measurements on the display
            display()
    
            -- Load the CSV module
            csv = require("csv")
    
            -- Make a new data table to store stuff in
            data = {}
    
            -- Set the CSV header
            --data["header"] = {"Soil_Moisture", "Temperature", "Humidity", "Light", "Pressure", "Time"}
            data["header"] = {"Soil_Moisture", "Temperature", "Light", "Pressure", "Humidity", "Time"}

            -- Set the CSV data
            data[1] = {soil, tempC, lux, kPa, humid, timestr}
         
            -- Write the CSV
            csv.writeCSV(data, "data.csv")

            -- Unload the CSV module
            csv = nil
            package.loaded.csv = nil

            -- Delete the data table
            data = nil

            -- Log message
            log.log("Data saved, going to sleep...", 3)

            -- Give some time for everything to complete and then go to sleep
            tmr.alarm(3, 100, tmr.ALARM_SINGLE, function()

                -- Sleep indefinitely until the DS3231 wakes it up
                node.dsleep(0)
            end)
            
    
        end)
            
    end)



end

-- Run the main() function (which does all the measuring) right away
main()
