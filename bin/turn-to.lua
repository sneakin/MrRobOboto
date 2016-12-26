local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    usage = "DIR",
    description = "Turns Rob to face DIR.",
    required_values = 1,
    run = function(options, args)
      local rob = require("rob")
      local sides = require("sides")

      local dir = args[1]

      if dir == nil then
        print("The direction must be:")
        for i, j in ipairs(sides) do
          print(i, j)
        end
        return -1
      else
        rob.face(dir)
        return 0
      end
    end
})
