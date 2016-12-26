local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Dumps the inventory in front of Rob.",
    arguments = {
      verbose = {
        boolean = true,
        description = "Print more output."
      }
    },
    run = function(options, args)
      local sides = require("sides")
      local robinv = require("rob/inventory")

      for slot, stack in robinv.iter(sides.front) do
        if stack then
          print(slot, stack.name, stack.size)
        elseif options.verbose then
          print(slot)
        end
      end
    end
})
