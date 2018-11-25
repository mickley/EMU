
# CSV Writing Module

This module allows data to be written to a CSV file on the [ESP8266 SPIFFS filesystem](https://nodemcu.readthedocs.io/en/master/en/spiffs/)

### Features
* Include a header row of column names
* Write a single row of data at a time, or multiple rows.

### Required Firmware Modules
* file

### LCD Module Functions

| Function                         | Reference                 |
|----------------------------------|---------------------------|
| [csv.writeCSV()](#CSVwritecvs)   | Write data to a CSV file  |


## csv.writeCSV()

This function writes a lua table of data to a CSV file

#### Syntax
`CSV.writeCSV(datatable, filename, [display_size])`

#### Parameters
- `datatable` A lua table containing tables of data corresponding to each row of data
- `filename` The filename to write the CSV data to
- (optional) `separator` The separator character to use in the CSV file. Defaults to a comma.

The datatable is a table of tables (array of arrays in other programming languages). Each CSV row of data is stored as a table in numbered indices (e.g., datatable[1]).  An optional named index (datatable["header"]) can contain a table of header row names.

#### Returns
`true` if writing the data to a file was successful, `false` if writing to a file failed.


#### Example
```Lua

-- Set up an empty table to hold data
data {}

-- Add the header row names as a table
data["header"] = {"Timestamp", "Temperature", "Humidity"}
            
-- Add a row of data as a table
data[1] = {"2018-06-10 14:15:05", 22.43, 67.89}

-- Optionally, you could include a second row of data, and write both in the same go
-- data[2] = {"2018-06-10 14:30:05", 24.18, 42.36}


-- Load the module
csv = require("csv")

-- Write the data out to CSV
csv.writeCSV(data, "data.csv", ",")

-- Release the module to free up memory
csv = nil
package.loaded.csv = nil
```


