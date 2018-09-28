--[[ 

This script tests relevant sensors to make sure they are working
and prints out pass/fail for each one.  It can be used to test
individual sensors, or also assembled prototypes with all sensors
present


Lua Module requirements:
ads1115, bh1750, ds3231


Firmware Module requirements:
bme280, i2c, node, tmr


##### Version History #####
- 2/8/2016  JGM - Version 0.1:
    - Beginnings of the script, only tests BME280 so far

- 4/27/2017 JGM - Version 1.0:
    - Complete script, tests BME280, BH1750, ADS1115, DS3231
    - Also configures wifi for coap and configures the DS3231 
      clock options

- 5/22/2017 JGM - Version 1.1:
    - Adapted for Robi Bagchi's setup

- 12/13/2017 JGM - Version 1.2:
    - Added delay timers to prevent crashing

- 5/16/2018 JGM - Version 1.3:
    - Updated sensor tester for 2018
    - Now uses firmware modules for bh1750 and ads1115
    - Added tests for ws2812 LED and ds18b20 soil temp

- 9/26/2018 JGM - Version 1.4:
    - Reverted to lua modules for bh1750 and ads1115
    - Added checks for csv and logging lua modules
    - Removed ws2812 and ds18b20 sections for publication

--]]


-- ########## Setup Variables ##########


-- Set the SDA and SCL pins to use for I?C communication
sda = 1 -- GPIO4
scl = 2 -- GPIO5


-- ########## Setup Wifi ##########


--Turn off wifi
wifi.setmode(wifi.NULLMODE)


-- ########## Test lua Modules ##########


-- Load the csv module, making sure it loads properly
status, csv = pcall(require, "csv")

if status then

    -- Unload the module
    csv = nil
    package.loaded.csv = nil

    -- Print out the success message
    print("--[[ CSV: PASS - Module loaded --]]")

else

    -- Didn't find the lua module
    print("'CSV: FAIL - Lua Module not present'")
end


-- Load the logging module, making sure it loads properly
status, logging = pcall(require, "logging")

if status then

    -- Unload the module
    logging = nil
    package.loaded.logging = nil

    -- Print out the success message
    print("--[[ Logging: PASS - Module loaded --]]")

else

    -- Didn't find the lua module
    print("'Logging: FAIL - Lua Module not present'")
end


-- ########## Test BME280 Temp/Humid/Pressure Sensor ##########


-- Initialize BME280 temp/humidity/pressure sensor.  
-- Settings:
--    x16 oversampling for temp and humidity
--    x1 oversampling for presssure (faster measurements)
--    forced mode
--    125 ms between samples
--    IIR Filter = 0

-- Initialize I2C bus
i2c.setup(0, sda, scl, i2c.SLOW) 

-- Initialize BME280 temp/humidity/pressure sensor.  
bme = bme280.setup(5, 1, 5, 1, 2, 0)

-- Wait 1 second before reading
tmr.create():alarm(1000, tmr.ALARM_SINGLE, function()    
    
    -- ##### Sensor Tests #####
    
    
    -- If nil is returned, no sensor was detected
    if bme == nil then
    
        print("'BME280: FAIL - No sensor detected'")
    
    -- If 2 is returned, we have a BME280, so let's see if it works
    elseif bme == 2 then
    
    
        tmr.create():alarm(100, tmr.ALARM_SINGLE, function()
        
            -- Get temperature, pressure, and humidity from the BME280
            temp, pressure, humid = bme280.read()
        
            -- Check for invalid measurements
            if temp == nil or pressure == nil or humid == nil then
        
                -- At least one measurement was invalid
                print("'BME280: FAIL - Sensor detected, some measurements invalid:' ", temp, pressure, humidity)
        
            else
        
                -- BME280 passed all tests
                print("--[[ BME280: PASS - " .. temp / 100 .. " C | " .. 
                    humid / 1000 .. " %RH | " .. math.floor((pressure / 100) + 0.5) / 100 .. " kPa" .. " --]]")
            end
    
        end)
    
    -- If 1 is returned we have a BMP280
    else
        print("'BME280: FAIL - BMP280 detected instead'")
    end
    
    
end)


-- ########## Test DS3231 Real Time Clock ##########

