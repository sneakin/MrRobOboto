local component = require("component")
local robinv = require("rob/inventory")
local sides = require("sides")

local args = {...}
local query = args[1]

if not query then
   print("Usage: inv-search-int query")
   os.exit()
end

for slot, stack in robinv.searchInternal(query) do
   print(slot, stack.name, stack.size)
end
