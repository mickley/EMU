-- Load the module
log = require("logging")

-- Log all messages to test.log and the serial terminal
log.init("test.log", 4, true, true)

-- Log a normal message
log.log("Logging was successful!", 3)

-- Log an error message
if 0 ~= 1 then
    log.log("Zero does not equal one!", 1)
end

-- Release the module to free up memory
log = nil
package.loaded.log = nil