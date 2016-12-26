local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Places the selected block in front of Rob.",
    run = function(options, args)
      local sides = require("sides")
      local c = require("component")
      local r = c.robot

      print(r.place(sides.forward))
    end
})
