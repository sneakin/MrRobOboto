local sides = require("sides")
local robinv = require("rob/inventory")
local component = require("component")
local inv = component.inventory_controller

local args = {...}

for slot, stack in robinv.iter(sides.front) do
   if stack and robinv.takeFromSlot(slot) then
      print("Took " .. stack.size .. " " .. stack.name .. " from slot " .. slot)
   end
end
