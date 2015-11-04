local sides = require("sides")
local robinv = require("rob/inventory")

local args = {...}
local verbose = args[1]

for slot, stack in robinv.iter(sides.front) do
  if stack then
     print(slot, stack.name, stack.size)
  elseif verbose then
     print(slot)
  end
end
