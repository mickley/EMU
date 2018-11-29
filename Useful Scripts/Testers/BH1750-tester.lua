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

- 11/28/2018 JGM - Version 1.1:
    - Now using similar code to sensor-tester.lua

--]]


-- Local variables
local sda, scl, status, test, lux, valid

-- Define the SDA and SCL pins
sda = 1
scl = 2

-- Make a timer object (easier to turn off)
check = tmr.create()

-- Load the BH1750 light module
status, bh1750 = pcall(require, "bh1750")

-- Set abort to zero to start
abort = 0

-- Abort message
print("Press the Abort button to stop sensor checking")

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

    -- Initialize the bh1750 sensor and check if it's present
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
                print("BH1750 present, invalid measurement, no value")

            elseif not valid then

                -- Returned a lux measurement, but out of range

                print("BH1750 present, invalid measurement", lux .. " lux")

            else

                -- Print status
                print("BH1750 present, valid measurement", lux .. " lux")

            end
            
        end)

    -- No sensor present
    elseif not test then

        -- Print status
        print("BH1750 not present")

    end

end)
