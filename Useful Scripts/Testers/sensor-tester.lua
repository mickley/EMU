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

--]]


-- ########## Setup Variables ##########


-- Set the SDA and SCL pins to use for I?C communication
sda = 1 -- GPIO4
scl = 2 -- GPIO5


-- Define the onewire pin
ow = 6

-- ########## Setup Wifi ##########


--Turn off wifi
wifi.setmode(wifi.NULLMODE)


-- ########## Test LED ##########


-- Setup the WS2812 bus
ws2812.init(ws2812.MODE_SINGLE)

-- Turn on Red
ws2812.write(string.char(0, 127, 0))

-- Wait 500 ms
tmr.create():alarm(500, tmr.ALARM_SINGLE, function()

    -- Switch to Green
    ws2812.write(string.char(127, 0, 0))

    -- Wait 500 ms
    tmr.create():alarm(500, tmr.ALARM_SINGLE, function()

        -- Switch to Blue
        ws2812.write(string.char(0, 0, 127))

        -- Wait 500 ms
        tmr.create():alarm(500, tmr.ALARM_SINGLE, function()

            -- Turn off
            ws2812.write(string.char(0, 0, 0))

        end)
    end)

end)

-- ########## Test Soil Moisture Sensor ##########


-- Setup the Onewire bus
ds18b20.setup(4)

-- Check for DS18b20 sensors and read from them
ds18b20.read(function(_, rom, _, temperature)
    device = string.format("%02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X",
        string.match(rom,"(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)"))
    tempS = temperature
end, {})



-- Create a timer to check whether we got a readout from the DS18b20 sensor
tmr.create():alarm(950, tmr.ALARM_SINGLE, function()

    if device == nil then

        -- Print status
        print("'Soil Temp: FAIL - Sensor not detected'")
        
    else

        -- Print out the success message
        print("--[[ Soil Temp: PASS - " .. device .. " | " .. temp .. " --]]")
    
        -- Print status
        print("DS18b20 present | ", device, temp)

        -- Reset the device variable
        device = nil
        
    end

end)


-- ########## Test BME280 Temp/Humid/Pressure Sensor ##########


-- Initialize BME280 temp/humidity/pressure sensor.  
-- Settings:
--    x16 oversampling for temp and humidity
--    x1 oversampling for presssure (faster measurements)
--    normal mode
--    20ms between samples
--    IIR Filter = 2

-- Initialize I2C bus
i2c.setup(0, sda, scl, i2c.SLOW) 

-- Initialize BME280 temp/humidity/pressure sensor.  
bme = bme280.setup(5, 1, 5, 3, 2, 0)

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
                print("'BME280: FAIL - Sensor detected, some measurements invalid'")
        
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
           if year ~= 2001 then
           
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


-- Initialize BH1750 sensor #1: one-shot mode, maximum range, 0x23 address
bh = bh1750.setup(0, 0x23, bh1750.ONE_TIME_HIGH_RES_MODE, 31)

-- Wait 3 seconds
tmr.create():alarm(3000, tmr.ALARM_SINGLE, function()

    -- Log message, but don't turn off
    if bh == nil then
        
        -- Didn't find the sensor
        print("'BH1750: FAIL - No Sensor Found'")

    else
        -- Get the lux value
        lx = bh1750.read()
    
        -- Check measurement
        if lx == nil or lx == 54612500 then
    
            print("'BH1750: FAIL - Bad Lux Measurement'")
            
        else

            -- Check for light out of range
            if lx == 121556854 then
            
                print("'BH1750: FAIL - Lux out of Range'")

            else

                -- Round lux to two decimals
                lux = math.floor(lx/10 + 0.5)/100
                print("--[[ BH1750: PASS - " .. lux .. " lux --]]")

            end
        
        end -- End of BH1750 measurement check

    end

end)


-- ########## Test ADS1115/Soil Moisture Sensor ##########


-- Setup the ADS1115 using the default address (0x48)
ads = ads1115.setup(ads1115.ADDR_GND)

-- Configure with 4.096v range, 128SPS, and measuring channel 0 in single shot mode
ads1115.setting(ads1115.GAIN_4_096V, ads1115.DR_128SPS, ads1115.SINGLE_0, ads1115.SINGLE_SHOT)

-- Wait 4 seconds
tmr.create():alarm(4000, tmr.ALARM_SINGLE, function()

    -- Log message, but don't turn off
    if ads == nil then
        
        -- Didn't find the sensor
        print("'ADS1115: FAIL - No Sensor Found'")

    else

        -- Start a measurement from the ADS1115
        ads1115.startread(function(volt, volt_dec, adc, sign) 

            -- Check measurement
            if adc == nil then
                print("'ADS1115: Ch0 FAIL - Bad Soil Measurement'")
            elseif adc < 24000 then
                print("'ADS1115: Ch0 FAIL - Measurement low: " .. adc .. "'")
            elseif adc > 28000 then
                print("'ADS1115: Ch0 FAIL - Measurement high: " .. adc .. "'")
            else
                print("--[[ ADS1115 Ch0: PASS - " .. adc .. " --]]")
            end -- End of ADS1115 Ch0 measurement check


            -- Configure with 4.096v range, 128SPS, and measuring channel 1 in single shot mode
            ads1115.setting(ads1115.GAIN_4_096V, ads1115.DR_128SPS, ads1115.SINGLE_1, ads1115.SINGLE_SHOT)

            -- Start a measurement from the ADS1115
            ads1115.startread(function(volt, volt_dec, adc, sign) 

                -- Check measurement
                if adc == nil then
                    print("'ADS1115: Ch1 FAIL - Bad Soil Measurement'")
                elseif adc < 24000 then
                    print("'ADS1115: Ch1 FAIL - Measurement low: " .. adc .. "'")
                elseif adc > 28000 then
                    print("'ADS1115: Ch1 FAIL - Measurement high: " .. adc .. "'")
                else
                    print("--[[ ADS1115 Ch1: PASS - " .. adc .. " --]]")
                end -- End of ADS1115 Ch1 measurement check

            end) -- End of ADS1115 Ch1 Readout 

        end) -- End of ADS1115 Ch0 Readout
    end

end)
