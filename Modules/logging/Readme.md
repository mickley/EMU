
# Logging Module

This module allows Lua code to integrate logging.  This can be used instead of print() to debug code and display error messages.  

It's especially useful because it can log all errors, warnings, messages etc. to a file.  This allows for debugging nodes that aren't connected to a computer: they can write debug and error information to a file that can be retrieved and examined later.  

### Features
* Writes messages to a file or the serial terminal or both.
* Allows messages to have different levels: eg errors are more important than warnings or debug info.
* The level of messages that are logged can be adjusted, so that less important messages are ignored.


### Logging Module Functions

| Function                     | Reference                                        |
|------------------------------|--------------------------------------------------|
| [log.init()](#loginit)       | Initialize the logging module                    |
| [log.log()](#loglog)         | Log a message to serial terminal or file or both |



## log.init()
This sets up the preferences for logging.  Here we can optionally specify a file, and indicate whether logging should be to a file, the serial terminal or both.  

The logLevel setting allows us to specify which messages get logged.  This allows for adjusting pre-existing code: eg. one can log all messages including debug, and then later set logging to only log errors and warnings.  

#### Syntax
`log.init([file, logLevel, logPrint, logFile])`

#### Parameters
- (optional) `file` Filename to log to.  If not specified, defaults to `node.log`
- (optional) `logLevel` The level of messages to log.  See table below for the options.  Defaults to `4` (all messages).
- (optional) `logPrint` Logs to the serial terminal if `true`.  Defaults to `true`
- (optional) `logFile` Logs to the file specified if `true`. Defaults to `true`

| logLevel | Messages that are logged                                  |
|----------|-----------------------------------------------------------|
| 0        | Logging off, none logged                                  |
| 1        | Log only error messages                                   |
| 2        | Log errors and warnings                                   |
| 3        | Log errors, warnings, and normal messages                 |
| 4        | Log errors, warnings, normal messages, and debug messages |

#### Returns
`nil`


## log.log()

Logs a message with the specified log level.  If that log level is <= the logLevel setting, the message will be logged.  Otherwise it'll be ignored.

#### Syntax
`log.log(message, level)`

#### Parameters
- `message` The message to log
- `level` The logging level of the message.  See table below for options.

| logLevel | Message Type   |
|----------|----------------|
| 1        | Error          |
| 2        | Warning        |
| 3        | Normal Message |
| 4        | Debug Message  |

#### Returns
`true` if logging was successful, or `false` if there was not enough space or the level was invalid

#### Example
```Lua
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
```
