local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Prints a list of all the open ports.",
    run = function(options, args)
      local Net = require("net")
      local component = require("component")
      local modem = component.modem

      for i = 1, Net.MAX_PORT do
        if modem.isOpen(i) then
          print(i)
        end
      end
    end
})
