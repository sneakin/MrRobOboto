local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Walls in a volume WIDTHxLENGTHxHEIGHT at and above Rob.",
    usage = "width [length [height]]",
    required_values = 1,
    arguments = {
      item = {
        description = "Item to fill the walls with.",
        default = "cobblestone"
      }
    },
    aliases = {
      i = "item"
    },
    run = function(options, args)
      local rob = require("rob")
      local WallFiller = require("rob/fillers/wall_filler")

      local item = options.item
      local width = tonumber(args[1])
      local length = tonumber(args[2] or width)
      local height = tonumber(args[3] or 3)

      local good, err = pcall(WallFiller.fill, width, length, height, item)
      rob.rollback_all()

      if good then
        print("Success!")
        return 0
      else
        print("Failed.")
        if err then
          print(err)
          if type(err) == "table" then
            for k,v in pairs(err) do
              print(k, v)
            end
          end
        end
        if debug and debug.traceback() then
          print(debug.traceback())
        end
        return -1
      end
    end
})
