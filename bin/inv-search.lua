local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Searches the inventory in front of Rob printing the slot counts.",
    usage = "item",
    required_values = 1,
    run = function(options, args)
      local component = require("component")
      local robinv = require("rob/inventory")
      local sides = require("sides")

      local query = args[1]

      for slot, stack in robinv.search(sides.front, query) do
        print(slot, stack.name, stack.size)
      end
    end
})
