local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Equips the named item.",
    usage = "item",
    required_values = 1,
    run = function(options, args)
      local inv = require("rob/inventory")
      local item = args[1]
      print(inv.equipFirst(item))
    end
})
