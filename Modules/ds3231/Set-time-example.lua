-- Set the current time here
-- Then run this code (don't save to ESP)
-- Best to set seconds to 00 or something, and run code when your 
-- computer or phone's
-- seconds hit 0
year = 2017
month = 5
day = 10
dayofweek = 4 --  1 = Sunday and 7 = Saturday
hour = 12  -- 24-hr time: Use EST = EDT hour - 1 when in daylight savings time
minute = 38
second = 0

-- Load the module
ds3231 = require("ds3231")

-- Initialize the module
ds3231.init(1, 2)

-- Configure the clock
ds3231.config("INT", nil, false, false, true)

-- Set the date and time
ds3231.setTime(second, minute, hour, dayofweek, day, month, year)

-- Print out current time
print(ds3231.getTime("%D %T", false))
