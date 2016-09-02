-- This is a basic example using the ADS1115 to read one analog channel 
-- in single shot mode.  Because single-shot needs time to measure the channel
-- we need to use a callback function with readADC() to wait for the value

-- Set the SDA and SCL pins to use for I²C communication
sda = 2 -- GPIO4
scl = 1 -- GPIO5

-- Load the module
ads1115 = require("ads1115")

-- Initialize the module with the sda and scl pins
ads1115.init(sda, scl)

-- Get a value from channel A0 using a callback function
-- This is needed in single-shot mode to allow time for the sensor to measure
ads1115.readADC(0, function(return_val)

    -- Set val = the return value sent to the callback function
    val = return_val

    -- Convert the value to millivolts
    mv = ads1115.mvolts(val)
    
    -- Print out the values
    print("Raw value: " .. val .. " | Millivolts: " .. mv)

    -- Release the module to free up the memory
    ads1115 = nil
    package.loaded["ads1115"] = nil    
    
end)
