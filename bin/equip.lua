local inv = require("rob/inventory")

local args = {...}
local item = args[1]

if not item then
   print("Usage: equip item-name")
   os.exit()
end

print(inv.equipFirst(item))
