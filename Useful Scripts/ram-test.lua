-- This is a script to test the RAM usage of a module
-- Run it with init.lua/config.lua
-- Edit the test variable to specify the module to test

-- Collect the garbage
collectgarbage()

-- Module to test memory usage for
local test = "mathfunc"

-- Get the ram before loading the module
local pre = node.heap()

-- Load the module
local mod = require(test)

-- Show the amount of RAM the module requires
print("Module " .. test .. ": " .. pre - node.heap() )

-- Release the module to free up the memory
mod = nil
package.loaded[test] = nil   

-- Collect the garbage
collectgarbage()

-- Show any ram that wasn't returned when the module was released
print("RAM Leaked: " .. pre - node.heap() )

