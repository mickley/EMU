--[[ 

##### I²C Module for the BH1750FVI Digital Light Sensor #####

See the Datasheet for more information:
https://www.mouser.com/ds/2/348/bh1750fvi-e-186247.pdf

##### Public Function Reference #####
* init(SDA, SCL, i2c_address, sensor_mode) - Initialize the sensor
* getLux(callback_func) - Read a lux value. If a callback function is specified, 
  run that function to receive the luxC value.
* setMode(sensor_mode) - Sets the sensor mode: continuous or single sample, & resolution
* setMeasurementTime(MT) - Sets the measurement time to adjust the range and resolution
* on() - Turns the sensor on
* off() - Turns the sensor off
* reset() - Resets the lux value in the data register

##### Required Firmware Modules #####
i2c, tmr

##### Max RAM usage: 6.7Kb #####

##### Version History #####
- 11/10/2016 JGM - Version 0.1:
    - Initial version

- 11/22/2016 JGM - Version 0.2: 
    - Removed the requirement of the bit firmware module to save some RAM

- 11/28/2016 JGM - Version 0.3:
    - Now uses dynamic timers for all timer-related stuff.  
      This avoids conflicts, but requires a recent firmware

- 2/22/2017 JGM - Version 0.4:
    - Added a check to the init function to see if the sensor was found
    - Added a local variable for i2c_id in case there are multiple i2c buses 
      in the future

- 3/9/2017 JGM - Version 0.5:
    - Added module version printout

- 5/8/2017 JGM - Version 1.0: 
    - Fixed a major bug in the code to change measurement time
    - The delay is now a function of the measurement time 
      (as it should have been)
    - Now returns the validity of the measurement as well.  
      This provides an easy way to check if the measurement is 
      out of range
    - Cleaned up code a bit.

- 12/20/2017 JGM - Version 1.1
    - Fixed bug that resulted in a crash if sensor not present

- 9/24/2018 JGM - Version 1.2
    - Fixed bug that resulted in max values when sensor was not present, 
      gives a reading of false now.
    - Now returns the raw sensor value as a 3rd parameter


--]]


-- ############### Module Initiation ###############


-- Make a table called M, this becomes the class
local M = {}


-- ############### Local variables ###############


-- Local variables
local address, MTReg, resolution, delay, modeCode
local i2c_id = 0
local version = 1.2


-- ############### Private Functions ###############


-- I²C function to write an Opcode to the device
-- We use this to write configuration settings
local function write(opcode)

    -- Send an I²C start condition
    i2c.start(i2c_id)

    -- Setup I²C address in write mode
    i2c.address(i2c_id, address, i2c.TRANSMITTER)

    -- Write the Opcode
    i2c.write(i2c_id, opcode)

    -- Send an I²C stop condition
    i2c.stop(i2c_id)

end

--  I²C function to read two bytes from the sensor
-- 
local function read()

	local test, bytes, raw, valid, lux

    -- Send an I²C start condition
    i2c.start(i2c_id)

    -- Setup I²C address in write mode
    test = i2c.address(i2c_id, 0x23, i2c.RECEIVER)

	-- Receive two bytes from the sensor
	bytes = i2c.read(i2c_id, 2)

	-- Send an I²C stop condition
	i2c.stop(i2c_id)

    -- Get the raw sensor value from the two bytes
	raw = string.byte(bytes, 1) * 256 + string.byte(bytes, 2)

    -- Check if the measurement is valid
    --if raw < 65535 then valid = true else valid = false end
    valid = raw < 65535 and true or false

    
    raw = test and raw or nil

	-- According to datasheet, divide by 1.2 & multiply by resolution
	-- Rescale to account for Measurement Time change
	lux = test and raw / 1.2 * resolution * 69.0 / MTReg or false

	-- TODO: Check for errors

    -- Return the lux measurement and its validity
	return lux, valid, raw

end


-- ############### Public Functions ###############


