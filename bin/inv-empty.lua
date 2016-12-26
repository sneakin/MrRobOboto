local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Emptys Rob's inventory into a chest.",
    arguments = {
      slot = {
        description = "Slot to empty or 'all'.",
        default = "all"
      }
    },
    aliases = {
      s = "slot"
    },
    run = function(options, args)
      local robinv = require("rob/inventory")
      local rob = require("rob")

      local slot = options.slot

      rob.busy()
      if slot == "all" then
        if robinv.emptyAll() then
          rob.cool()
        else
          rob.notcool()
        end
      else
        slot = tonumber(slot)
        if robinv.emptySlot(slot) then
          rob.cool()
        else
          rob.notcool()
        end
      end
    end
})
