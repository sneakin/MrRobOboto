local sides = require("sides")
local component = require("component")
local robot = component.robot
local number = require("sneaky/number")
local rob = require("rob")
local robinv = require("rob/inventory")
local areas = require("rob/pathing/areas")

local planter = {}

function action(points, dir, x, y, w, h, item, spacing_x, spacing_y)
   print("planter action",dir,x,y,w,h,item, spacing_x,spacing_y)
   robot.suck(sides.down)

   if robot.count() == 0 then
      robinv.selectFirst(item)
   end
   
   if x % spacing_x == 0 then
      if y % spacing_y == 0 then
         robot.place(sides.forward)
      end
   end
   
   return true
end

function planter.plant(item, width, length, spacing_x, spacing_y)
   local mark = rob.checkpoint()

   robinv.selectFirst(item)
   areas.move_to_end(rob.checkpoints, width, length)
   areas.square_back(width, length, false, action, item, spacing_x, spacing_y)

   rob.pop_to(mark)
end

return planter
