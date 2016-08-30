local moduleName = ...
local M = {}
_G[moduleName] = M

-- Variables to store current settings
local address, comp, rate, pga, delay

-- List of possible i2c addresses
local i2c_addresses = {72, 73, 74, 75}




-- ADS1115 Register Addresses
local REG_CONVERT               = 0x00 -- Conversion register
local REG_CONFIG                = 0x01 -- Configuration register
local REG_THRESHLOW             = 0x02 -- 
local REG_THRESHHIGH            = 0x03 -- 



-- Configuration variable
local CONFIG = {}

-- Configure the comparator (Bits 0-1)
CONFIG["COMP_QUEUE_1"]       = 0x0000 -- 1 conversion exceeding threshholds before ALERT pin is activated
CONFIG["COMP_QUEUE_2"]       = 0x0001 -- 2 conversions exceeding threshholds before ALERT pin is activated
CONFIG["COMP_QUEUE_4"]       = 0x0002 -- 4 conversion exceeding threshholds before ALERT pin is activated
CONFIG["COMP_DISABLE"]       = 0x0003 -- Comparator disabled, and ALERT pin pulled high (default)

-- Configure comparator Latching (Bit 2)
CONFIG["COMP_NOLATCH"]       = 0x0000 -- ALERT pin will deactivate according to comparator mode (default)
CONFIG["COMP_LATCH"]         = 0x0004 -- ALERT pin latches on activation and must be manually cleared
 
-- Configure the alert pin (Bit 3)
-- Sets whether the ALERT pin is set to be low or high by the comparator
CONFIG["COMP_ALERT_LOW"]     = 0x0000 -- Active low.  When ALERT is activated it will be low (default)
CONFIG["COMP_ALERT_HIGH"]    = 0x0008 -- Active high.  When ALERT is activated it will be high

-- Configuration of the comparator mode (Bit 4)
-- Traditional mode: activates ALERT when over high threshhold, remains low until below low threshhold
-- Window mode: activates ALERT when over high threshhold or under low threshhold
CONFIG["COMP_MODE_HYSTER"]   = 0x0000 -- Traditional comparator mode with hysteresis (default)
CONFIG["COMP_MODE_WINDOW"]   = 0x0010 -- Window comparator mode


-- Configuration of the sampling rate (Bits 5-7)
-- This sets how fast sampling occurs.  
CONFIG["RATE_8"]             = 0x0000 -- 8 samples per second
CONFIG["RATE_16"]            = 0x0020 -- 16 samples per second
CONFIG["RATE_32"]            = 0x0040 -- 32 samples per second
CONFIG["RATE_64"]            = 0x0060 -- 64 samples per second
CONFIG["RATE_128"]           = 0x0080 -- 128 samples per second (default)
CONFIG["RATE_250"]           = 0x00A0 -- 250 samples per second
CONFIG["RATE_475"]           = 0x00C0 -- 475 samples per second
CONFIG["ATE_860"]           = 0x00E0 -- 860 samples per second

-- Configuration of the (Bit 8)
CONFIG["MODE_CONTINUOUS"]    = 0x0000 -- Convert values continuously
CONFIG["MODE_SINGLE"]        = 0x0100 -- Single shot mode, power down afterwards (default)


-- Configuration of the PGA or voltage range/sensitivity (Bits 9-11)
CONFIG["PGA_6144"]           = 0x0000 -- Gain 2/3: +/- 6.144 volts: 0.1875 mV resolution
CONFIG["PGA_4096"]           = 0x0200 -- Gain 1:   +/- 4.096 volts: 0.125 mV resolution
CONFIG["PGA_2048"]           = 0x0400 -- Gain 2:   +/- 2.048 volts: 0.0625 mV resolution (default)
CONFIG["PGA_1024"]           = 0x0600 -- Gain 4:   +/- 1.024 volts: 0.03125 mV resolution
CONFIG["PGA_512"]            = 0x0800 -- Gain 8:   +/- 0.512 volts: 0.015625 mV resolution
CONFIG["PGA_256"]            = 0x0A00 -- Gain 16:  +/- 0.256 volts: 0.007813 mV resolution

-- Configuration (Bits 12-14)
CONFIG["MUX_DIFF_01"]        = 0x0000 -- Difference between A0 (+) and A1 (-) (default)
CONFIG["MUX_DIFF_03"]        = 0x1000 -- Difference between A0 (+) and A3 (-)
CONFIG["MUX_DIFF_13"]        = 0x2000 -- Difference between A1 (+) and A3 (-)
CONFIG["MUX_DIFF_23"]        = 0x3000 -- Difference between A2 (+) and A3 (-)
CONFIG["MUX_SINGLE_0"]       = 0x4000 -- Difference between A0 (+) and Ground
CONFIG["MUX_SINGLE_1"]       = 0x5000 -- Difference between A1 (+) and Ground
CONFIG["MUX_SINGLE_2"]       = 0x6000 -- Difference between A2 (+) and Ground
CONFIG["MUX_SINGLE_3"]       = 0x7000 -- Difference between A3 (+) and Ground

