local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Selects the numbered slot or the slot containing the named item.",
    usage = "slot_or_item",
    required_values = 1,
    run = function(options, args)
      local component = require("component")
      local robot = component.robot
      local inv = require("rob/inventory")

      local slot = tonumber(args[1])
      if not slot then
        slot = inv.findFirstInternal(args[1])
        if not slot then
          print("Not found")
          return -1
        end
      end

      robot.select(slot)
      return 0
    end
})
