-- This is an example of using the comparator on the ADS1115 to 
-- trigger the ALERT pin when certain conditions are met

-- Set the SDA and SCL pins to use for I²C communication
sda = 2 -- GPIO4
scl = 1 -- GPIO5

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
ads1115.setComparator(10667, 16000, 1, false, "low", "hysteresis")

-- Get a value from channel A0
local val = ads1115.readADC(0)

-- Convert the value to millivolts
local mv = ads1115.mvolts(val)

-- Print out the values
print("Raw value: " .. val)
print("Millivolts: " .. mv)

-- Release the module to free up the memory
ads1115 = nil
package.loaded["ads1115"] = nil