-- Bit 15
CONFIG["OS_NULL"]            = 0x0000 -- Unused, no effect
CONFIG["OS_CONVERT"]         = 0x8000 -- Begin a single conversion when in power down mode (default)



-- Initializes the sensor
function M.init(sda, scl)

    i2c.setup(0, sda, scl, i2c.SLOW)

    -- Set up the defaults
    comp = CONFIG["COMP_DISABLE"] -- Disable the comparator
    rate = CONFIG["RATE_128"] -- 128 samples per second
    pga = CONFIG["PGA_6144"] -- +/- 6.144 volts of range
    delay = 8 -- 8ms delay, enough for 128 samples per second


    -- Find the i2c address being used by the sensor
    -- We cycle through a table of possible addresses, checking each one
    for _,addr in ipairs(i2c_addresses) do 

        -- Try to set the address
        local set = M.setAddress(addr)

        -- If address setting worked, stop trying
        if set == true then break

    end

    -- 
    if address == nil then
        print("Error: no ADS1115 found at any of the possible i2c addresses")
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
            print("ADS1115 found at address: 0x" .. string.format("%02X", addr))

            -- Set the address to use to addr
            address = addr
            
            -- Address setting successful
            return true

        else

            -- Device not found
            print("No ADS1115 found at address: 0x" .. string.format("%02X", addr))
            return false

        end

    else
        -- Throw error, not a valid address
        print("The address: 0x" .. string.format("%02X", addr) .. " is not valid for ADS1115")

        -- Address failed
        return false
    end

end


-- Function to set the PGA value
-- This sets the gain on the ADS1115, which changes the sensitivity 
-- and the range of voltages that can be measured
function M.setPGA(range)

    if range == 6.144 then

        -- Set PGA to measure +/- 6.144 Volts
        pga = CONFIG["PGA_6144"]
        
    elseif range == 4.096 then

        -- Set PGA to measure +/- 4.096 Volts
        pga = CONFIG["PGA_4096"]
        
    elseif range == 2.048 then

        -- Set PGA to measure +/- 2.048 Volts
        pga = CONFIG["PGA_2048"]
        
    elseif range == 1.024 then

        -- Set PGA to measure +/- 1.024 Volts
        pga = CONFIG["PGA_1024"]
        
    elseif range == 0.512 then

        -- Set PGA to measure +/- 0.512 Volts
        pga = CONFIG["PGA_512"]
        
    elseif range == 0.256 then

        -- Set PGA to measure +/- 0.256 Volts
        pga = CONFIG["PGA_256"]
        
    else
    
        -- Throw error and explain
        print("Voltage range could not be set. " .. range .. " is an invalid value")
        print("Acceptable values: 6.144, 4.096, 2.048, 1.024, 0.512, 0.256")

        return false
    end

    return true
end



function M.setRate(setrate)

    if setrate == 8 then

        -- 
        rate = CONFIG["RATE_8"]
        
    elseif setrate == 16 then

        -- 
        rate = CONFIG["RATE_16"]
        
    elseif setrate == 32 then

        rate = CONFIG["RATE_64"]
        
    elseif setrate == 64 then

        -- 
        rate = CONFIG["RATE_128"]
        
    elseif setrate == 128 then

        -- 
        rate = CONFIG["RATE_250"]
        
    elseif setrate == 250 then

        -- 
        rate = CONFIG["RATE_475"]

     elseif setrate == 475 then

        -- 
        rate = CONFIG["PGA_256"]


    elseif setrate == 860 then

        -- 
        rate = CONFIG["RATE_860"]
        
    else
    
        -- Throw error and explain
        print("Sampling rate could not be set. " .. setrate .. " is an invalid value")
        print("Acceptable values (per second): 8, 16, 32, 64, 128, 250, 475, 860")

        return false
    end

    -- set the delay to wait before reading the conversion register
    delay = math.ceil(1000/rate)

end



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

    -- OR the two bytes to concatenate them together
    local value = bit.bor(MSB, LSB)

    -- Return the value
    return val
    
end


function M.readADC(channel)

    local mux = 0

    if channel == 0 then
        mux = CONFIG["MUX_SINGLE_0"]
    elseif channel == 1 then
        mux = CONFIG["MUX_SINGLE_1"]
    elseif channel == 2 then
        mux = CONFIG["MUX_SINGLE_2"]
    elseif channel == 3 then
        mux = CONFIG["MUX_SINGLE_3"]
    elseif channel == 10 then
        mux = CONFIG["MUX_DIFF_01"]
    elseif channel == 30 then
        mux = CONFIG["MUX_DIFF_03"]
    elseif channel == 31 then
        mux = CONFIG["MUX_DIFF_13"]
    elseif channel == 32 then
        mux = CONFIG["MUX_DIFF_23"]
    else

        -- Throw error

    end

    print("mux: "..mux)

    local config = 0
    config = bit.bor(comp, rate, CONFIG["MODE_SINGLE"], pga, mux, CONFIG["OS_CONVERT"])
    
    print("config: "..config)

    writeRegister(address, REG_CONFIG, config)

    tmr.delay(delay)

    local val = readRegister(address, REG_CONVERT)

    return val

end



return M