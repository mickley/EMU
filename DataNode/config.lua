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
