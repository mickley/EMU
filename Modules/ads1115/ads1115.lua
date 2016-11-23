--[[ 

##### ADS1115 16-bit Analog to Digital Converter Module #####
This implements the ADS1115 in NodeMCU

See the Datasheet from TI for more information:
http://www.ti.com/lit/ds/symlink/ads1115.pdf

With some inspiration from the Adafruit arduino driver: 
https://github.com/adafruit/Adafruit_ADS1X15

##### Public Function Reference #####
* init(SDA, SCL, i2c_address) - Initialize the module
* readADC(channel, callback_func) - Read a value from the ADC on the configured channel.
  If a callback function is specified, run that function to receive the ADC value.
* millivolts(value) - Converts value returned by ADC to millivolts 
  based on PGA voltage range settings
* setMode(mode) - Sets the the mode (single shot or continuous)
* setPGA(voltage_range) - Sets the voltage range/sensitivity
* setRate(sampling_rate) - Sets the sampling rate (samples/second)
* setComparator(low, high, queue, latch, alert, mode) - Enables the comparator

##### Required Firmware Modules #####
gpio, i2c, tmr

##### Max RAM usage: 8.5Kb #####

##### Version History #####
- 8/29/2016 JGM - Version 0.1:
    - Initial version

- 8/30/2016 JGM - Version 0.2:
    - Put all config variables into a table instead of each being a local variable.
      There's a limit of 50 local variables per function/module in NodeMCU and we were close.
      This actually seems to consume nearly 2kb of ram, 
      but it's worth it for a fully fledged module
    - The init() function uses setRate(), setPGA(), and setAddress() to do it's business.  
      setAddress() also includes more checking to make sure we have a device

- 8/31/2016 JGM - Version 0.3:
    - Deals with negative numbers correctly, including in single shot mode
    - Added mvolts() function to convert values into millivolts
    - Added setComparator() function to enable and configure the comparator
    - Added setMode() function to set single shot or continuous mode
    - Numerous bug fixes, and cleaned up code considerably
    
- 9/2/2016 JGM - Version 0.4:
    - Fixed error in setRate() that resulted in improper delays
    - readADC() now optionally takes a callback function as the second argument
      If this is defined, it will wait until conversion is finished before
      reading the value, and will return the value as an argument in the callback
      function.
      
- 9/2/2016 JGM - Version 0.5:
    - Rewrote setComparator() to use optional arguments

- 9/10/2016 JGM - Version 0.6:
    - No longer sets address automatically.  Address is now an optional argument
      for init().  setAddress() has been removed.

- 9/14/2016 JGM - Version 1.0:
    - Rewritten to use less memory, saving 5-6 Kb

- 11/22/2016 JGM - Version 1.1: 
    - Removed the requirement of the bit firmware module to save some RAM
    
--]]


-- ############### Module Initiation ###############


-- Make a table called M, this becomes the class
local M = {}


-- ############### Local variables ###############


-- Local variables to store various settings
local address, mode, comp, rate, pga, delay, resolution


-- ############### ADS1115 Register Addresses ###############


-- CONVERT       = 0x00 -- Conversion register
-- CONFIG        = 0x01 -- Configuration register
-- THRESHLOW     = 0x02 -- Low threshold registe (for comparator)
-- THRESHHIGH    = 0x03 -- High threshhold register (for comparator)


-- ############### ADS1115 Configuration ###############


-- List of configuration values for the ADS1115

-- Configure the comparator (Bits 0-1)
-- COMP_QUEUE_1     = 0x0000 -- 1 conversion exceeding threshholds before ALERT pin is activated
-- COMP_QUEUE_2     = 0x0001 -- 2 conversions exceeding threshholds before ALERT pin is activated
-- COMP_QUEUE_4     = 0x0002 -- 4 conversion exceeding threshholds before ALERT pin is activated
-- COMP_DISABLE     = 0x0003 -- Comparator disabled, and ALERT pin pulled high (default)

-- Configure comparator Latching (Bit 2)
-- COMP_NOLATCH     = 0x0000 -- ALERT pin will deactivate according to comparator mode (default)
-- COMP_LATCH       = 0x0004 -- ALERT pin latches on activation and must be manually cleared
 
