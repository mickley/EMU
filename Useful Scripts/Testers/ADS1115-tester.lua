--[[ 

This can be used to test ADS1115 analog to digital converters
It checks for an ADS1115 every second, and if one is present, 
it returns the single-ended value for channel 0

Additionally, if a probe module and probe are attached, it tests those as well, 
assuming that the probe is attached and not in soil but in open air.

Module requirements:
ads1115

Firmware Module requirements
gpio, i2c, tmr, uart

##### Version History #####
- 1/2/2018   JGM - Version 1.0:
    - Initial version

- 11/28/2018 JGM - Version 1.1:
    - Now checks for low and high measurements when soil probe is attached
    - Detects both ADS1115 and soil probe

--]]


-- Local variables
local sda, scl, status, test, value

-- Define the SDA and SCL pins
sda = 1
scl = 2

-- Make a timer object (easier to turn off)
check = tmr.create()

-- Load the ADS1115 ADC module
status, ads1115 = pcall(require, "ads1115")

-- Set abort to zero to start
abort = 0

-- Abort message
print("Press the Abort button to stop sensor checking")

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
    test = ads1115.init(sda, scl)

    -- ADS1115 sensor is present
    if test then

        -- Set voltage to max 4.096 volts
        ads1115.setPGA(4.096)

        -- Read channel A0 using callback function
        ads1115.readADC(0, function(value)


                -- Check soil measurement: Should be 24000-27000, ideally 26000s
                if value < 24000 then

                    if value < 6000 then
                        -- Print out the success message
                        print("ADS1115 Ch0 present, no soil probe ", value)
                    else
                        -- Low measurement: connection problems
                        print("ADS1115 Ch0 + Soil Probe present - Value low (poor connection?) ", value)
                    end


                elseif value > 27000 then

                    -- High measurement, wiring problems too high voltage to soil module
                    print("ADS1115 Ch0 + Soil Probe present - Value high (not 3.3v power?) ", value)

                else

                    -- Print out the success message
                    print("ADS1115 Ch0 + Soil Probe present ", value)

                end -- End of ADS1115 Ch0 measurement check    

        end)

    -- No sensor present
    elseif not status then

        -- Print status
        print("ADS1115 not present")

    end

end)
