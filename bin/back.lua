local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    usage = "[N]",
    description = "Moves Rob back by N blocks.",
    run = function(options, args)
      local rob = require("rob")
      local n = tonumber(args[1] or 1)
      if rob.backBy(n) then
        print("Moved back " .. n .. " blocks.")
      end
    end
})
