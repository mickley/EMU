--[[ 

##### Lua Configuration #####
This file is run by init.lua and allows simple configurations to be loaded
In particular, it sets the next file to be run by init.lua (if any)
Replace the EDITME sections with your own information

##### Version History #####
- 5/23/2016 JGM - Version 1.0:
	- Initial version
       
- 8/23/2016 JGM - Version 1.1:
	- Added settings for wifi network, time sync, timezone, voltage measuring and thingspeak

- 9/10/2016 JGM - Version 1.2:
    - Added wifi_required variable for init.lua v2.0

- 10/10/2016 JGM - Version 1.3:
    - Added wifi_ip and wifi_router variables for setting static IP addresses
      Using wifi.sta.setip(), this lowers connection time from 1000ms to 155ms

- 11/16/2016 JGM - Version 1.4: 
    - Added hostname and removed thingspeak API key

- 12/9/2016 JGM - Version 1.5:
    - Added thingspeak API key again, and an option to specify whether to sync 
      time over SNTP when connected to wifi

--]]


-- ########### Configuration ###########
-- Set configuration variables here


-- ##### Startup File #####

-- Set startup file to execute by default
startup = "startupfile.lua"


-- ##### Wifi Options #####

-- WIFI SSID (network name)
wifi_ssid = "EDITME"
wifi_pass = "EDITME"

-- Is Wifi required for startup routine?
-- If so, then init.lua will try to wait until connected before running startup
wifi_required = false

-- Set the router IP address and the IP address you want the ESP to have
-- This speeds up connecting when trying to save power
wifi_ip = nil
wifi_router = nil

-- Set the hostname of the ESP
-- If running a webserver, you can then go to http://hostname
wifi_hostname = nil


-- ##### Time Options #####

-- Sync the time via sntp when connected to wifi
wifi_sync_time = true

-- Time sync ntp server
-- Lots of options here, find the best one
-- Note: might be good to find an alternate
timeserver1 = "us.pool.ntp.org"
timeserver2 = "pool.ntp.org"
-- 1.us.pool.ntp.org

-- Hours relative to UTC
timezone = -5

--Interval to sleep in minutes
interval = 15


-- ##### Miscellany #####

-- adc.readvdd33() is low by about 0.25V for D1 Mini
volt_adj = 0.25

-- Add the thingspeak API key to use
thingspeak_API = "EDITME"


-- ##### Configuration Finished #####

print("Configuration settings loaded")
-- #####################################
