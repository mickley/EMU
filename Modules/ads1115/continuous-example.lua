-- Set the SDA and SCL pins to use for I²C communication
sda = 2 -- GPIO4
scl = 1 -- GPIO5

-- Load the module
ads1115 = require("ads1115")

-- Initialize the module with the sda and scl pins
ads1115.init(sda, scl)

-- Variable to count the number of times we've measured
count = 0

-- Start a timer and measure every 1 second
tmr.create():alarm(1000, tmr.ALARM_AUTO, function(timer)

    -- Add one to count to keep track of how many times we've measured
    count = count + 1

    -- Get a value from channel A0
    -- No need for callback function because we're in continuous mode
    val = ads1115.readADC(0)
    
    -- Convert the value to millivolts
    mv = ads1115.mvolts(val)
    
    -- Print out the values
    print("Raw value: " .. val .. " | Millivolts: " .. mv)

    -- Stop measuring after 30 seconds
    if count == 30 then

        -- Stop the timer
        timer:unregister()

        -- Release the module to free up the memory
        ads1115 = nil
        package.loaded["ads1115"] = nil    
            
    end

end)
