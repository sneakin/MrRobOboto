local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Takes everything from the chest in front of Rob.",
    run = function(options, args)
      local sides = require("sides")
      local robinv = require("rob/inventory")
      local component = require("component")
      local inv = component.inventory_controller

      for slot, stack in robinv.iter(sides.front) do
        if stack and robinv.takeFromSlot(slot) then
          print("Took " .. stack.size .. " " .. stack.name .. " from slot " .. slot)
        end
      end
    end
})
