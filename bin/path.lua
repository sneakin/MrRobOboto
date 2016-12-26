local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Manages Rob's path history.",
    long_help = ("Commands"
                   .. "\n  reset     Erases the history"
                   .. "\n  rollback  Rob retraces the history"
                   .. "\n  print     Displays the history"),
    usage = "command",
    required_values = 1,
    arguments = {
      steps = Command.Argument.Integer({
          description = "The number of steps to rollback."
      })
    },
    aliases = {
      s = "steps"
    },
    run = function(options, args)
      local rob = require("rob")
      local cmd = args[1]

      if cmd == "reset" then
        rob.checkpoints:reset()
      elseif cmd == "rollback" then
        if options.steps and options.steps > 0 then
          rob.rollback(options.steps)
        else
          rob.rollback_all()
        end
      elseif cmd == "print" then
        for i, point in ipairs(rob.checkpoints.points) do
          print(i, point)
        end
      else
        error("Unknown command: " .. cmd)
      end
    end
})
