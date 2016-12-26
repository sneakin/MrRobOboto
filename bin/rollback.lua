local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Rolls Rob back to his starting point.",
    arguments = {
      steps = Command.Argument.Integer({
          description = "The number of steps to rollback.",
      })
    },
    aliases = {
      s = "steps"
    },
    run = function(options, args)
      local rob = require("rob")

      if options.steps and options.steps > 0 then
        local num_points = tonumber(args[1])
        rob.checkpoints:rollback(num_points)
      else
        rob.checkpoints:rollback_all()
      end
    end
})
