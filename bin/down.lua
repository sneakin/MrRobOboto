local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    usage = "[N]",
    description = "Moves Rob down N blocks.",
    long_help = "N can be a number or 'all'.",
    run = function(options, args)
      local rob = require("rob")

      if args[1] == "all" then
        print(rob.bottomOut())
      else
        print(rob.downBy(tonumber(args[1] or 1)))
      end
    end
})
