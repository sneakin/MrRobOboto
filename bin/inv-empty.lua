local robinv = require("rob/inventory")
local rob = require("rob")

local args = {...}
local slot = tonumber(args[1])

rob.busy()
if slot then
   if robinv.emptySlot(slot) then
      rob.cool()
   else
      rob.notcool()
   end
else
   if robinv.emptyAll() then
      rob.cool()
   else
      rob.notcool()
   end
end
