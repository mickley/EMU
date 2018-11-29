--[[ 

This can be used to test the DS3231 clock modules

If the ESP8266 is currently connected to a wifi network, the script also compares the time to 
internet time, automatically setting the correct time, or adjusting if the time is slightly off.

NOTE: DS3231 modules disable communication via ESPlorer for some reason when plugged in
This script is designed so that when each clock is plugged in, 
the user should close the serial port and re-open it using the Close/Open button in Esplorer
After re-opening the connection, the user should set check=1 to test again.
This can be accomplished by making a Snippet button for Check in the same way as Abort

##### Example to permanently set up wifi #####
wifi.setmode(wifi.STATION)
wifi.sta.config({ssid="WIFI_NAME", pwd="password", save=true})

Module requirements:
ds3231

Firmware Module requirements
gpio, i2c, rtctime, sntp, tmr, uart

##### Version History #####
- 1/2/2018   JGM - Version 1.0:
    - Initial version

 
- 11/28/2018 JGM - Version 1.1:
    - Now only sets the time if the ESP8266 is connected to a wifi network


--]]

-- Local variables
local sda, scl, status, test, timezone, wifi_present

-- Define the SDA and SCL pins
sda = 1
scl = 2

-- Set the timezone: -4 for EDT, -5 for EST
timezone = -5

-- Check for wifi connection.  If connected to wifi, enable additional functionality
wifi_present = wifi.sta.getip() ~= nil

-- Abort message
print("Press the Abort button to stop sensor checking")

-- Only sync internet time if wifi is enabled
if wifi_present then

    -- Sync the time from the internet over SNTP
    sntp.sync(nil, function(sec, usec, server)
    
        -- Start the timer to check for DS3231 if the time synced successfully
        timer:start()
    
        print("SNTP internet time synced successfully. ")
        print("Click the Check snippet button (set check=1) to check a clock")
        print("When you plug in a new clock, click Close and then Open on ESPlorer")
        
    end, function(err)

        -- Disable wifi extra features
        wifi_present = false
    
        -- Print error message
        print('SNTP internet time sync failed.  Check wifi connection')
        print("Click the Check snippet button (set check=1) to check a clock")
        print("When you plug in a new clock, click Close and then Open on ESPlorer")
    end, true)

else
        -- No wifi
        print("Click the Check snippet button (set check=1) to check a clock")
        print("When you plug in a new clock, click Close and then Open on ESPlorer")    
    
end

-- Make a timer object (easier to turn off)
timer = tmr.create()

-- Setup the I2C bus
i2c.setup(0, sda, scl, i2c.SLOW)

-- Set abort and check to zero to start
abort = 0
check = 0

-- Check for a DS3231 clock every second every second
timer:alarm(1000, tmr.ALARM_AUTO, function()

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

    
    -- Should we check for a clock?
    if check == 1 then

        -- Reset check to 0
        check = 0
        
        -- Load the ds3231 module, making sure it loads properly
        status, ds3231 = pcall(require, "ds3231")
    
        -- Initialize the module
        test = ds3231.init(sda, scl)
    
        -- DS3231 clock is present
        if test ~= nil and test == true then
    
            -- Get the time from the DS3231
            clockTime = tonumber(ds3231.getTime("%s", false) + (timezone * 3600))

            -- Get the internet time, if there's wifi
            if wifi_present then
            
                -- Get the real internet time
                realTime = rtctime.get() + (timezone * 3600)

            end
    
            -- Time is not set, let's configure it
            if clockTime < 1000000000 then

                -- Set the time if there's wifi
                if wifi_present then
        
                    -- Configure the clock
                    ds3231.config("INT", nil, false, false, true)
        
                    -- Get the current internet time
                    tm = rtctime.epoch2cal(realTime)
                        
                    -- Set the date and time
                    ds3231.setTime(tm.sec, tm.min, tm.hour, tm.wday, tm.day, tm.mon, tm.year)
        
                    -- Print status message
                    print("DS3231 clock present, wrong time | Time set to " .. ds3231.getTime("%D %T", false))
               
               else
               
                    -- No wifi, just print status message
                    print("DS3231 clock present, wrong time " .. ds3231.getTime("%D %T", false))
                    
               end
    
            -- Time is set
            else

                -- If there's wifi, check if the time is correct
                if wifi_present then
        
                    -- Compare the internet time to the clock time
                    timediff = math.abs(clockTime - realTime)
        
                    -- If there's less than 5 seconds difference, everything is working
                    if timediff <= 5 then
        
                        -- Print status message
                        print("DS3231 clock present, set correctly: " .. ds3231.getTime("%D %T", false))
        
                    -- Time is set, but needs to be adjusted
                    else
        
                        -- Get the current internet time
                        tm = rtctime.epoch2cal(realTime)
                            
                        -- Set the date and time
                        ds3231.setTime(tm.sec, tm.min, tm.hour, tm.wday, tm.day, tm.mon, tm.year)
            
                        -- Print status message
                        print("DS3231 clock present, time adjusted by " .. timediff .. "s : " .. ds3231.getTime("%D %T", false))
        
                    end
                    
                else

                    -- No wifi, just print status message
                    print("DS3231 clock present, time set " .. ds3231.getTime("%D %T", false))
                    
                end
    
            end
    
        -- No clock present
        else
    
            -- Print status
            print("DS3231 clock not present")
    
        end

        print("Waiting. Click the Check Snippet button to check another clock")
    
    end
end)
