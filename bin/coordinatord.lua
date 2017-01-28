local sneaky = require("sneaky/util")
local Command = require("sneaky/command")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "The Rob Oboto coordinator daemon.",
    arguments = {
      x = Command.Argument.Integer({}),
      y = Command.Argument.Integer({}),
      z = Command.Argument.Integer({}),
      stop = {
        boolean = true
      }
    },
    run = function(options, args)
      local cd = require("rob/coordinator")
      if options.stop then
        cd.stop()
      else
        assert(args[1], "no node given")
        
        if options.x then
          local site = require("rob/site")
          local vec3d = require("vec3d")
          site.instance():add_node(args[1], vec3d:new(options.x, options.y, options.z))
        end
        
        cd.start(args[1])
      end
    end
})