-- Configure the alert pin (Bit 3)
-- Sets whether the ALERT pin is set to be low or high by the comparator
-- COMP_ALERT_LOW   = 0x0000 -- Active low.  When ALERT is activated it will be low (default)
-- COMP_ALERT_HIGH  = 0x0008 -- Active high.  When ALERT is activated it will be high

-- Configuration of the comparator mode (Bit 4)
-- Traditional mode: activates ALERT when over high threshold, remains low until below low threshold
-- Window mode: activates ALERT when over high threshold or under low threshhold
-- COMP_MODE_HYSTER = 0x0000 -- Traditional comparator mode with hysteresis (default)
-- COMP_MODE_WINDOW = 0x0010 -- Window comparator mode

-- Configuration of the sampling rate (Bits 5-7)
-- This sets how fast sampling occurs.  
-- RATE_8           = 0x0000 -- 8 samples per second
-- RATE_16          = 0x0020 -- 16 samples per second
-- RATE_32          = 0x0040 -- 32 samples per second
-- RATE_64          = 0x0060 -- 64 samples per second
-- RATE_128         = 0x0080 -- 128 samples per second (default)
-- RATE_250         = 0x00A0 -- 250 samples per second
-- RATE_475         = 0x00C0 -- 475 samples per second
-- RATE_860         = 0x00E0 -- 860 samples per second

