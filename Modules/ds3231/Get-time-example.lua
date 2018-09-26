-- Some examples for reading the time from the DS3231 clock in different formats

-- Load the module
ds3231 = require("ds3231")

-- Initialize the module with SDA = 1, SCL = 2
ds3231.init(1, 2)

-- Get the raw numbers for all of the date/time parameters
seconds, minutes, hours, day, date, month, year = ds3231.getTime("raw")

-- Print out the raw numbers
print(seconds, minutes, hours, day, date, month, year)

-- Only get the hours, not saving the other values
_, _, hours = ds3231.getTime("raw")

-- Print out the hours
print(hours)

-- Get a formatted time string in ISO 8601 standard format YYYY-mm-ddTHH:MM:SS+tz
-- Also sync the current time with the rtctime firmware module (D1 Mini keeps time)
timestring = ds3231.getTime("%f", true);

-- Print the formatted time string
print(timestring)

-- Get a formatted time string in R's native time format: YYYY-mm-dd HH:MM:SS
timestring = ds3231.getTime("%R", true);

-- Print the formatted time string
print(timestring)

-- Don't forget to release it after use
ds3231 = nil
package.loaded["ds3231"]=nil