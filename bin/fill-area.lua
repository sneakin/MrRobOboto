local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Fills in an WIDTHxLENGTH area.",
    usage = "width [length]",
    required_values = 1,
    arguments = {
      item = {
        description = "Item to fill the area with.",
        default = "cobblestone"
      },
      pattern = {
        description = "Fill pattern to use."
      }
    },
    aliases = {
      i = "item",
      p = "pattern"
    },
    run = function(options, args)
      local number = require("sneaky/number")
      local filler = require("rob/filler")
      local rob = require("rob")
      local robinv = require("rob/inventory")

      local item = options.item
      local width = tonumber(args[1])
      local length = tonumber(args[2] or width)
      local pattern = options.pattern

      local pattern_func = function(x, y, w, h, z, h)
        if robinv.countInternalSlot() <= 0 then
          assert(robinv.selectFirst(item), "no item")
        end

        return true
      end

      if pattern == "checkers" then
        function select_block(x, y)
          if number.even(y) then
            if number.even(x) then
              return item
            else
              return args[5]
            end
          else
            if number.even(x) then
              return args[5]
            else
              return item
            end
          end
        end
        
        pattern_func = function(x, y, w, h, z, h)
          assert(robinv.selectFirst(select_block(x, y)), "no item")
          return true
        end
      end

      robinv.selectFirst(item)

      local good, err = pcall(filler.floor, width, length, pattern_func)
      rob.rollback_all()

      if good then
        print("Success!")
        return 0
      else
        print("Failed.")
        sneaky.print_error(err, debug.traceback())
        return -1
      end
    end
})
