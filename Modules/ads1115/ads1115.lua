--[[ 

##### ADS1115 16-bit Analog to Digital Converter Module #####
This implements the ADS1115 in NodeMCU

See the Datasheet from TI for more information:
http://www.ti.com/lit/ds/symlink/ads1115.pdf

With some inspiration from the Adafruit arduino driver: 
https://github.com/adafruit/Adafruit_ADS1X15

##### Public Function Reference #####
* init(SDA, SCL)
* readADC(channel) - Read a value from the ADC on the configured channel
* millivolts(value) - Converts value returned by ADC to millivolts 
  based on PGA voltage range settings
* setAddress(i2c_address) - Sets the I²C address to look for an ADS1115 on
* setMode(mode) - Sets the the mode (single shot or continuous)
* setPGA(voltage_range) - Sets the voltage range/sensitivity
* setRate(sampling_rate) - Sets the sampling rate (samples/second)
* setComparator(low, high, queue, latch, alert, mode) - Enables the comparator

##### Required Firmware Modules #####
bit, gpio, i2c, tmr

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

--]]


-- ############### Module Initiation ###############

-- Set module name to the current filename
local moduleName = ...

-- Make a table called M, this becomes the class
local M = {}

-- 
_G[moduleName] = M

-- ############### Local variables ###############


-- Local variables to store various settings
local address, mode, comp, rate, pga, delay, resolution


-- ############### ADS1115 Register Addresses ###############


local REG_CONVERT       = 0x00 -- Conversion register
local REG_CONFIG        = 0x01 -- Configuration register
local REG_THRESHLOW     = 0x02 -- Low threshold registe (for comparator)
local REG_THRESHHIGH    = 0x03 -- High threshhold register (for comparator)


-- ############### ADS1115 Configuration ###############


-- Table of configuration values for the ADS1115
local CONFIG = {}

-- Configure the comparator (Bits 0-1)
CONFIG.COMP_QUEUE_1     = 0x0000 -- 1 conversion exceeding threshholds before ALERT pin is activated
CONFIG.COMP_QUEUE_2     = 0x0001 -- 2 conversions exceeding threshholds before ALERT pin is activated
CONFIG.COMP_QUEUE_4     = 0x0002 -- 4 conversion exceeding threshholds before ALERT pin is activated
CONFIG.COMP_DISABLE     = 0x0003 -- Comparator disabled, and ALERT pin pulled high (default)

-- Configure comparator Latching (Bit 2)
CONFIG.COMP_NOLATCH     = 0x0000 -- ALERT pin will deactivate according to comparator mode (default)
CONFIG.COMP_LATCH       = 0x0004 -- ALERT pin latches on activation and must be manually cleared
 
-- Configure the alert pin (Bit 3)
-- Sets whether the ALERT pin is set to be low or high by the comparator
CONFIG.COMP_ALERT_LOW   = 0x0000 -- Active low.  When ALERT is activated it will be low (default)
CONFIG.COMP_ALERT_HIGH  = 0x0008 -- Active high.  When ALERT is activated it will be high

-- Configuration of the comparator mode (Bit 4)
-- Traditional mode: activates ALERT when over high threshold, remains low until below low threshold
-- Window mode: activates ALERT when over high threshold or under low threshhold
CONFIG.COMP_MODE_HYSTER = 0x0000 -- Traditional comparator mode with hysteresis (default)
CONFIG.COMP_MODE_WINDOW = 0x0010 -- Window comparator mode

-- Configuration of the sampling rate (Bits 5-7)
-- This sets how fast sampling occurs.  
CONFIG.RATE_8           = 0x0000 -- 8 samples per second
CONFIG.RATE_16          = 0x0020 -- 16 samples per second
CONFIG.RATE_32          = 0x0040 -- 32 samples per second
CONFIG.RATE_64          = 0x0060 -- 64 samples per second
CONFIG.RATE_128         = 0x0080 -- 128 samples per second (default)
CONFIG.RATE_250         = 0x00A0 -- 250 samples per second
CONFIG.RATE_475         = 0x00C0 -- 475 samples per second
CONFIG.RATE_860         = 0x00E0 -- 860 samples per second

