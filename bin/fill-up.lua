local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Fills a volume WIDTHxLENGTHxHEIGHT at and above Rob.",
    usage = "width [length [height]]",
    required_values = 1,
    arguments = {
      item = {
        description = "Item to fill the volume with.",
        default = "cobblestone"
      },
      initial = {
        description = "Floor to begin filling.",
        default = 0
      }
    },
    aliases = {
      i = "item"
    },
    run = function(options, args)
      local filler = require("rob/filler")
      local rob = require("rob")
      local robinv = require("rob/inventory")

      local item = options.item
      local width = tonumber(args[1])
      local length = tonumber(args[2] or width)
      local height = tonumber(args[3] or width)
      local initial_floor = options.initial

      print("Filling " .. width .. "x" .. length .. "x" .. height .. " with " .. item)
      robinv.selectFirst(item)

      local good, err = pcall(filler.fillUp, width, length, height, initial_floor,
                              function(x, y, w, h, z, h)
                                if robinv.countInternalSlot() <= 0 then
                                  robinv.selectFirst(item)
                                end

                                return true
      end)
      rob.rollback_all()

      if good then
        print("Success!")
        return 0
      else
        print("Failed.")
        return -1
      end
    end
})