-- Configuration of the mode (continuous or single shot (Bit 8)
-- MODE_CONTINUOUS  = 0x0000 -- Convert values continuously
-- MODE_SINGLE      = 0x0100 -- Single shot mode, power down afterwards (default)

-- Configuration of the PGA or voltage range/sensitivity (Bits 9-11)
-- PGA_6144         = 0x0000 -- Gain 2/3: +/- 6.144 volts: 0.1875 mV resolution
-- PGA_4096         = 0x0200 -- Gain 1:   +/- 4.096 volts: 0.125 mV resolution
-- PGA_2048         = 0x0400 -- Gain 2:   +/- 2.048 volts: 0.0625 mV resolution (default)
-- PGA_1024         = 0x0600 -- Gain 4:   +/- 1.024 volts: 0.03125 mV resolution
-- PGA_512          = 0x0800 -- Gain 8:   +/- 0.512 volts: 0.015625 mV resolution
-- PGA_256          = 0x0A00 -- Gain 16:  +/- 0.256 volts: 0.007813 mV resolution

-- Configuration of the channel (Bits 12-14)
-- MUX_DIFF_01      = 0x0000 -- Difference between A0 (+) and A1 (-) (default)
-- MUX_DIFF_03      = 0x1000 -- Difference between A0 (+) and A3 (-)
-- MUX_DIFF_13      = 0x2000 -- Difference between A1 (+) and A3 (-)
-- MUX_DIFF_23      = 0x3000 -- Difference between A2 (+) and A3 (-)
-- MUX_SINGLE_0     = 0x4000 -- Difference between A0 (+) and Ground
-- MUX_SINGLE_1     = 0x5000 -- Difference between A1 (+) and Ground
-- MUX_SINGLE_2     = 0x6000 -- Difference between A2 (+) and Ground
-- MUX_SINGLE_3     = 0x7000 -- Difference between A3 (+) and Ground

-- Bit 15
-- OS_NULL          = 0x0000 -- Unused, no effect
-- OS_CONVERT       = 0x8000 -- Begin a single conversion when in power down mode (default)


-- ############### Private Functions ###############


-- I²C function to write a value to register on a device at address 
-- We use this to write configuration settings to registers
local function writeRegister(address, register, value)

    -- Send an I²C start condition
    i2c.start(0)

    -- Setup I²C address in write mode
    i2c.address(0, address, i2c.TRANSMITTER)

    -- Write the register address we'd like to write to
    i2c.write(0, register)

    -- Extract the two bytes from the value to write
    -- Have to remove one half and then the other half of the 16 bits
    --local MSB = bit.rshift(value, 8)
    local MSB = math.floor(value / 256)

    --local LSB = bit.band(value, 0xFF)
    local LSB = value % 256
    
    -- Write the most significant byte (leftmost 8 bits)
    i2c.write(0, MSB)

    -- Write the least significant byte (rightmost 8 bits)
    i2c.write(0, LSB)

    -- Send an I²C stop condition
    i2c.stop(0)

end


-- I²C function to read a 16 bit value from a register on a device with address
-- We use this to read the contents of registers, especially the conversion reg
local function readRegister(address, register)

    -- Send an I²C start condition
    i2c.start(0)

    -- Setup I²C address in write mode
    i2c.address(0, address, i2c.TRANSMITTER)

    -- Write the address of the register we'd like to read
    i2c.write(0, register)

    -- Send an I²C stop condition
    i2c.stop(0)

    -- Send an I²C start condition again
    i2c.start(0)

    -- Setup I²C address in read mode
    i2c.address(0, address, i2c.RECEIVER)

    -- Receive two bytes from the sensor
    local bytes = i2c.read(0, 2)

    -- Send an I²C stop condition
    i2c.stop(0)

    -- Get first byte (most significant, leftmost)
    local MSB = string.byte(bytes, 1)

    -- Get the second byte (least significant, rightmost)
    local LSB = string.byte(bytes, 2)

    -- Shift the first byte left 8 spaces
    --MSB = bit.lshift(MSB, 8)
    MSB = MSB * 256

    -- Controls the sign of the number returned
    local sign = 1 

    --bit.isset(MSB, 15) and bit.bor(bit.band(MSB, 0x7FFF), LSB) * -1 or bit.bor(MSB, LSB)

    -- Check to see if it's a negative number
    -- If so, the leftmost bit will be 1 instead of 0
    --if bit.isset(MSB, 15) then
    if MSB > 0x7FFF then -- If it's greater than 32767

        -- Set the leftmost bit to zero by ANDing 7FFF
        --MSB = bit.band(MSB, 0x7FFF)
        MSB = MSB - 0x8000 -- Subtract 32768
        
        -- Set the sign to negative 
        sign = -1
    end

    -- OR the two bytes to concatenate them together & multiply by the sign
    --local value = bit.bor(MSB, LSB) * sign
    local value = (MSB + LSB) * sign

    -- Return the value
    return value
    
end


-- ############### Public Functions ###############


-- Initializes the sensor
function M.init(sda, scl, i2c_addr)

    -- If address is specified, check if its between 0x48 and 0x4B and use if so
    -- Otherwise use 0x48 by default
    if i2c_addr ~= nil and i2c_addr >= 0x48 and i2c_addr <= 0x4B then
        address = i2c_addr
    else
        address = 0x48
    end

    -- Set up the defaults
    comp = 0x0003 -- Disable the comparator
    M.setMode("single") -- Set the mode to single shot
    M.setRate(128) -- 128 samples per second
    M.setPGA(6.144) -- +/- 6.144 volts of range

    -- Test to see if the I²C address works
    -- Initialize the I²C bus using the specified pins
    i2c.setup(0, sda, scl, i2c.SLOW)

    -- Send an I²C start condition
    i2c.start(0)

    -- Setup the I²C address in write mode and return any acknowledgment
    local test = i2c.address(0, address, i2c.TRANSMITTER)

    -- Send an I²C start condition
    i2c.stop(0)

    -- If we got an acknowledgement (test = true) then we've found the device
    return test

end


-- Function to read the value for a given ADC channel setup
-- Can read either single-ended channels (0-3) or
-- differential channels (1 vs 0, 3 vs 0, 3 vs 1, 3 vs 2)
function M.readADC(channel, callback_func)

    -- Variable to hold channel configuration setting
    local mux = 0

    -- Figure out what channel we're measuring and set mux accordingly
    if channel == 0 then
        mux = 0x4000 -- Difference between A0 (+) and Ground
    elseif channel == 1 then
        mux = 0x5000 -- Difference between A1 (+) and Ground
    elseif channel == 2 then
        mux = 0x6000 -- Difference between A2 (+) and Ground
    elseif channel == 3 then
        mux = 0x7000 -- Difference between A3 (+) and Ground
    elseif channel == 10 then
        mux = 0x0000 -- Difference between A0 (+) and A1 (-) (default)
    elseif channel == 30 then
        mux = 0x1000 -- Difference between A0 (+) and A3 (-)
    elseif channel == 31 then
        mux = 0x2000 -- Difference between A1 (+) and A3 (-)
    elseif channel == 32 then
        mux = 0x3000 -- Difference between A2 (+) and A3 (-)
    else

       -- Print error message
       print("Err: " .. channel .. " not a valid channel")
       --print("Valid options: 0, 1, 2, 3, 10, 30, 31, 32")

       -- Exit function and return false
       return false

    end

    -- OR all the configuration settings together and store in config
    --local config = bit.bor(mode, comp, rate, pga, mux)
    local config = mode + comp + rate + pga + mux

    -- Write the configuration to the Config register (0x01)
    writeRegister(address, 0x01, config)

    -- Check if the first optional argument is a function
    -- If so, we have a callback function to run
    if type(callback_func) == "function" then
    
        -- TODO: replace with tmr.create() dynamic timer in new firmware
        -- No need to worry if timer is taken
        -- tmr.create():alarm(delay, tmr.ALARM_SINGLE, function()
        tmr.alarm(6, delay, tmr.ALARM_SINGLE, function()
    
            -- Run readRegister(), but discard the value
            -- For some reason, if we don't do this, we get the LAST value
            --readRegister(address, REG_CONVERT)
        
            -- Get the value from the Conversion register (0x00)
            local value = readRegister(address, 0x00)
        
            -- Set value to zero if we got a negative # from a single-ended channel
            -- this would mean simply that there was no connection to ground
            -- Or that "ground" had a higher voltage
            value = value < 0 and channel < 10 and 0 or value
    
            -- Run the callback function with the value as the argument
            callback_func(value)
            
        end)

        -- Return nil, since the value is returned via callback function
        return nil

    else 

        -- Get the value from the Conversion register (0x00)
        local value = readRegister(address, 0x00)
    
        -- Set value to zero if we got a negative # from a single-ended channel
        -- this would mean simply that there was no connection to ground
        -- Or that "ground" had a higher voltage
        value = value < 0 and channel < 10 and 0 or value

        -- Return the value, since there is no callback function
        return value
    end
end


-- Function to convert a value from the ADC to millivolts
function M.mvolts(value)

    -- Return the value converted to millivolts and rounded to 3 decimals
    return tonumber(string.format("%.3f",  value * resolution))
    
end


-- Sets the mode to either single shot (with power down in between) 
-- or continuous mode where the sensor continuously grabs a value
-- 1 for single, 0 for continuous
function M.setMode(setmode)

    -- Set mode to single shot (Bit 8) and begin a conversion if powered down (Bit 15)
    -- Alternatively, set mode to continuous measurents and don't trigger a conversion
    if setmode == "single" then
        --mode = bit.bor(0x0100, 0x8000)
        mode = 0x0100 + 0x8000
    else
        mode = 0 -- bit.bor(0x0000, 0x0000)
    end

end



-- Function to set the PGA value
-- This sets the gain on the ADS1115, which changes the sensitivity 
-- and the range of voltages that can be measured
function M.setPGA(range)

    -- Configuration of the PGA or voltage range/sensitivity (Bits 9-11)
    -- Ranges are +/- that number of volts and return +/- 32767
    -- E.g. 6.144 sets it to +/- 6.144 volt range
    if range == 6.144 then
        pga = 0x0000 -- Gain 2/3: +/- 6.144 volts: 0.1875 mV resolution
    elseif range == 4.096 then
        pga = 0x0200 -- Gain 1:   +/- 4.096 volts: 0.125 mV resolution
    elseif range == 2.048 then
        pga = 0x0400 -- Gain 2:   +/- 2.048 volts: 0.0625 mV resolution (default)
    elseif range == 1.024 then
        pga = 0x0600 -- Gain 4:   +/- 1.024 volts: 0.03125 mV resolution
    elseif range == 0.512 then
        pga = 0x0800 -- Gain 8:   +/- 0.512 volts: 0.015625 mV resolution
    elseif range == 0.256 then
        pga = 0x0A00 -- Gain 16:  +/- 0.256 volts: 0.007813 mV resolution
    else
    
        -- Throw error and explain
        print("Err: PGA not set. " .. range .. " is invalid")
        --print("Acceptable values: 6.144, 4.096, 2.048, 1.024, 0.512, 0.256")

        -- Return false for failure
        return false
    end

    -- Set the resolution in millivolts for one bit of precision 
    resolution = range * 1000 / 32767

    -- Return true for success
    return true
end


-- Function to set the sampling rate
-- This sets how long/often it takes for the ADS1115 to record a sample
-- Lower sampling rates use more power, but can be more accurate
function M.setRate(setrate)

    -- Configuration of the sampling rate (Bits 5-7) 
    -- Rates are in samples per second
    if setrate == 8 then
        rate = 0x0000 -- 8 samples per second
    elseif setrate == 16 then
        rate = 0x0020 -- 16 samples per second
    elseif setrate == 32 then
        rate = 0x0040 -- 32 samples per second
    elseif setrate == 64 then
        rate = 0x0060 -- 64 samples per second
    elseif setrate == 128 then
        rate = 0x0080 -- 128 samples per second (default)
    elseif setrate == 250 then
        rate = 0x00A0 -- 250 samples per second
    elseif setrate == 475 then
        rate = 0x00C0 -- 475 samples per second
    elseif setrate == 860 then
        rate = 0x00E0 -- 860 samples per second
    else
    
        -- Throw error and explain
        print("Err: Rate not set. " .. setrate .. " is invalid")
        --print("Acceptable values (per second): 8, 16, 32, 64, 128, 250, 475, 860")

        -- Return false for failure
        return false
        
    end

    -- set the delay to wait before reading the conversion register
    -- This is the inverse of the sampling rate in milliseconds
    delay = math.ceil( 1000 / setrate )

    -- Return true for success
    return true
end


-- Function to set the comparator
function M.setComparator(mode, low, high, latch, queue, alert)

    -- Clear the comparator settings
    comp = 0

    -- Configure comparator Latching (Bit 2). On is 0x0004, off is 0x0000
    --comp = latch and bit.bor(comp, 0x0004) or comp
    if latch then
        comp = 0x0004 -- Latch on
    end

    -- Configure the comparator (Bits 0-1)
    -- 1 conversion exceeding threshholds before ALERT pin is activated (0x0000)
    -- 2 conversions exceeding threshholds before ALERT pin is activated (0x0001)
    -- 4 conversion exceeding threshholds before ALERT pin is activated (0x0002)
    if queue == 2 then
        --comp = bit.bor(comp, 0x0001)
        comp = comp + 0x0001
    elseif queue == 4 then
        --comp = bit.bor(comp, 0x0002)
        comp = comp + 0x0002
    end
    
    -- Configure the alert pin (Bit 3)
    -- Sets whether the ALERT pin is set to be low or high by the comparator
    -- Active low.  When ALERT is activated it will be low (default) (0x0000)
    -- Active high.  When ALERT is activated it will be high (0x0008)
    if alert == "high" then
        --comp = bit.bor(comp, 0x0008)
        comp = comp + 0x0008
    end

    -- The low threshold argument is set
    if low ~= nil then
        if low < -32767 or low > 32767 then
            -- Out of bounds error

            -- Disable comparator
            comp = 0x0003

            return false
        end

        -- If low < 0, convert to a positive number & add the sign bit
        if low < 0 then
            --low = bit.bor(low * -1, 0x8000)
            low = (low * -1) + 0x8000
        end

        -- Write the Low threshold register (0x02)
        writeRegister(address, 0x02, low)

    end

    -- The high threshold argument is set
    if high ~= nil then

        if high < -32767 or high > 32767 then
            -- Out of bounds error

            -- Disable comparator
            comp = 0x0003

            return false
        end

        -- If high < 0, convert to a positive number & add the sign bit
        if high < 0 then
            --high = bit.bor(high * -1, 0x8000)
            high = (high * -1) + 0x8000
        end

        -- Write the High threshold register (0x03)
        writeRegister(address, 0x03 , high)

    end

    -- Configuration of the comparator mode (Bit 4)
    -- Traditional mode: activates ALERT when over high threshold, remains low until below low threshold (0x0000)
    -- Window mode: activates ALERT when over high threshold or under low threshhold (0x0010)
    -- Disable comparator: Bits 0-1 (0x0003)
    if mode == "window" then
        --comp = bit.bor(comp, 0x0010)
        comp = comp + 0x0010
    elseif mode == "disable" then
        --comp = bit.bor(comp, 0x0003)
        comp = comp + 0x0003
    end
    
    -- Return true if successful
    return true

end


-- Return the module table
return M
