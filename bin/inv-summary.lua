local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Prints a summary of the inventory in front of Rob.",
    arguments = {
      by_number = {
        description = "Sort by the number of items.",
        boolean = true
      }
    },
    aliases = {
      n = "by_number"
    },
    run = function(options, args)
      local table = require("table")
      local sides = require("sides")
      local component = require("component")
      local inv = component.inventory_controller
      local robinv = require("rob/inventory")

      local sorter = sneaky.pairsByValues

      if options.by_number then
        sorter = sneaky.pairsByKeys
      end

      local summary = {}

      for slot, stack in robinv.iter(sides.front) do
        if stack then
          summary[stack.name] = (summary[stack.name] or 0) + stack.size
        end
      end

      local total = 0
      for item, count in sorter(summary) do
        -- local item, count = table.unpack(info)
        print(item, count)
        total = total + count
      end

      print("---")
      print("Total", total)

      return 0
    end
})
