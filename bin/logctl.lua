local Command = require("sneaky/command")
local sneaky = require("sneaky/util")
local Logger = require("sneaky/logger")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Controls and manages the logger.",
    arguments = {
      stderr = {
        boolean = true
      },
      nostderr = {
        boolean = true
      },
      level = {
        parse_value = function(v) return Logger.Level[v] end,
        validator = function(v) return v == nil or Logger.Level[v] ~= nil end
      }
    },
    run = function(options, args)
      if options.stderr then
        Logger.default()
        print("Logging to stderr")
      elseif options.nostderr then
        Logger.stop_default()
        print("Not logging to stderr")
      end

      if options.level then
        Logger.level = options.level
      end
      
      print("Log level", Logger.Level[Logger.level])
    end
})
