--[[ 

##### CSV Module #####


##### Public Function Reference #####



##### Required Firmware Modules #####
file


##### Version History #####
- 9/1/2016 JGM - Version 0.1:
    - Initial version
    
--]]




-- ############### Module Initiation ###############


-- Make a table called M, this becomes the class
local M = {}


-- ############### Local variables ###############

local header

-- ############### Private Functions ###############


-- ############### Public Functions ###############


function M.writeCSV(tbl, filename, separator)

    local sep

    -- Check if the first argument is a table
    if type(tbl) == "table" then

        --print(tbl.header)
        --print(type(tbl.header))
        --print(tbl.header == nil)
        
        -- Check if there's a header, and whether it's a table itself
        if tbl.header == nil or type(tbl.header ~= "table") then 
            --print("Err: No table header set")
        end

    else
        print("Err: need a table with a header field")
    end

    -- Check to see if filename is a string and arr is a table

    -- Check to see if the sep argument is set
    if type(separator) == "string" then
        sep = separator
    else
        sep = ","
    end

    --sep = arg[1] or ","
    
    
    if file.exists(filename) then

        -- Open the file in append mode
        file.open(filename, "a+")
        
    else

        -- Join the header
        header = table.concat(tbl.header, sep)

        --print(header)
        
        -- Create the file
        file.open(filename, "w")

        -- Write the header row
        file.writeline(header)
        
    end
        
    -- Write the data rows
    for _, line in ipairs(tbl) do

        -- Get the data row and join it
        row = table.concat(line, sep)

        --print(row)

        -- Write the data row
        file.writeline(row)
    end

    -- Close the file
    file.close()
    
end

return M
