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


--]]


-- ########### Configuration ###########
-- Set configuration variables here

-- WIFI SSID (network name)
wifi_ssid = "EDITME"
wifi_pass = "EDITME"

-- Set startup routine to run by default
startup = "sensorlog.lua"

--Interval to sleep in seconds
interval = (15 * 60)

-- Hours relative to UTC
timezone = -4

-- Time sync ntp server
-- Lots of options here, find the best one
-- Note: might be good to find an alternate
timeserver1 = "us.pool.ntp.org"
timeserver2 = "pool.ntp.org"
-- 1.us.pool.ntp.org

-- adc.readvdd33() is low by about 0.25V for D1 Mini
volt_adj = 0.25

-- Set Thingspeak API key
thingspeak_api = "EDITME"

print("Configuration settings loaded")
-- #####################################
