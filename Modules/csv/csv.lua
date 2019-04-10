--[[ 

##### CSV Module #####
This module enables writing a lua table to a CSV file stored on the SPIFFS filesystem

##### Public Function Reference #####
writeCSV(tbl, filename, [separator]) - Write the contents of a lua table, to a file as CSV, with optional separator charater


##### Required Firmware Modules #####
file


##### Version History #####
- 9/1/2016 JGM - Version 0.1:
    - Initial version

- 3/9/2017 JGM - Version 0.2:
    - Added module version printout

- 5/8/2017 JGM - Version 0.3: 
    - Now uses object-oriented file functions
      Also checks to see if files were opened correctly, 
      preventing errors

- 9/20/2018 JGM - Version 0.4
    - Fixed bug when no header row was specified
    
- 4/10/2019 JGM - Version 0.5:
    - There's a bug in the SPIFFS filesystem that causes
      file writes to fail as the filesystem gets full.
      Adding code to prevent writes when over ~75% space
      until bug is fixed.

--]]




-- ############### Module Initiation ###############


-- Make a table called M, this becomes the class
local M = {}


-- ############### Local variables ###############

local header
local version = 0.5

-- ############### Private Functions ###############


-- ############### Public Functions ###############


function M.writeCSV(tbl, filename, separator)

    local sep

    -- Check if the first argument is a table
    if type(tbl) == "table" then

    else
        print("Err: need a table of data")
    end

    -- Check to see if filename is a string and arr is a table

    -- Check to see if the sep argument is set
    if type(separator) == "string" then
        sep = separator
    else
        sep = ","
    end

    --sep = arg[1] or ","
    

    -- Get the remaining space left
    space, _, total = file.fsinfo()
    
    -- Check how much space is left
    -- If less than 25% of the filesystem space is remaining, we'd better stop
    if space / total < 0.25 then

        -- Print error message
        print("Not enough filesystem space left to write to CSV safely")

        -- Quit the function
        return false

    end


    -- Check if the CSV file already exists on the filesystem
    if file.exists(filename) then

        -- Open the file in append mode
        fhandle = file.open(filename, "a+")
        
    else
        
        -- Create the file
        fhandle = file.open(filename, "w")

        -- Check to see if the file opened successfully
        if fhandle then

            -- Check if there's a header, and whether it's a table itself
            if tbl.header ~= nil and type(tbl.header == "table") then 
    
                -- Join the header
                header = table.concat(tbl.header, sep)
    
                -- Write the header row
                fhandle:writeline(header)
            end

        else
        
            -- Print error message
            print("Couldn't create " .. filename)
    
            -- Writing to CSV was unsuccessful
            return false
        end
        
    end

    -- Check to see if the file opened successfully
    if fhandle then

        
        -- Write the data rows
        for _, line in ipairs(tbl) do
    
            -- Get the data row and join it
            row = table.concat(line, sep)
    
            --print(row)
    
            -- Write the data row
            fhandle:writeline(row)
        end
    
        -- Close the file
        fhandle:close()
        
    else

        -- Print error message
        print("Couldn't open " .. filename)

        -- Writing to CSV was unsuccessful
        return false
    end

    -- Writing to CSV was successful
    return true
    
end

-- Print out module version information on load
print("Loaded CSV v" .. version)

-- Return the module table
return M