-- Configuration of the mode (continuous or single shot (Bit 8)
CONFIG.MODE_CONTINUOUS  = 0x0000 -- Convert values continuously
CONFIG.MODE_SINGLE      = 0x0100 -- Single shot mode, power down afterwards (default)

-- Configuration of the PGA or voltage range/sensitivity (Bits 9-11)
CONFIG.PGA_6144         = 0x0000 -- Gain 2/3: +/- 6.144 volts: 0.1875 mV resolution
CONFIG.PGA_4096         = 0x0200 -- Gain 1:   +/- 4.096 volts: 0.125 mV resolution
CONFIG.PGA_2048         = 0x0400 -- Gain 2:   +/- 2.048 volts: 0.0625 mV resolution (default)
CONFIG.PGA_1024         = 0x0600 -- Gain 4:   +/- 1.024 volts: 0.03125 mV resolution
CONFIG.PGA_512          = 0x0800 -- Gain 8:   +/- 0.512 volts: 0.015625 mV resolution
CONFIG.PGA_256          = 0x0A00 -- Gain 16:  +/- 0.256 volts: 0.007813 mV resolution

-- Configuration (Bits 12-14)
CONFIG.MUX_DIFF_01      = 0x0000 -- Difference between A0 (+) and A1 (-) (default)
CONFIG.MUX_DIFF_03      = 0x1000 -- Difference between A0 (+) and A3 (-)
CONFIG.MUX_DIFF_13      = 0x2000 -- Difference between A1 (+) and A3 (-)
CONFIG.MUX_DIFF_23      = 0x3000 -- Difference between A2 (+) and A3 (-)
CONFIG.MUX_SINGLE_0     = 0x4000 -- Difference between A0 (+) and Ground
CONFIG.MUX_SINGLE_1     = 0x5000 -- Difference between A1 (+) and Ground
CONFIG.MUX_SINGLE_2     = 0x6000 -- Difference between A2 (+) and Ground
CONFIG.MUX_SINGLE_3     = 0x7000 -- Difference between A3 (+) and Ground

-- Bit 15
CONFIG.OS_NULL          = 0x0000 -- Unused, no effect
CONFIG.OS_CONVERT       = 0x8000 -- Begin a single conversion when in power down mode (default)


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
    local MSB = bit.rshift(value, 8)
    local LSB = bit.band(value, 0xFF)
    
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
    MSB = bit.lshift(MSB, 8)

    -- Controls the sign of the number returned
    local sign = 1 

-- Check to see if it's a negative number
    -- If so, the leftmost bit will be 1 instead of 0
    if bit.isset(MSB, 15) then

        -- Set the leftmost bit to zero by ANDing 7FFF
        MSB = bit.band(MSB, 0x7FFF)
        
        -- Set the sign to negative 
        sign = -1
    end

    -- OR the two bytes to concatenate them together & multiply by the sign
    local value = bit.bor(MSB, LSB) * sign

    -- Return the value
    return value
    
end


-- ############### Public Functions ###############


-- Initializes the sensor
function M.init(sda, scl)

    -- Set up the defaults
    comp = CONFIG.COMP_DISABLE -- Disable the comparator
    M.setMode("single") -- Set the mode to single shot
    M.setRate(128) -- 128 samples per second
    M.setPGA(6.144) -- +/- 6.144 volts of range

    -- List of possible I²C addresses
    local i2c_addresses = {0x48, 0x49, 0x4A, 0x4B}

    -- Initialize the I²C bus using the specified pins
    i2c.setup(0, sda, scl, i2c.SLOW)

    -- Find the i2c address being used by the sensor
    -- We cycle through a table of possible addresses, checking each one
    for _,addr in ipairs(i2c_addresses) do 

        -- Try to set the address
        local set = M.setAddress(addr)

        -- If address setting worked, stop trying
        if set == true then 

            -- Quit function, returning true for success
            return true

        end

    end

    -- Print out a message if address setting failed
    if address == nil then
        print("Err: no ADS1115 found at any address")

        -- Return false for failure
        return false
    end
end


-- Function to read the value for a given ADC channel setup
-- Can read either single-ended channels (0-3) or
-- differential channels (1 vs 0, 3 vs 0, 3 vs 1, 3 vs 2)
function M.readADC(channel, ...)

    -- Variable to hold channel configuration setting
    local mux = 0

    -- Figure out what channel we're measuring and set mux accordingly
    if channel == 0 then
        mux = CONFIG.MUX_SINGLE_0
    elseif channel == 1 then
        mux = CONFIG.MUX_SINGLE_1
    elseif channel == 2 then
        mux = CONFIG.MUX_SINGLE_2
    elseif channel == 3 then
        mux = CONFIG.MUX_SINGLE_3
    elseif channel == 10 then
        mux = CONFIG.MUX_DIFF_01
    elseif channel == 30 then
        mux = CONFIG.MUX_DIFF_03
    elseif channel == 31 then
        mux = CONFIG.MUX_DIFF_13
    elseif channel == 32 then
        mux = CONFIG.MUX_DIFF_23
    else

       -- Print error message
       print("Err: " .. channel .. " not a valid channel")
       --print("Valid options: 0, 1, 2, 3, 10, 30, 31, 32")

       -- Exit function and return nil
       return nil

    end

    -- OR all the configuration settings together and store in config
    local config = bit.bor(mode, comp, rate, pga, mux)

    -- Write the configuration to the config register
    writeRegister(address, REG_CONFIG, config)

    -- Check if the first optional argument is a function
    -- If so, we have a callback function to run
    if type(arg[1]) == "function" then

        -- TODO: replace with tmr.create() dynamic timer in new firmware
        -- No need to worry if timer is taken
        -- tmr.create():alarm(delay, tmr.ALARM_SINGLE, function()
        tmr.alarm(6, delay, tmr.ALARM_SINGLE, function()
    
            -- Run readRegister(), but discard the value
            -- For some reason, if we don't do this, we get the LAST value
            --readRegister(address, REG_CONVERT)
        
            -- Get the value from the conversion register
            local value = readRegister(address, REG_CONVERT)
        
            -- Set value to zero if we got a negative # from a single-ended channel
            -- this would mean simply that there was no connection to ground
            -- Or that "ground" had a higher voltage
            if value < 0 and channel < 10 then
                value = 0
            end 
    
            -- Run the callback function with the value as the argument
            arg[1](value)
            
        end)

        -- Return nil, since the value is returned via callback function
        return nil

    else 

        -- Get the value from the conversion register
        local value = readRegister(address, REG_CONVERT)
    
        -- Set value to zero if we got a negative # from a single-ended channel
        -- this would mean simply that there was no connection to ground
        -- Or that "ground" had a higher voltage
        if value < 0 and channel < 10 then
            value = 0
        end 

        -- Return the value, since there is no callback function
        return value
    end
end


-- Function to convert a value from the ADC to millivolts
function M.mvolts(value)

    if value >= -32767 and value <= 32767 then
        -- Return the value converted to millivolts and rounded to 3 decimals
        return tonumber(string.format("%.3f",  value * resolution))
    else
        return nil -- Return nil if the value is out of range
    end
end


-- Function to set the i2c address of the ADS1115
-- Normally, this will be done automatically by init(), but if multiple sensors
-- are connected, it needs to be set manually
function M.setAddress(addr)

    -- Check to see if it's one of the approved addresses
    if addr == 0x48 or addr == 0x49 or addr == 0x4A or addr == 0x4B then

        -- Send an I²C start condition
        i2c.start(0)

        -- Setup the I²C address in write mode and return any acknowledgment
        local ack = i2c.address(0, addr, i2c.TRANSMITTER)

        -- Send an I²C start condition
        i2c.stop(0)

        -- If we got an acknowledgement (ack = true) then we've found the device
        if ack == true then
        
            -- Device found
            print("ADS1115 found at: 0x" .. string.format("%02X", addr))

            -- Set the address to use to addr
            address = addr
            
            -- Address setting successful
            return true

        else

            -- Device not found
            print("Err: No ADS1115 found at: 0x" .. string.format("%02X", addr))
            return false

        end

    else
        -- Throw error, not a valid address
        print("Err: 0x" .. string.format("%02X", addr) .. " not valid address")

        -- Address setting failed
        return false
    end

end


-- Sets the mode to either single shot (with power down in between) 
-- or continuous mode where the sensor continuously grabs a value
-- 1 for single, 0 for continuous
function M.setMode(setmode)

    if setmode == "single" then
        -- Set mode to single shot mode 
        -- and specify to begin a conversion if powered down
        mode = bit.bor(CONFIG.MODE_SINGLE, CONFIG.OS_CONVERT)
        
    else
        -- Set mode to continuous measurements
        mode = bit.bor(CONFIG.MODE_CONTINUOUS, CONFIG.OS_NULL)
    end
end


-- Function to set the PGA value
-- This sets the gain on the ADS1115, which changes the sensitivity 
-- and the range of voltages that can be measured
function M.setPGA(range)

    -- Set the PGA voltage measuring range
    -- Ranges are +/- that number of volts and return +/- 32767
    -- E.g. 6.144 sets it to +/- 6.144 volt range
    if range == 6.144 then
        pga = CONFIG.PGA_6144
    elseif range == 4.096 then
        pga = CONFIG.PGA_4096
    elseif range == 2.048 then
        pga = CONFIG.PGA_2048
    elseif range == 1.024 then
        pga = CONFIG.PGA_1024
    elseif range == 0.512 then
        pga = CONFIG.PGA_512
    elseif range == 0.256 then
        pga = CONFIG.PGA_256
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

    -- Set the sampling rate to use.  
    -- Rates are in samples per second
    if setrate == 8 then
        rate = CONFIG.RATE_8
    elseif setrate == 16 then
        rate = CONFIG.RATE_16
    elseif setrate == 32 then
        rate = CONFIG.RATE_32
    elseif setrate == 64 then
        rate = CONFIG.RATE_64
    elseif setrate == 128 then
        rate = CONFIG.RATE_128
    elseif setrate == 250 then
        rate = CONFIG.RATE_250
    elseif setrate == 475 then
        rate = CONFIG.RATE_475
    elseif setrate == 860 then
        rate = CONFIG.RATE_860
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
function M.setComparator(low, high, queue, latch, alert, mode)

    -- Clear the comparator settings
    comp = 0

    -- Set the comparator queue mode = # of times to exceed threshholds
    if queue == 1 then
        comp = bit.bor(comp, CONFIG.COMP_QUEUE_1)
    elseif queue == 2 then
        comp = bit.bor(comp, CONFIG.COMP_QUEUE_2)
    elseif queue == 4 then
        comp = bit.bor(comp, CONFIG.COMP_QUEUE_4)
    else
    
        -- Disable comparator
        comp = CONFIG.COMP_DISABLE 

        print("Err: Comp queue: ".. queue .. "invalid. Comparator disabled")
        --print("Valid options: 1, 2, 4")

        -- Return false for failure
        return false
        
    end

    -- Add latch if specified, otherwise ignore
    if latch == true then
        comp = bit.bor(comp, CONFIG.COMP_LATCH)
    end

    -- Set alert pin action to HIGH if specified (low or nil ignore)
    if alert == "high" then
        comp = bit.bor(comp, CONFIG.COMP_ALERT_HIGH)
    end 

    -- Set comparator mode to window if specified (hysteresis or window ignore)
    if mode == "window" then
        comp = bit.bor(comp, CONFIG.COMP_MODE_WINDOW)
    end

    -- High threshold must be higher than low threshold
    if high > low then

        if high < -32767 or high > 32767 then
            -- Out of bounds error

            -- Disable comparator
            comp = CONFIG.COMP_DISABLE 

            return false
        end

        if low < -32767 or low > 32767 then
            -- Out of bounds error

            -- Disable comparator
            comp = CONFIG.COMP_DISABLE

            return false
        end

        -- If high < 0, convert to a positive number & add the sign bit
        if high < 0 then
            high = bit.bor(high * -1, 0x8000)
        end

        -- If low < 0, convert to a positive number & add the sign bit
        if low < 0 then
            low = bit.bor(low * -1, 0x8000)
        end

        -- Write the threshold values to their registers
        writeRegister(address, REG_THRESHLOW, low)
        writeRegister(address, REG_THRESHHIGH , high)


    else
        -- Throw error: high can't be <= low

        -- Disable comparator
        comp = CONFIG.COMP_DISABLE 

        return false
    end

    -- Return true if successful
    return true

end


-- Return the module table
return M
