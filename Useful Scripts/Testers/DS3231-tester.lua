--[[ 

This can be used to test the DS3231 clock and also sets the time
It checks for a clock every second. If one is present, it sets the
time via the internet, then checks to make sure the time is set correctly.

Module requirements:
ds3231

Firmware Module requirements
gpio, i2c, rtctime, sntp, tmr, uart

##### Version History #####
- 1/2/2018   JGM - Version 1.0:
    - Initial version

--]]

-- Local variables
local sda, scl, status, temp, pressure, humidity

-- Define the SDA and SCL pins
sda = 1
scl = 2

-- Set the timezone: -4 for DST, -5 for EST
timezone = -4

-- Sync the time from the internet over SNTP
sntp.sync(nil, function(sec, usec, server)

    -- Start the timer to check for DS3231 if the time synced successfully
    timer:start()

    print("SNTP internet time synced successfully. Waiting...")
    print("Click the Check button to check a clock")
    print("When you plug in a new clock, click Close and then Open")
    
end, function(err)

    -- Print error message
    print('SNTP internet time sync failed.  Check wifi')

end, true)


-- Make a timer object (easier to turn off)
timer = tmr.create()

-- Setup the I2C bus
i2c.setup(0, sda, scl, i2c.SLOW)

-- Set abort and check to zero to start
abort = 0
check = 0

-- Check for a DS3231 clock every second every second
timer:register(1000, tmr.ALARM_AUTO, function()

    -- Stop the timer if aborted
    if abort == 1 then

        -- Unregister/stop the timer
        timer:unregister()

        -- Unload ds3231 module
        ds3231 = nil
        package.loaded.ds3231 = nil

        -- Wait for any callbacks to complete
        tmr.create():alarm(250, tmr.ALARM_SINGLE, function()
    
            -- Print status
            print("Stopped checking for DS3231 clocks")

        end)

    end

    -- Status message
    print("waiting...")
    
    -- Should we check for a clock?
    if check == 1 then

        -- Reset check to 0
        check = 0
        
        -- Load the module
        ds3231 = require("ds3231")
    
        -- Initialize the module
        status = ds3231.init(1, 2)
    
        -- DS3231 clock is present
        if status ~= nil and status == true then
    
            -- Get the time from the DS3231
            clockTime = tonumber(ds3231.getTime("%s", false) + (-5 * 3600))
    
            -- Get the real internet time
            realTime = rtctime.get() + (timezone * 3600)
    
            -- Time is not set, let's configure it
            if clockTime < 1000000000 then
    
                -- Configure the clock
                ds3231.config("INT", nil, false, false, true)
    
                -- Get the current internet time
                tm = rtctime.epoch2cal(realTime)
                    
                -- Set the date and time
                ds3231.setTime(tm.sec, tm.min, tm.hour, tm.wday, tm.day, tm.mon, tm.year)
    
                -- Print status message
                print("DS3231 clock present | Time set to " .. ds3231.getTime("%D %T", false))
    
            -- Time is set, check if it's correct
            else
    
                -- Compare the internet time to the clock time
                timediff = math.abs(clockTime - realTime)
    
                -- If there's less than 5 seconds difference, everything is working
                if timediff <= 5 then
    
                    -- Print status message
                    print("DS3231 clock present | Set correctly: " .. ds3231.getTime("%D %T", false))
    
                -- Time is set, but needs to be adjusted
                else
    
                    -- Get the current internet time
                    tm = rtctime.epoch2cal(realTime)
                        
                    -- Set the date and time
                    ds3231.setTime(tm.sec, tm.min, tm.hour, tm.wday, tm.day, tm.mon, tm.year)
        
                    -- Print status message
                    print("DS3231 clock present | Time adjusted by " .. timediff .. "s : " .. ds3231.getTime("%D %T", false))
    
                end
    
            end
    
        -- No sensor present
        else
    
            -- Print status
            print("DS3231 clock not present")
    
        end
    end
end)
