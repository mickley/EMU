-- An example using the BH1750 sensor to read sunlight values with the maximum possible range

-- Load the module
bh1750 = require("bh1750")

-- Initialize the module with SDA = 1, SCL = 2, 0x23 I2C address, and OneTime_H mode
status = bh1750.init(1, 2, 0x23, "OneTime_H")

-- Set the measurement time to the lowest sensitivity/highest range setting (max 121556 lux)
bh1750.setMeasurementTime(31)

-- Get the lux value, validity, and raw value from the sensor
bh1750.getLux(function(lx, validity, raw)
    print(lx, validity, raw)
end)