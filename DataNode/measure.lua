--[[ 

##### Ecological Sensor Logging Script #####

This script reads the BME280 and TLS2561 sensors 

It depends heavily on configuration variables being set in config.lua, 
so this must be run first

Module requirements:
ads1115, csv

Firmware Module requirements:


##### Version History #####
- 10/13/2016 JGM - Version 0.1:
        - Initial version


--]]


-- ########## Local Variables ##########

-- Initialize all the variables we'll be using
-- Local variables are more efficient
--local sda scl
local lux, temp, pressure, humidity, humid, kPa, tempC, tempF, inHG, correction
local timestamp, time, timestr
local soilPin, soilDelay

-- Set the SDA and SCL pins to use for I�C communication
sda = 1 -- GPIO4
scl = 2 -- GPIO5

-- Set the pin to turn on the soil sensor
soilPin = 5

-- Set the delay before using the soil sensor
soilDelay = 500

--Set the display's I2C address
disp_addr = 0x3c

-- Make sure interval is set correctly, and set to 15s otherwise
interval = interval ~= nil and interval or 15


-- ########## Ancillary Functions ##########


-- Function to round floating point numbers
function round(number, digits)
    return tonumber(string.format("%." .. (digits or 0) .. "f", number))
end


-- Function to display # of digits for date/time
function digs(number, digits)
    return string.format("%0" .. (digits or 0) .. "d", number)
end


-- Function to draw on the display
-- Put anything you want to show up on the display in here
function draw()

   -- Display all our stuff
    disp:drawStr( 5, 10, "Soil Moist.: " .. moist)
    disp:drawStr( 5, 20, "Temp: " .. tempF)
    --disp:drawStr( 5, 30, "Humid: " .. humid)
    disp:drawStr( 5, 40, "Light: " .. lux)
    disp:drawStr( 5, 50, "Pressure: " .. inHG)
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


-- ########## Initialize soil moisture pin ##########


-- Set the soil pin to output mode so it can send electricity
gpio.mode(soilPin, gpio.OUTPUT)

-- Set the soil pin to Low (Off)
gpio.write(soilPin, gpio.LOW)


-- ########## Initialize Light sensor ##########


-- Initialize the TSL2561 digital light sensor
status = tsl2561.init(sda, scl)


-- ########## Initialize Temp/Humidity sensor ##########


-- Initialize BME280 temp/humidity/pressure sensor in sleep mode (power efficiency)
bme280.init(sda, scl, nil, nil, nil, 0)


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

    -- Load ADS1115 module
    ads1115 = require("ads1115")
    
    -- Initialize ADS1115 module, sets up configuration
    ads1115.init(sda, scl)

    -- Maximum voltage to measure is 4.096 volts
    ads1115.setPGA(4.096)

    -- Turn on soil moisture sensors
    gpio.write(soilPin, gpio.HIGH)
    

    -- Take readings from BME280 in forced mode, and then go back to sleep
    -- The callback function runs after 113ms by default (or set first arg to # of ms)
    -- This gives time for the sensor to take the readings
    bme280.startreadout(0, function ()
    
        -- Get pressure & temperature from BME280
        pressure, temp = bme280.baro() -- hectopascals * 1000, tempC * 100

        -- Get humidity from BME280
        --humidity = bme280.humi() -- RH * 1000

        -- Unit conversions
        tempC = temp / 100 -- To Celcius
        tempF = tempC * 9 / 5 + 32 -- To Fahrenheit
        --humid = humidity / 1000 -- To relative humidity percentage
        kPa = pressure / 10000 -- hectopascals * 1000
        inHG = kPa * 0.295301 -- To inches of mercury
        
        -- Barometric correction for inHG by temperature
        -- From http://www.csgnetwork.com/barcorrecttcalc.html
        correction = inHG * ((tempF - 28.630) / (1.1123 * tempF + 10978))
        inHG = round(inHG + correction, 3)

    end)

    -- Read the lux value from the light sensor if the sensor has returned OK for status
    if status == tsl2561.TSL2561_OK then
        lux = tsl2561.getlux()
    else
        print("Error getting lux measurement. Status: " .. status)
    end

    -- Set a timer to wait until the soil sensors equilibrate
    tmr.alarm(2, soilDelay, tmr.ALARM_SINGLE, function()
    
        -- Read channel A0 using callback function
        ads1115.readADC(0, function(return_val)
    
            -- Get the soil moisture value from the callback
            moist = return_val
    
            -- Done with ads1115, so we can unload it 
            ads1115 = nil
            package.loaded["ads1115"] = nil

            -- Turn off soil moisture sensor
            gpio.write(soilPin, gpio.LOW)
    
            -- Get unix timestamp
            timestamp = rtctime.get()

            -- Check if the timestamp is nill
            if timestamp ~= nil then
                -- Convert unix seconds to string
                time = rtctime.epoch2cal( (timestamp + (timezone * 3600)) )
                
                -- Creat a formatted date/time string
                timestr = time["mon"] .. "/" .. digs(time["day"], 2) .. "/" .. digs(time["year"], 2) .. 
                    " " .. digs(time["hour"], 2) .. ":" .. digs(time["min"], 2) .. ":" .. 
                    digs(time["sec"], 2) .. " UTC" .. timezone
                
                -- Print out string
                print(timestr)
            else
                timestr = ""
            end

            -- Print out the information
            print("Light Level: " .. lux .. " lux")
            print("Temperature: " .. tempF .. " deg F")
            --print("Humidity: " .. humid .. "%")
            print("Soil Moisture: " .. moist .. " deg F")
            print("Pressure: " .. inHG .. " in HG")
                        
            -- Display our measurements on the display
            display()

    
            -- Load the CSV module
            csv = require("csv")
    
            -- Make a new data table to store stuff in
            data = {}
    
            -- Set the CSV header
            --data["header"] = {"Soil_Moisture", "Temperature", "Humidity", "Light", "Pressure", "Time"}
            data["header"] = {"Soil_Moisture", "Temperature", "Light", "Pressure", "Time"}

            -- Set the CSV data
            --data[1] = {moist, tempF, humid, lux, inHG, timestr}
            data[1] = {moist, tempF, lux, inHG, timestr}
         
            -- Write the CSV
            csv.writeCSV(data, "data.csv")

            -- Unload the CSV module
            csv = nil
            package.loaded.csv = nil

            -- Delete the data table
            data = nil
    
        end)
            
    end)



end


-- Run the timer to measure and weigh the soil
tmr.alarm(1, interval * 1000, tmr.ALARM_AUTO, function() 

    -- 
    main()
        
end)

-- Run it right away
main()

