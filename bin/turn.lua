local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    usage = "[N]",
    description = "Turns Rob N quarter turns.",
    run = function(options, args)
      local rob = require("rob")
      local sides = require("rob/sides")
      
      local times = tonumber(args[1]) or 1

      rob.turn(times)
      print(sides.tostring(rob.facing()))

      return 0
    end
})
