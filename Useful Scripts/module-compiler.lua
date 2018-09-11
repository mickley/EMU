-- This is a script to quickly compile all the required modules on an EMU
-- and delete the uncompiled sources

-- Compile lua modules
node.compile("ds3231.lua")
node.compile("ads1115.lua")
node.compile("bh1750.lua")
node.compile("csv.lua")
node.compile("logging.lua")

-- Remove uncompiled modules
file.remove("ds3231.lua")
file.remove("ads1115.lua")
file.remove("bh1750.lua")
file.remove("csv.lua")
file.remove("logging.lua")

