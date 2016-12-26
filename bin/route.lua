local Command = require("sneaky/command")
local sneaky = require("sneaky/util")
local sides = require("sides")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Routes and moves Rob through a Site.",
    arguments = {
      from = {
        description = "Where Rob is right now.",
        default = "building-1:charger:b"
      },
      to = {
        description = "Where to move Rob.",
        default = "building-2:zone-1:entry"
      },
      dir = {
        description = "The direction Rob is facing.",
        parse_value = function(value)
          if value then
            return sides[value]
          end
        end
      }
    },
    run = function(options, args)
      local routes = sneaky.reload("./sites/test-site/routes")
      local path = require("rob/path")
      local rob = require("rob")
      local flipped_sides = require("rob/flipped_sides")

      local from = options.from
      local to = options.to
      local from_dir = options.dir

      local a = routes:route(from, to)
      if a then
        print("Moving to " .. to)
        rob.busy()
        
        local mark = rob.checkpoint()
        local p, facing = routes:to_path(a, from_dir)
        local good, err = pcall(path.follow, rob, p)
        if good then
          print("Made it?")
          print("Now facing " .. (facing or "???"))
          rob.cool()
          return 0
        else
          rob.rollback_to(mark)
          print("Error moving:")
          sneaky.print_error(err)
          rob.notcool()
          return -2
        end
      else
        print("No route " .. from .. " to " .. to .. ".")
        return -1
      end
    end
})
