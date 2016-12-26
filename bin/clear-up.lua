local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Clears a volume at and above Rob.",
    long_help = "Rob stays at the final position on sucess or returns to the starting position on failure.",
    usage = "width [length [height]]",
    required_values = 1,
    run = function(options, args)
      local rc = require("rob/clear")
      local rob = require("rob")

      local width = tonumber(args[1])
      local length = tonumber(args[2] or width)
      local height = tonumber(args[3] or width)

      local good, err = pcall(rc.volumeUp, width, length, height)

      if good then
        print("Success!")
        return 0
      else
        print("Failed.")
        sneaky.print_error(err, debug.traceback())
        rob.rollback_all()
        return -1
      end
    end
})
