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

- 12/9/2016  JGM - Version 1.5:
    - Added thingspeak API key again, and an option to specify whether to sync 
      time over SNTP when connected to wifi

- 4/3/2017   JGM - Version 1.6:
    - Reconfigured for the EMUse project

- 5/10/2017  JGM - Version 1.7:
    - Got rid of the volt_adj parameter for reading internal voltage
    - It's now +/- obsolete with current ESP modules.  

- 9/11/2018  JGM - Version 1.8:
    - Removed wifi sections
    - Adapted config script for publication
    - Added log_level setting

--]]


-- ########### Configuration ###########
-- Set configuration variables here


-- ##### Startup File #####

-- Set startup file to execute by default
startup = "measure.lua"

-- Hours relative to UTC
timezone = -5 -- EST

--Interval to sleep between measurements, in minutes
interval = 15

-- Set the name of the EMU (for the log and CSV files)
emu_name = "EMU_1"

-- The logging level: 0 for off, 1 for errors, 2 for errors and warnings
-- 3 for errors, warnings and status, and 4 for debug/verbose
log_level = 3


-- ##### Configuration Finished #####

print("Configuration settings loaded")
-- #####################################
