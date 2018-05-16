--[[ 

This can be used to test BH1750 light sensors.  
It checks for a sensor every second, and if one is present, 
it returns the lux value

Module requirements:
bh1750

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

-- Load the BH1750 light module
status, bh1750 = pcall(require, "bh1750")

-- Set abort to zero to start
abort = 0

-- Check for a BH1750 sensor and measurements every second
check:alarm(1000, tmr.ALARM_AUTO, function()

    -- Stop the timer if aborted
    if abort == 1 then

        -- unregister the timer
        check:unregister()

        -- Wait for any callbacks to complete and unload
        tmr.create():alarm(250, tmr.ALARM_SINGLE, function()
    
            -- Unload bh1750 module
            bh1750 = nil
            package.loaded.bh1750 = nil
    
            -- Print status
            print("Stopped checking for BH1750 sensor")

        end)

    end

    -- Initialize the BH1750 sensor and check if it's present
    status = bh1750.init(sda, scl, 0x23, "Continuous_H")

    -- BME sensor is present
    if status then
       
        -- Wait 100 ms to start up and then try taking a measurement
        tmr.create():alarm(200, tmr.ALARM_SINGLE, function()

            -- Get measurement
            lux, valid = bh1750.getLux()

            -- Print status
            print("BH1750 present | ", lux, valid)

        end)

    -- No sensor present
    elseif not status then

        -- Print status
        print("BH1750 not present")

    end

end)
