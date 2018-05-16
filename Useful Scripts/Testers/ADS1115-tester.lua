--[[ 

This can be used to test ADS1115 analog to digital converters
It checks for an ADS1115 every second, and if one is present, 
it returns the single-ended value for channel 1

Module requirements:
ads1115

Firmware Module requirements
gpio, i2c, tmr, uart

##### Version History #####
- 1/2/2018   JGM - Version 1.0:
    - Initial version

--]]


-- Local variables
local sda, scl, status, lux, valid

-- Define the SDA and SCL pins
sda = 1
scl = 2

-- Make a timer object (easier to turn off)
check = tmr.create()

-- Load the ADS1115 ADC module
status, ads1115 = pcall(require, "ads1115")

-- Set abort to zero to start
abort = 0

-- Check for a ADS1115 ADC and a measurement every second
check:alarm(1000, tmr.ALARM_AUTO, function()

    -- Stop the timer if aborted
    if abort == 1 then

        -- Unregister the timer
        check:unregister()

        -- Wait for any callbacks to complete and unload
        tmr.create():alarm(50, tmr.ALARM_SINGLE, function()
    
            -- Unload ads1115 module
            ads1115 = nil
            package.loaded.ads1115 = nil
    
            -- Print status
            print("Stopped checking for ADS1115 ADC")

        end)
        
    end

    -- Initialize the ADS1115 ADC and check if it's present
    status = ads1115.init(sda, scl)

    -- BME sensor is present
    if status then

        -- Set voltage to max 4.096 volts
        ads1115.setPGA(4.096)
       
        -- Wait 100 ms to start up and then try taking a measurement
        tmr.create():alarm(200, tmr.ALARM_SINGLE, function()

            -- Get measurement
            value = ads1115.readADC(0)

            -- Print status
            print("ADS1115 present | ", value)

        end)

    -- No sensor present
    elseif not status then

        -- Print status
        print("ADS1115 not present")

    end

end)
