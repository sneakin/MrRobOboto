local component = require("component")
local robinv = require("rob/inventory")
local sides = require("sides")

local args = {...}
local query = args[1]

if not query then
   print("Usage: inv-search query")
   os.exit()
end

for slot, stack in robinv.search(sides.front, query) do
   print(slot, stack.name, stack.size)
end
