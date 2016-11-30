--[[  Basic ESP8266 Lua Tutorial

This teaches some basic programming that nearly all languages use: 
   print, variables, control statements, functions, and loops

It also covers some things specific to lua like tables.  

Finally, it covers a bit of NodeMCU/ESP8266 specific stuff: wifi, gpio pins, sensors

]]--

-- This is a comment.  It has -- at the beginning and anything in it won't get run.  
-- Multi-line comments start with --[[ and end with ]]--
-- As you can see below, comments are very useful to tell others (or yourself) what you're doing 



-- ##### Printing #####
-- We use print to tell us what's going on (debugging) or what a variable is
print("Hi everybody!")

-- ##### Variables #####
-- Variables let us store things: numbers, text, data etc.

-- Numbers
tim = 31
print(tim)
print(tim * 2)

-- Text (called strings)
message = "Hi everybody!"
print(message)
print(message.." What's up?")



-- ##### Control Statements (eg if...then) #####
-- Control statements let us do different things depending on conditions we can test

-- Check how old tim is
if tim < 50 then
    print("Tim is not old")
end

-- You can have more than one choice
if tim < 25 then
    print("Tim is young")
elseif tim > 40 then
    print("Tim is aging")
else
    print("Tim is not old")
end

-- Try setting tim to different values and re-running the if...then code.  What happens?
tim = 20
tim = 45



-- ##### Functions #####
-- Functions let us re-use bits of code, so you don't have to repeat yourself or remember
-- how to do something
-- Functions can take arguments inside the () and do things with them

-- Take a number, add 5 to it, and print it out
-- This code needs to be run first to work, even though it won't do anything
function addfive(number)
    print(number + 5)
end

--Let's test the function we made
addfive(3)
addfive(8)

-- Functions are more useful when they give something back (return) instead of just printing
function addfive(number)
    return number + 5
end

-- Let's test again
addfive(8)
print(addfive(8))
new = addfive(8)
print(new + 2)



-- ##### Lua tables (arrays) #####
-- Lua tables let us store multiple things/variables in one place
-- We can give them a name, or just refer to them by their number/place

-- Make a table
tim = {}

-- Store tim's age in the table's age field
tim["age"] = 30

-- Tables can store both text and numbers (and functions and other tables at the same time
tim["birthday"] = "Sept. 3rd."

-- Here we store a table inside of a table.  This table doesn't have named fields
tim["numbers"] = {10, 20, 30, 40, 50}

-- Now let's look at the table
print(tim)
print(tim["age"])

-- You can refer to table fields with the . instead.  tim.age is the same as tim["age"]
print(tim.age)
print(tim.birthday)
print(tim.numbers)
print(tim.numbers[2])



-- ##### For loops #####
-- We didn't cover this, but for loops let us do repetitive things

for i=1,10 do
    print(i * 10)
end



-- ##### NodeMCU Wifi #####
-- A few wifi commands using the NodeMCU wifi module

-- Set up our ESP8266 to be a wifi station and connect TO a router
-- It could also be an access point and work like a router with things connecting to it
wifi.setmode(wifi.STATION)

-- Now we're a wifi station, so tell the ESP8266 which network and password to connect to
wifi.sta.config("elbrus", "plasticity")

-- Connect to the network
wifi.sta.connect()

-- Get our IP address to see if we're connected.  Might take 5-10 seconds
print(wifi.sta.getip())



-- ##### NodeMCU GPIO #####
-- The ESP8266 has a bunch of pins that you can use as input or output
-- This lets us read from sensors and also do things
-- Pin #4 has an LED connected to it, so we can test with that

-- Set the gpio pin as an output so it can send electricity to the LED
gpio.mode(4, gpio.OUTPUT)

-- Make pin 4 low (ground, 0V).  This turns the LED on, since it's already connected to 3.3V
gpio.write(4, gpio.LOW)

-- Make pin 4 high (+3.3V).  This turns the LED off
gpio.write(4, gpio.HIGH)



-- ##### NodeMCU Sensors #####
-- A lot of sensors use something called I2C to talk to the ESP8266
-- I2C has 4 wires: 3.3V, Ground, and two communication wires SDA and SCL
-- For most sensors, we'll have to tell them which pins will be SDA and SCL

-- An example with the BME280 humidity, temperature and pressure sensor:
-- Use pin 2 for SDA and pin 1 for SCL.  This starts up the sensor
bme280.init(2, 1)

-- Get the temperature and print it
temp = bme280.temp()
print(temp)



-- ##### An example program #####
-- You could save this part to a file (eg blink.lua) and put it on your ESP8266

-- A function to toggle the LED on and off
-- This has to come first so later commands can use it
function toggleLED ()

    -- Check whether the gpio pin is low or high
    if value == gpio.LOW then

        -- If it's low, set it to high
        value = gpio.HIGH
    else
    
        -- If it's high, set it to low
        value = gpio.LOW
    end

    -- Now that we've switched high > low, or low > high, make the gpio pin change
    gpio.write(pin, value)
end

-- ## Setup ##

-- Set the GPIO Pin we'll use to 4 (this is the one with the LED)
pin = 4

-- Set the value of the pin to start as low (ground)
value = gpio.LOW

-- Toggle the LED every 1000 milliseconds (1 second)
duration = 1000

-- Set the gpio pin as an output so it can send electricity to the LED
gpio.mode(pin, gpio.OUTPUT)

-- ## Run our program ##

-- Set a timer.  This timer will keep running toggleLED every second until it's turned off
-- toggleLED is a "callback function" here.  That means each time the timer is done running, 
-- it will run toggleLED()
tmr.create():alarm(duration, tmr.ALARM_AUTO, toggleLED)
