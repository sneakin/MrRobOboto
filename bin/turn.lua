local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    usage = "[N]",
    description = "Turns Rob N quarter turns.",
    run = function(options, args)
      local rob = require("rob")

      local times = tonumber(args[1]) or 1

      rob.turn(times)

      if rob.hasNavigation() then
        print(rob.navigation.getFacing())
      end

      return 0
    end
})
