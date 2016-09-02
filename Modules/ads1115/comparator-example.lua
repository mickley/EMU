-- This is an example of using the comparator on the ADS1115 to 
-- trigger the ALERT pin when certain conditions are met
-- Connect the ALERT pin to D4 (built-in LED) to see how it works
-- The LED will turn on when ALERT goes low

-- Set the SDA and SCL pins to use for I²C communication
sda = 2 -- GPIO4
scl = 1 -- GPIO5

-- Configure D4 as an input, so we can check whether it's on
gpio.mode(4, gpio.INPUT)

-- Load the module
ads1115 = require("ads1115")

-- Initialize the module with the sda and scl pins
ads1115.init(sda, scl)

-- Set the sensor to measure continuously
ads1115.setMode("continuous")

-- Setup the comparator
-- Trigger when voltage goes above 3V (3 / 6.144 * 32767 = 15999)
-- Turn off trigger when voltage goes below 2V (2 / 6.144 * 32767 = 10666)
-- Only require one measurement to cross threshold to trigger
-- Alert pin will go low when activated
-- No latching, hysteresis mode
ads1115.setComparator("hysteresis", 10667, 16000)

-- Variable to count the number of times we've measured
count = 0

-- Start timer 0 and measure every 1 second
tmr.alarm(0, 1000, tmr.ALARM_AUTO, function()

    -- Add one to count to keep track of how many times we've measured
    count = count + 1

    -- Get a value from channel A0
    -- No need for callback function because we're in continuous mode
    val = ads1115.readADC(0)
    
    -- Convert the value to millivolts
    mv = ads1115.mvolts(val)

    -- Check whether pin D4/LED is on or off
    if gpio.read(4) == 1 then
        state = "Off" -- D4 is HIGH, but LED is off
    else
        state = "On" -- D4 is LOW, but LED is on
    end

    -- Print out the values
    print("Raw value: " .. val .. " | Millivolts: " .. mv .. " | " .. "LED " .. state)
    
    -- Stop measuring after 30 seconds
    if count == 30 then

        -- Stop the timer
        tmr.unregister(0)

        -- Release the module to free up the memory
        ads1115 = nil
        package.loaded["ads1115"] = nil    
            
    end

end)
