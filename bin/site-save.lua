local sneaky = require("sneaky/util")
local Command = require("sneaky/command")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Copies the loaded site to a new directory.",
    arguments = {
    },
    run = function(options, args)
      local Site = require("rob/site")
      assert(args[1], "no directory given")
      Site.instance():save(args[1])
    end
})