function M.init(sda, scl, addr, sensor_mode)

	-- Restrict address to 0x23 or 0x5C, and default to 0x5C if not specified
	address = addr ~= nil and (addr == 0x23 or addr == 0x5C) and addr or 0x23

    -- Initialize the I²C bus using the specified pins
    i2c.setup(i2c_id, sda, scl, i2c.SLOW)

    -- Send an I²C start condition
    -- Test to see if the I²C address works
    i2c.start(i2c_id)

    -- Setup the I²C address in write mode and return any acknowledgment
    local test = i2c.address(i2c_id, address, i2c.TRANSMITTER)

    -- Send an I²C start condition
    i2c.stop(i2c_id)

    -- Set defaults for MTReg and Sensitivity
    MTReg = 69
    resolution = 1
    delay = 185

    -- If sensor was found, initialize it
    if test then 

        -- Turn on the sensor
        M.on()
        
    end

    -- Set the mode, defaults to Continuous_H if not set
    M.setMode(sensor_mode)
    
    -- If we got an acknowledgement (test = true) then we've found the device
    return test

end


-- Turn sensor on
function M.on()

	write(0x01)

end


-- Turn sensor off
-- Reset operator won't work in this mode
function M.off()

	write(0x00)

end


-- Reset the data register value
function M.reset()

	write(0x07)

end


-- Sets the sensor mode: 
-- Continuous or one-time and 3 sensitivities: 6 modes total
function M.setMode(mode)

    -- Set the delay: default for H and H2 modes
    delay = math.ceil(185 * MTReg / 69)

    -- Set the resolution: default for H and L modes
    resolution = 1

    if mode == "Continuous_H2" then

		-- 0.5 lx resolution (18 bit), 120ms sampling time
		modeCode = 0x11
		resolution = 0.5

	elseif mode == "Continuous_L" then

		-- 4 lx resolution (15 bit), 16ms sampling time
		modeCode = 0x13
        delay = math.ceil(25 * MTReg / 69)

	elseif mode == "OneTime_H" then

		modeCode = 0x20

	elseif mode == "OneTime_H2" then

		modeCode = 0x21
		resolution = 0.5

	elseif mode == "OneTime_L" then

		modeCode = 0x23
		delay = math.ceil(25 * MTReg / 69)

	else

        -- Default to Continuous_H
        -- 1 lx resolution (16 bit), 120ms sampling time
        modeCode = 0x10

	end

	-- Write the opcode
	write(modeCode)

end


-- Sets the measurement time register for the sensor
-- This allows for adjusting the sensitivity
-- It also allows for extension of the sensor's range.
-- Default is 69, range is from 31 to 254
function M.setMeasurementTime(MT)

	-- Constrain measurment time to [31,254]
	MT = math.min(math.max(MT, 20), 300)

	-- Set the MTReg class variable so we can account for it while measuring
	MTReg = MT

    -- Set the new delay time
    delay = math.ceil(((modeCode == 0x13 or modeCode == 0x23) and 25 or 185) * MTReg / 69)

	-- Shift the first 3 bytes of MT to the last 3
	-- Then add the 01000 prefix by adding 0x40
	local high = math.floor(MT / 32) + 0x40

	-- Get rid of the first 3 bytes in MT by ANDing 0x1F
	-- Then add the 011 prefix by adding 0x60
	local low = (MT % 32) + 0x60

    -- Write the high byte
    write(high)

    -- Write the low byte
    write(low)

end


-- Scales the sensitivity of the sensor by changing measurement time w/o re-scaling
-- Increasing the sensitivity accounts for something covering sensor (window)
-- Decreasing the sensitivity accounts 
-- The range in sensitivity scaling is 0.45 to 3.68.  Default is 1.00
--- void SetSensitivity(float Sens);


function M.getLux(callback_func)

	local lux, valid, raw

	-- Set the mode/initiate a conversion
	write(modeCode)

    -- Check if the first optional argument is a function
    -- If so, we have a callback function to run
    if type(callback_func) == "function" then

		-- Read the value after the specified delay is up
        tmr.create():alarm(delay, tmr.ALARM_SINGLE, function()

        	-- Get the lux value and its validity
        	lux, valid, raw = read()

        	-- Run the callback function with the lux & validity as arguments
            callback_func(lux and math.floor(lux * 100 + 0.5) / 100 or false, valid, raw)
    	end)

    else

    	-- Get the lux value and its validity
    	lux, valid, raw = read()

    	-- Return the lux value and validity, since there is no callback function
    	return lux and math.floor(lux * 100 + 0.5) / 100 or false, valid, raw

    end

end


-- Print out module version information on load
print("Loaded BH1750 v" .. version)

-- Return the module table
return M
