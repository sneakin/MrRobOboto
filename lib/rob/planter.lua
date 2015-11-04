local sides = require("sides")
local component = require("component")
local robot = component.robot
local number = require("sneaky/number")
local rob = require("rob")
local areas = require("rob/pathing/areas")

local planter = {}

function action(dir, x, y, w, h, spacing_x, spacing_y)
   print("planter action",dir,x,y,w,h,spacing_x,spacing_y)
   robot.suck(sides.down)

   if robot.count() > 0 then
      if x % spacing_x == 0 then
         if y % spacing_y == 0 then
            robot.place(sides.forward)
         end
      end
   else
      inv.selectFirst("sapling")
   end
   
   return true
end

function planter.plant(width, length, spacing_x, spacing_y)
   rob.turnAround()
   
   local good, retdata = areas.squareBack(width, length, number.odd(length), action, spacing_x, spacing_y)
   
   print("Planting was ", good, table.unpack(retdata))
   if good then
      return areas.backToStart(width, length, sides.back, number.even(length))
   else
      local x, y, dir = table.unpack(retdata)
      local good, retdata = areas.backToStart(1 + width - x, length - y, sides.back, number.even(length))
      return false, retdata[1], retdata[2]
   end
end

return planter
