local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Fills a volume WIDTHxLENGTHxDEPTH below Rob.",
    usage = "width [length [depth]]",
    required_values = 1,
    arguments = {
      item = {
        description = "Item to fill the volume with.",
        default = "cobblestone"
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

      robinv.selectFirst(item)

      local good, err = pcall(filler.fillDown, width, length, height,
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
        print(err)
        for k,v in pairs(err) do
          print(k, v)
        end
        if debug and debug.traceback() then
          print(debug.traceback())
        end
        return -1
      end
    end
})
