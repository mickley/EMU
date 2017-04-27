gpio_pin= {5,4,0,2,14,12,13,15,3,1,9,10} 

function find_dev(addr)
     i2c.start(0)
     test = i2c.address(0, addr ,i2c.TRANSMITTER)
     i2c.stop(0)
     return test
end

print("\n\n" .. "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n" ..
"Scanning all pins for I2C devices")

for scl = 1, 7 do
     for sda = 1, 7 do
          tmr.wdclr()
          if sda ~= scl then
               i2c.setup(0, sda, scl, i2c.SLOW)
               for addr = 0, 127 do
                    if find_dev(addr)==true then
                    print("Device found at address 0x" ..
                         string.format("%02X", addr) .. 
                         " (Dec: " .. addr .. ")")
                         
                    print("  Device is wired: SDA to GPIO" .. 
                         gpio_pin[sda] .. " - Pin #" .. sda)
                    print("  Device is wired: SCL to GPIO"..
                         gpio_pin[scl] .. " - Pin #" .. scl)
                    end
               end
          end
     end
end 

print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
