local Command = require("sneaky/command")
local sneaky = require("sneaky/util")
local sides = require("sides")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Swings Rob's selected tool.",
    arguments = {
      dir = {
        description = "The direction Rob will swing.",
        parse_value = function(value)
          if value then
            return sides[value]
          end
        end,
        default = "front"
      },
      times = Command.Argument.Integer({
          description = "Number of times to swing.",
          default = 1
      })
    },
    run = function(options, args)
      local rob = require("rob")
      for n = 1, options.times do
        rob.swing(options.dir)
      end
      return 0
    end
})
