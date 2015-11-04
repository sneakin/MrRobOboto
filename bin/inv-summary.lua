local table = require("table")
local sides = require("sides")
local sneaky = require("sneaky-util")
local component = require("component")
local inv = component.inventory_controller
local robinv = require("rob/inventory")

local sorter = sneaky.pairsByValues

local args = {...}
if args[1] == "-n" then
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
