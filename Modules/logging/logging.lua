--[[ 

##### Logging Module #####
This module is used to log messages, both to terminal and to a file.

It can be configured through the use of global variables (config.lua)
For example, you can set the log level through a global variable, which 
controls which messages get printed (if you only want the most important ones)


##### Public Function Reference #####
* init(file, logLevel, logPrint, logFile) - Initialize logging.  
  Sets up the default settings for the level of logging to perform, 
  file to log to, etc.
* log(message, loglevel) - log a message with a given loglevel


##### Public Log Levels ##### 
Level 0: Logging off
Level 1: Log errors
Level 2: Log errors and warnings
Level 3: Log errors + warnings + status messages
Level 4: Log everything, including debug messages

##### Required Firmware Modules #####
file, rtctime

##### Max RAM usage: Kb #####

##### Version History #####
- 9/1/2016 JGM - Version 0.1:
    - Initial version

- 9/11/2016 JGM - Version 0.2:
    - Tightened up the code a bit.  
    - Settings moved to init() function instead of using global variables
    - Removed log level module variables
    
- 11/28/2016 JGM - Version 0.3:
    - Now starts the rtctime time at 1/1/1970 and starts counting 
      if rtctime isn't set.

--]]


-- ############### Module Initiation ###############


-- Make a table called M, this becomes the class
local M = {}


-- ############### Local variables ###############


-- Local variables to store various settings
local level, filename, toprint, tofile


-- ############### Public Functions ###############


-- Initialize the logging module
-- This checks to see if global variables are set
-- If not, it sets up some defaults
function M.init(file, logLevel, logPrint, logFile)

    -- Start the rtctime at 1/1/1970 if no time is set
    if rtctime.get() == 0 then rtctime.set(0) end

    -- Use the file filename if it's set or default to node.log
    filename = type(file) == "string" and file or "node.log"

    -- Use the logLevel if set and valid, or default to debug level (4)
    level = logLevel ~= nil and logLevel >= 0 and logLevel <= 4 and 
        logLevel == math.floor(logLevel) and logLevel or 4

    -- Disable printing if specified, and default to enabled
    toprint = logPrint and true or true

    -- Disable logging to file if specified, and default to enabled
    tofile = logFile and true or true

    

end


-- Log the message if it's part of the configured log level
-- Can either print the message out to serial terminal, log to file, or both
function M.log(message, lvl)

    -- Local function variables
    local space, tm, stamp, msgtype, msg

    -- Check to make sure the log level lvl is valid
    if lvl == nil or lvl < 0 or lvl > 4 or lvl ~= math.floor(lvl) then
        M.log("Log level invalid.  Message not logged.", M.error)
        return false
    end

    -- Check to see if this message should be logged
    if lvl <= level then
    
        -- Get the current time
        tm = rtctime.epoch2cal(rtctime.get())
        
        -- Construct a timestamp
        stamp = tm.mon .. "/" .. string.format("%02d", tm.day) .. "/" .. 
            string.format("%04d", tm.year) .. " " .. 
            string.format("%02d", tm.hour) .. ":" .. 
            string.format("%02d", tm.min) .. ":" .. 
            string.format("%02d", tm.sec)
        
        -- Construct the message type
        if lvl == 1 then
            msgtype = "Error"
        elseif lvl == 2 then
            msgtype = "Warning"
        elseif lvl == 3 then
            msgtype = "Normal"
        elseif lvl == 4 then
            msgtype = "Debug"
        end

        -- Construct the message
        msg = stamp .. " " .. msgtype .. ": " .. message

        -- If printing is enabled, print the message over the serial port
        if toprint then
            print(msg)
        end

        -- If logging to file is enabled, log to the specified file
        if tofile then

            -- Get the remaining space left
            space = file.fsinfo()
            
            -- Check how much space is left
            -- If less than 200 bytes, we'd better be safe
            if space < 200 then

                -- Print error message
                print("Not enough filesystem space left to log safely")

                -- Quit the function
                return false

            -- If less than 1000 bytes is left, log a warning
            elseif space < 1000 then
                M.log("Running out of logging space: "..space.." bytes", M.warn)
            end

            -- Open the logfile filename for writing
            file.open(filename, "a+")

            -- Write the line to the logfile
            file.writeline(msg)

            -- Close the file
            file.close()

        end
    end

    -- Logging was successful
    return true
    
end


-- Return the module table
return M
