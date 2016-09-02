--[[ 

##### Logging Module #####
This module is used to log messages, both to terminal and to a file.

It can be configured through the use of global variables (config.lua)
For example, you can set the log level through a global variable, which 
controls which messages get printed (if you only want the most important ones)


##### Public Function Reference #####
init() - Initialize logging.  Sets up the defaults and/or reads the global variables
log(message, loglevel) - log a message with a  given loglevel

##### Required Firmware Modules #####
file, rtctime

##### Version History #####
- 9/1/2016 JGM - Version 0.1:
    - Initial version


--]]


-- ############### Module Initiation ###############

-- Set module name to the current filename
local moduleName = ...

-- Make a table called M, this becomes the class
local M = {}

-- 
_G[moduleName] = M


-- ############### Local variables ###############


-- Local variables to store various settings
local level, filename, toprint, tofile

-- Globals
-- LogLevel 0 for off, 1 for errors, 2 for debug
-- LogPrint true for also printing log messages
-- LogToFile true to log to file
-- Logfile filename

-- ############### Public Log Levels ###############

M.off       = 0 -- Level 0: Logging off
M.error     = 1 -- Level 1: only log errors
M.warn      = 2 -- Level 2: Log errors and warnings
M.normal    = 3 -- Level 3: Log errors + warnings + status messages
M.debug     = 4 -- Level 4: Log everything


-- ############### Private Functions ###############

-- Function to display # of digits for date/time
--local function digs(number, digits)
--    return string.format("%0" .. (digits or 0) .. "d", number)
--end

-- ############### Public Functions ###############


-- Initialize the logging module
-- This checks to see if global variables are set
-- If not, it sets up some defaults
function M.init()

    -- Use the LogLevel if set, and default to debug level
    if LogLevel ~= nil and LogLevel >= 0 and LogLevel <= 4 and LogLevel == math.floor(LogLevel) then
        level = LogLevel
    else
        level = 4
    end

    -- Use the Logfile filename if set and default to node.log
    if type(Logfile) == string then
        filename = Logfile
    else
        filename = "node.log"
    end

    -- Disable printing if specified
    if LogPrint == false then
        toprint = false
    else
        toprint = true
    end

    -- Disable logging to file if specified
    if LogFile == false then
        tofile = false
    else
        tofile = true
    end

    return nil
end


-- Log the message
-- Can either print the message out, log to file, or both
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

        --stamp = tm.mon .. "/" .. digs(tm.day, 2) .. "/" .. digs(tm.year, 2) .. 
        --    " " .. digs(tm.hour, 2) .. ":" .. digs(tm.min, 2) .. ":" .. 
        --    digs(tm.sec, 2)

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
                M.log("Not much space left for logging: "..space.." bytes", M.warn)
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
