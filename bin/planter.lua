local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Plants saplings in evenly spaced rows and columns.", -- todo hoe the ground (farm command?)
    usage = "width [length]",
    required_values = 2,
    arguments = {
      sx = Command.Argument.Integer({
          description = "Spacing between columns.",
          default = 3
      }),
      sy = Command.Argument.Integer({
          description = "Spacing between rows.",
          default = 3
      }),
      item = {
        description = "Item to plant.",
        default = "sapling"
      }
    },
    run = function(options, args)
      local rob = require("rob")
      local planter = require("rob/planter")

      local item = options.item
      local w = tonumber(args[2])
      local l = tonumber(args[3] or w)
      local sx = options.sx
      local sy = options.sy

      local good, err = pcall(planter.plant, item, w, l, sx, sy)

      rob.rollback_all()

      if good then
        print("Success!")
        return 0
      else
        print("Failed")
        return -1
      end
    end
})
