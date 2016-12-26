local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Crafts the named item using internal inventory.",
    usage = "item",
    required_values = 1,
    arguments = {
      count = Command.Argument.Integer({
          description = "Number of items to craft.",
          default = 1
      })
    },
    aliases = {
      c = "count"
    },
    run = function(options, args)
      local crafter = require("rob/crafter")
      for k,v in pairs(options) do
        print(k,v)
      end
      for n, v in ipairs(args) do
        print(n, v)
      end
      local number = options.count
      local item_name = args[1]

      print(crafter.craft(number, item_name))
    end
})
