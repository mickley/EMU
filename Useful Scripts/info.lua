--[[ 

##### ESP8266 Information #####
This script prints out as much information as possible for the particular ESP8266 module

This includes chip and flash information, NodeMCU version information, 
filesystem information, and network information.  

Useful for identifying nodes, and their software, figuring out flash chip size, etc.


##### Version History #####
- 5/23/2016 JGM - Version 1.0:
        - Initial version
- 8/23/2016 JGM - Version 1.1:
        - Added some error-catching code to prevent crashes when not connected to wifi 


--]]

-- Define local variables
local majorVer, minorVer, devVer, chipid, flashid, flashsize, flashmode, flashspeed
local ssid, ip, netmask, gateway, mac, remaining, used, total

-- Get the data

-- Wifi SSID
ssid = wifi.sta.getconfig()

-- Wifi Connection info
ip, netmask, gateway = wifi.sta.getip()

-- MAC Address
mac = wifi.sta.getmac()

-- Chip info
majorVer, minorVer, devVer, chipid, flashid, flashsize, flashmode, flashspeed = node.info();

-- Filesystem info
remaining, used, total = file.fsinfo()

-- Print all the data out
print("NodeMCU ESP8266 Info:")
print(string.rep('-', 40))

-- Print out information on the ESP8266 Chip
print('NodeMCU          v'..majorVer.."."..minorVer.."."..devVer..'\n'..
    'Chip ID:         '..chipid..'\n'..
    'Flash ID:        '..flashid..'\n'..
    'Flash Size:      '..flashsize..' KB\n'..
    'Heap Remaining:  '..node.heap()..' bytes\n')

-- Print out information in the Wifi Connection
print("Connection Info:")
print(string.rep('-', 40))

-- Only print ssid if set up
if ssid == nil then
    print('Wifi not set up')
else
    print('SSID:            '..ssid)

    -- Only print wifi information if connected
    if ip == nil then
        print('Not connected to '..ssid)
    else
        print('IP Address:      '..ip..'\n'..
            'Netmask:         '..netmask..'\n'..
            'Gateway:         '..gateway)
    end
end

-- Print mac address
print('MAC Address:     '..mac)

-- Get a list of files
files = file.list()
numfiles = 0

-- Print out Filesystem info
print('\nFilesystem Info: ')
print(string.rep('-', 40))

-- Print the name and size of each file stored on the ESP8266
for name, size in pairs(files) do
    print(name..string.rep(' ', 25 - string.len(name))..' : '..size..' bytes')
    numfiles = numfiles + 1
end

-- Print Filesystem summary
print(string.rep('-', 40))
print('Total files(s)'..string.rep(' ', 11)..' : '..numfiles..'\n'..
    'Filesystem used'..string.rep(' ', 10)..' : '..used..' bytes \n'..
    'Filesystem remaining'..string.rep(' ', 5)..' : '..remaining..' bytes \n')

-- Garbage collect memory
collectgarbage("collect")
