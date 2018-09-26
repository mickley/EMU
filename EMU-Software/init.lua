--[[ 

##### ESP8266 Init Script #####
This is a customized init.lua script for use with ESP8266 NodeMCU firmware
The script is designed to give multiple chances for a user to exit in case of 
coding errors.  Without these chances, coding errors result in endless reboot loops
without the ability to regain control, requiring reflashing the firmware.

The init script gets configuration information from config.lua
If wifi_required is true it tries to connect to the configured wifi and sync time

Then by default it runs the startup file specified in config.lua

Firmware Module requirements:
file, gpio, sntp, tmr, uart, wifi, (optionally sntp)

##### Version History #####
- 5/23/2016 JGM - Version 1.0:
    - Initial version
        
- 8/23/2016 JGM - Version 1.1:
    - Now configures wifi connection using ssid and pass from config.  
      Performs sntp sync to get current time from time from internet.
      Also fixed some bugs.
          
- 9/10/2016 JGM - Version 2.0:
    - Extensively rewritten to minimize memory use
    - More asynchronous, minimizes time until startup is run by 
      utilizing more callbacks
    - Much less buggy
    
- 11/16/2016 JGM - Version 2.1:
    - Fixed some bugs with configuring wifi
    
- 11/16/2016 JGM - Version 2.2:
    - Added an option to set the hostname of the device through config

- 11/28/2016 JGM - Version 2.3:
    - Now uses dynamic timers for all timer-related stuff.  
      This avoids conflicts, but requires a recent firmware

- 12/11/2016 JGM - Version 2.4:
    - Now uses pcall() to run the Init, Setup, and dofile() functions to 
      minimize errors
    - Checks to make sure that all required modules are present
    - Pulling D0 to ground (LOW) will also abort init.lua

- 4/03/2017  JGM - Version 2.5:
    - Now uses wifi.eventmon.reg() instead of wifi.sta.eventMonReg() (deprecated)
    - A few other small changes, cleaning things up

- 4/13/2017  JGM - Version 2.6:
    - Switched to using D5 to abort instead of D0, which needs
      to be reserved for coming out of deep sleep

- 5/10/2017  JGM - Version 3.0:
    - Ditched the setup() function, we never used any of its functionality
    - Now adds configuration options in the top of the script, for more flexibility
    - Some other small coding changes to improve readability and efficiency

- 9/11/2018  JGM - Version 3.1:
    - Adapted script for publication
    - Removed wifi-oriented code to simplify

--]]


-- ########### Configuration ###########

-- These are configuration settings for init.lua
local cfg = {}

-- Delay time in milliseconds before running Init()
-- During this time, setting abort=1 will quit
-- Don't set this lower than ~200 or you cannot gain control back if there are problems
-- Suggested setting: 200-2000
cfg.delay = 1000

-- Hardware pin that can be used to abort init.lua, preventing startup from running
-- To abort, connect the specified pin to ground.  
-- The following pins can be used: 1, 2, 4, 5, 6, 7, 8 
-- Note: 0 is often used to wait from deep sleep.  3 cannot be used at all
-- Note: 4 will turn on the LED when grounded
cfg.abortpin = 7

-- Current version of init.lua
local initversion = 3.1

-- ########### Init Functions ###########


-- The Init function should be run by a timer (see bottom) after 0.5 - 2 seconds
-- This is important to allow the user to get out of init.lua if there's a major error
local function Init()


    -- ########## Early Config: Load config.lua ##########


    -- Check for config.lua
    if file.exists("config.lua") then

        -- Get our startup variables from config.lua
        pcall(dofile, "config.lua")
    else
        -- Throw an error message
        print("Error: no config.lua file")
        
        -- Quit the Init() function
        return
    end


    -- ########## Abort or Run Startup File ##########


    -- If the user sets abort = 1 then abort
    if abort == 1 then

        -- Delete abort variable
        abort = nil 

        -- Detected abort, so we quit without doing anything
        print("Startup aborted")

    -- Check if the startup file from config.lua exists.  If not, abort
    elseif not file.exists(startup) then


        -- Startup file doesn't exist, so we quit without doing anything
        print(startup .. " does not exist")

    -- Don't wait, run immediately
    else

        -- Run the startup file set in config.lua
        print("Executing " .. startup)

        -- Run the startup file after 10 milliseconds
        -- This gives time for init.lua to finish, freeing up RAM
        tmr.create():alarm(10, tmr.ALARM_SINGLE, function()
            pcall(dofile, startup)
        end) -- End of timer to run startup
        
    end -- End of conditions check

end -- End of Init() function


-- ###################################

-- ########### Run Startup ###########


-- Setup Instructions
print("Init.lua v" .. initversion)
print("Set abort=1 or pull D" .. cfg.abortpin .. " pin low to abort and exit init.lua")
abort = 0

-- Check to see that modules required in init.lua are present
if type(tmr) ~= "romtable" or type(file) ~= "romtable" or 
    type(uart) ~= "romtable" or type(gpio) ~= "romtable" then
    
    -- Print message and exit init.lua if we're missing something
    print("Missing required firmware module")
    print("Need: file, gpio, tmr, uart")

else

    -- Setup the abort pin as input
    gpio.mode(cfg.abortpin, gpio.INPUT)

    -- Set a timer to run the Init() function after a specified delay
    -- This delay gives time to set abort=1 if needed
    tmr.create():alarm(cfg.delay, tmr.ALARM_SINGLE, function()

        -- Only run the Init() function if the abort pin is high (default) or abort ~= 1
        -- Connect the abort pin to ground or set abort=1 to abort
        if gpio.read(cfg.abortpin) == 0 then

            -- Detected abort, so we quit
            print("Aborting (D" .. cfg.abortpin .. " Low)") 

        -- Check to see if startup was aborted by the user setting abort = 1
        elseif abort == 1 then

            -- Delete abort variable
            abort = nil

            -- Detected abort, so we quit
            print("Aborting (User set abort=1)")

        else

            -- No reason to abort, so run the Init() function
            pcall(Init)

        end -- End of abort check
        
    end) -- End of delay timer

end -- End of required modules check
