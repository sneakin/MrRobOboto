local sneaky = require("sneaky/util")
local Command = require("sneaky/command")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Loads a new site into global memory.",
    arguments = {
    },
    run = function(options, args)
      local Site = require("rob/site")
      assert(args[1], "no site given")
      Site.load_instance(args[1])
      print("Loaded site " .. Site.instance().name .. " from " .. args[1])
    end
})
