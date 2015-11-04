local crafter = require("rob/crafter")

local args = {...}
local number = 1
local item_name = nil

if args[2] then
   number = tonumber(args[1])
   item_name = args[2]
else
   item_name = args[1]
end

print(crafter.craft(number, item_name))
