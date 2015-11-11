local rob = require("rob")
local robinv = require("rob/inventory")
local MoveThenPlacer = require("rob/movers/move_then_placer")

local WallFiller = {}

function WallFiller.fill(width, length, height, item, item_selector)
   local mover = MoveThenPlacer:new(rob, rob.checkpoints, robinv, item)
   if item_selector then
      mover.select_item = item_selector
   end

   print("Filling walls of " .. width .. "x" .. length .. "x" .. height .. " with " .. item)
   mover:ready()
   
   local mark = mover:checkpoint()
   mover:
      forward():
      turn(2)

   for z = 1, height do
      mover:
         back(width - 1):
         turn():
         back(length - 1):
         turn():
         back(width - 1):
         turn():
         back(length - 2):
         up():
         off():
         back():
         on():
         turn():
         replace_from(mark, function(points)
                         points:forward():down(z - 1):turn(2)
         end)
   end
   
   mover:
      off():
      forward():
      turn(2):
      replace_from(mark, function(points)
                      points:down(height)
      end)
end

return WallFiller
