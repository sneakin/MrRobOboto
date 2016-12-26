local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Manages an area for tree farming.",
    long_help = "Rob will clear an area of trees, collect the drops, and plant trees nicely spaced in the area.",
    usage = "width [length]",
    required_values = 1,
    arguments = {
      spacing = Command.Argument.Integer({
          description = "Space between trees.",
          default = 4
      })
    },
    run = function(options, args)
      local jack = require("rob/lumberjack")

      local w = tonumber(args[1])
      local l = tonumber(args[2] or w)
      local spacing = options.spacing

      print(jack.clear(w, l, spacing))
      
      return 0
    end
})
