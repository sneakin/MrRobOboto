local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Prints the local network addresses.",
    run = function(options, args)
      local component = require("component")
      local i = 1

      for addr, comp in component.list() do
        if comp == "modem" then
          print(addr)
          i = i + 1
        end
      end
    end
})
