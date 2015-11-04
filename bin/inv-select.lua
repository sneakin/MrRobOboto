local component = require("component")
local robot = component.robot
local inv = require("rob/inventory")

local args = {...}
local slot = tonumber(args[1])
if not slot then
   slot = inv.findFirstInternal(args[1])
   if not slot then
      print("Not found")
   end
end

robot.select(slot)
