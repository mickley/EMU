--[[ 

##### I²C Module for the BH1750FVI Digital Light Sensor #####


~~ Datasheets ~~


The following sources were of use for reference:



##### Public Function Reference #####
* 

##### Required Firmware Modules #####
i2c

##### Max RAM usage: 6.7Kb #####

##### Version History #####
- 11/10/2016 JGM - Version 0.1:
    - Initial version

- 11/22/2016 JGM - Version 0.2: 
    - Removed the requirement of the bit firmware module to save some RAM

--]]


-- ############### Module Initiation ###############


-- Make a table called M, this becomes the class
local M = {}


-- ############### Local variables ###############


-- Local variables
local address, cursor
local sensitivity, resolution, delay
local MTReg, modeCode



-- ############### Private Functions ###############


-- I²C function to write an Opcode to the device
-- We use this to write configuration settings
local function write(address, opcode)

    print(address)
    print(opcode)

    -- Send an I²C start condition
    i2c.start(0)

    -- Setup I²C address in write mode
    i2c.address(0, 0x23, i2c.TRANSMITTER)

    -- Write the Opcode
    i2c.write(0, opcode)

    -- Send an I²C stop condition
    i2c.stop(0)

end


local function read()

	local lux, bytes, MSB, LSB, intensity

  
    -- Send an I²C start condition
    i2c.start(0)

    -- Setup I²C address in write mode
    i2c.address(0, 0x23, i2c.RECEIVER)

	-- Receive two bytes from the sensor
	bytes = i2c.read(0, 2)

	-- Send an I²C stop condition
	i2c.stop(0)

	-- Get first byte (most significant, leftmost)
	MSB = string.byte(bytes, 1)

	-- Get the second byte (least significant, rightmost)
	LSB = string.byte(bytes, 2)

	-- Shift the first byte left 8 spaces and add the second byte to it
	--MSB = bit.lshift(MSB, 8)
	--intensity = MSB + LSB
	intensity = MSB * 256 + LSB

    --print("MSB: " .. MSB * 256 .. " | " .. "LSB:" .. LSB .. " | " .. intensity)
    --print("MTReg: " .. MTReg .. " | " .. "Res: " .. resolution)

	-- Check to see if we've changed the sensitivity. 
	if sensitivity ~= 1 then

		-- According to datasheet, divide by 1.2 & multiply by Resolution
		-- Sensitivity has been changed, so don't re-scale
		lux = intensity / 1.2 * resolution

	else

		-- According to datasheet, divide by 1.2 & multiply by Resolution
		-- Rescale to account for Measurement Time change
		lux = intensity / 1.2 * resolution * 69.0 / MTReg

	end

	-- TODO: Check for errors

	return lux

end


-- ############### Public Functions ###############


function M.init(sda, scl, address, mode)

	-- Restrict address to 0x23 or 0x5C, and default to 0x5C if not specified
	address = address ~= nil and (address == 0x23 or address == 0x5C) and address or 0x5C

    print(address)
    -- Initialize the I²C bus using the specified pins
    i2c.setup(0, sda, scl, i2c.SLOW)

	-- Turn on the sensor
	M.on()

	-- Set the mode, defaults to Continuous_H if not set
	M.setMode(mode)

    -- Set defaults for MTReg and Sensitivity
    MTReg = 69
    sensitivity = 1.00
    resolution = 1
    delay = 185

end


-- Turn sensor on
function M.on()

	write(address, 0x01)

end


-- Turn sensor off
-- Reset operator won't work in this mode
function M.off()

	write(address, 0x00)

end


-- Reset the data register value
function M.reset()

	write(address, 0x07)

end


-- Set the sensor mode: continuous or one-time, and 3 sensitivities
function M.setMode(mode)


	if mode == "Continuous_H" then

		-- 1 lx resolution (16 bit), 120ms sampling time
		modeCode = 0x10

	elseif mode == "Continuous_H2" then

		-- 0.5 lx resolution (18 bit), 120ms sampling time
		modeCode = 0x11
		resolution = 0.5

	elseif mode == "Continuous_L" then

		-- 4 lx resolution (15 bit), 16ms sampling time
		modeCode = 0x13
		delay = 25

	elseif mode == "OneTime_H" then

		modeCode = 0x20

	elseif mode == "OneTime_H2" then

		modeCode = 0x21
		resolution = 0.5

	elseif mode == "OneTime_L" then

		modeCode = 0x23
		delay = 25

	else

		-- Default to Continuous_H
		modeCode = 0x10

	end

	-- Write the opcode
	write(address, modeCode)


end


-- Sets the measurement time register for the sensor
-- This allows for adjusting the sensitivity
-- It also allows for extension of the sensor's range.
-- Default is 69, range is from 31 to 254
function M.setMeasurementTime(MT)

	-- Constrain measurment time to [31,254]
	MT = math.min(math.max(MT, 31), 254)

	-- Set the MTReg class variable so we can account for it while measuring
	MTReg = MT

	-- Shift the first 3 bytes of MT to the last 3
	-- Then add the 01000 prefix by adding 0x40
	local high = bit.rshift(MT, 5) + 0x40

	-- Get rid of the first 3 bytes in MT by ANDing 0x1F
	-- Then add the 011 prefix by adding 0x60
	local low = bit.band(MT, 0x1F) + 0x60

    -- Send an I²C start condition
    i2c.start(0)

    -- Setup I²C address in write mode
    i2c.address(0, 0x23, i2c.TRANSMITTER)

    -- Write the high byte
    i2c.write(0, high)

    -- Write the high byte
    i2c.write(0, low)

    -- Send an I²C stop condition
    i2c.stop(0)

end


-- Scales the sensitivity of the sensor by changing measurement time w/o re-scaling
-- Increasing the sensitivity accounts for something covering sensor (window)
-- Decreasing the sensitivity accounts 
-- The range in sensitivity scaling is 0.45 to 3.68.  Default is 1.00
--- void SetSensitivity(float Sens);


function M.getLux(callback_func)

	local lux

	-- Set the mode/initiate a conversion
	write(address, modeCode)

    -- Check if the first optional argument is a function
    -- If so, we have a callback function to run
    if type(callback_func) == "function" then

        -- TODO: replace with tmr.create() dynamic timer in new firmware
        -- No need to worry if timer is taken
        -- tmr.create():alarm(delay, tmr.ALARM_SINGLE, function()
        tmr.alarm(5, delay, tmr.ALARM_SINGLE, function()

        	lux = read()

        	-- Run the callback function with the lux as the argument
            callback_func(lux)
    	end)

    else

    	lux = read()

    	return(lux)

    end

end


-- Return the module table
return M
