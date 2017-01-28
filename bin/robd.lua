local sneaky = require("sneaky/util")
local Command = require("sneaky/command")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "The Rob Oboto daemon. Run this on all robots.",
    arguments = {
      ox = Command.Argument.Integer(),
      oy = Command.Argument.Integer(),
      oz = Command.Argument.Integer(),
      facing = Command.Argument.Side(),
      stop = {
        boolean = true
      }
    },
    run = function(options, args)
      local vec3d = require("vec3d")
      local robd = require("rob/daemon")
      local rob = require("rob")
      
      if options.ox and options.oy and options.oz then
        local v = vec3d:new(tonumber(options.ox),
                            tonumber(options.oy),
                            tonumber(options.oz))
        if rob.hasNavigation() then
          v = v - rob.offset()
        end
        print("Setting origin to " .. tostring(v))
        rob.origin(v)
      end
      
      if options.facing then
        print("Facing " .. options.facing)
        rob.facing(options.facing)
      end
      
      if options.stop then
        robd.stop()
      else
        robd.start()
      end
    end
})
