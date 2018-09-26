-- An example script to write a header row and two rows of data to a CSV file.

-- Set up an empty table to hold data
data = {}

-- Add the header row names as a table
data["header"] = {"Timestamp", "Temperature", "Humidity"}
            
-- Add a row of data as a table
data[1] = {"2018-06-10 14:15:05", 22.43, 67.89}

-- Optionally, you could include a second row of data, and write both in the same go
--data[2] = {"2018-06-10 14:30:05", 24.18, 42.36}

-- Load the module
csv = require("csv")

-- Write the data out to CSV
csv.writeCSV(data, "data.csv", ",")

-- Release the module to free up memory
csv = nil
package.loaded.csv = nil