-- Wait 2 seconds
tmr.create():alarm(2000, tmr.ALARM_SINGLE, function()
    
    -- Load the ds3231 module, making sure it loads properly
    status, ds3231 = pcall(require, "ds3231")
    
    -- Check to see if the module loaded successfully
    if status then
        
        -- Initialize the DS3231 real time clock
        test = ds3231.init(sda, scl, 0x68, -5)
        
        -- Check to see if we found the DS3231
        if test then
    
            -- Configure the DS3231 options, just in case it hasn't been
            ds3231.config("INT", nil, false, false, true)
        
            -- Get the year
            _, _, _, _, _, _, year = ds3231.getTime("raw")
        
        
           -- Check if the year is right
           if year <= 2001 then
           
                -- Print out the failure message
                print("'DS3231: FAIL - " .. "Time Not Set'")
                
           else
        
                -- Return the formatted date/time
                timestr = ds3231.getTime("%D %T", false)
            
                -- Print out the success message
                print("--[[ DS3231: PASS - " .. timestr .. " --]]")
           end

        else
        
            -- Didn't find the sensor
            print("'DS3231: FAIL - No Clock Detected'")
        end
        
        -- Done with ds3231, so we can unload it 
        ds3231 = nil
        package.loaded.ds3231 = nil
    
    else
    
        -- Didn't find the lua module
        print("'DS3231: FAIL - Lua Module not present'")
    
    end

end)


-- ########## Test BH1750FVI Light Sensor ##########


-- Wait 3 seconds
tmr.create():alarm(3000, tmr.ALARM_SINGLE, function()


    -- Load the BH1750 sensor module
    status, bh1750 = pcall(require, "bh1750")   

    -- Check to see if the module loaded successfully
    if status then
        
        -- Initialize the bh1750 sensor
        test = bh1750.init(sda, scl, 0x23, "OneTime_H")
        
        -- Check to see if we found the bh1750 sensor
        if test then

            -- Set the measurement time to the minimum: 121,556 lux
            bh1750.setMeasurementTime(31)

            -- Start getting a lux measurement
            bh1750.getLux(function(lux, valid, raw)

                -- Check lux measurement
                if not lux then

                    -- Didn't find the sensor after initialized
                    print("'BH1750: FAIL - No Sensor Found'")

                elseif not valid then

                    -- Returned a lux measurement, but out of range
                    print("'BH1750: FAIL - Lux measurement out of range'")

                else

                    -- Print out the success message
                    print("--[[ BH1750: PASS - " .. lux .. " lux --]]")

                end

            end)

        else

            -- Didn't find the sensor
            print("'BH1750: FAIL - No Sensor Found'")

        end

        -- Done with bh1750, so we can unload it 
        bh1750 = nil
        package.loaded.bh1750 = nil

    else

        -- Didn't find the lua module
        print("'BH1750: FAIL - Lua Module not present'")

    end

end)


-- ########## Test ADS1115/Soil Moisture Sensor ##########


-- Wait 4 seconds
tmr.create():alarm(4000, tmr.ALARM_SINGLE, function()

    -- Load ADS1115 module
    status, ads1115 = pcall(require, "ads1115")

    -- Load the BH1750 sensor module
    status, bh1750 = pcall(require, "bh1750")   

    -- Check to see if the module loaded successfully
    if status then
        
        -- Initialize ADS1115 module, sets up configuration
        test = ads1115.init(sda, scl, 0x48)
        
        -- Check to see if we found the ads1115
        if test then

            -- Maximum voltage to measure is 4.096 volts
            ads1115.setPGA(4.096)
        
            -- Read channel A0 using callback function
            ads1115.readADC(0, function(soil)


                -- Check soil measurement: Should be 24000-27000, ideally 26000s
                if soil < 24000 then

                    -- Low measurement: module not plugged in or connection problems
                    print("'ADS1115: Ch0 FAIL - Measurement low: " .. soil .. "'")

                elseif soil > 27000 then

                    -- High measurement, wiring problems too high voltage to soil module
                    print("'ADS1115: Ch0 FAIL - Measurement high: " .. soil .. "'")

                else

                    -- Print out the success message
                    print("--[[ ADS1115 Ch0: PASS - " .. soil .. " --]]")

                end -- End of ADS1115 Ch0 measurement check

            end)

        else

            -- Didn't find the sensor
            print("'ADS1115: FAIL - No Sensor Found'")

        end

        -- Done with bh1750, so we can unload it 
        bh1750 = nil
        package.loaded.bh1750 = nil

    else

        -- Didn't find the lua module
        print("'ADS1115: FAIL - Lua Module not present'")

    end

end)
