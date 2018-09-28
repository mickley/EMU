--[[ 

This can be used to test BME280 temp, humidity, and pressure sensors
It checks for a sensor every second, and if one is present, 
it returns the measurements.  

It can also be used for the BMP280, which excludes humidity

Module requirements:
none

Firmware Module requirements
bme280, gpio, i2c, tmr, uart

##### Version History #####
- 1/2/2018   JGM - Version 1.0:
    - Initial version

--]]

-- Local variables
local sda, scl, status, temp, pressure, humidity

-- Define the SDA and SCL pins
sda = 1
scl = 2

-- Make a timer object (easier to turn off)
check = tmr.create()

-- Setup the I2C bus
i2c.setup(0, sda, scl, i2c.SLOW)

-- Set abort to zero to start
abort = 0

-- Check for a BME sensor and measurements every second
check:alarm(1000, tmr.ALARM_AUTO, function()

    -- Stop the timer if aborted
    if abort == 1 then

        -- Unregister the timer
        check:unregister()

        -- Wait for any callbacks to complete
        tmr.create():alarm(250, tmr.ALARM_SINGLE, function()
    
            -- Print status
            print("Stopped checking for BME280 sensor")

        end)

    end

    -- Initialize the BME sensor and check if it's present
    status = bme280.setup(5, 1, 5, 1, 2, 0)

    -- BME sensor is present
    if status == 2 then

        -- Wait 100 ms to start up and then try taking a measurement
        tmr.create():alarm(100, tmr.ALARM_SINGLE, function()

            -- Get measurements
            temp, pressure, humidity = bme280.read()

            -- Print status
            print("BME280 present | ", temp, pressure, humidity)

        end)

    -- BMP sensor is present instead of BME
    elseif status == 1 then

        -- Print status
        print ("BMP280 present -- Wrong sensor chip")

    -- No sensor present
    elseif status == nil then

        -- Print status
        print("BME280 not present")

    end

end)
