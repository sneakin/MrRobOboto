local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Takes the named item from the chest in front of Rob.",
    usage = "item",
    required_values = 1,
    arguments = {
      number = Command.Argument.Integer({
          description = "Number to take.",
          default = 1
      })
    },
    aliases = {
      n = "number"
    },
    run = function(options, args)
      local sides = require("sides")
      local robinv = require("rob/inventory")
      local component = require("component")
      local inv = component.inventory_controller

      local number = options.number
      local item_name = args[1]

      robinv.take(number, item_name)
    end
})
