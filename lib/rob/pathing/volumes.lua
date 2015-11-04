local sides = require("sides")
local rob = require("rob")
local areas = require("rob/pathing/areas")

local volumes = {}

function volumes.cubeUp(width, length, height, action)
   local rz = 0
   
   for z = 1, height do
      rz = z

      local good, retdata = areas.square(width, length, action, rz, height)
      local back_good, back_retdata = areas.backToStart(table.unpack(retdata))
      if not good or not back_good then
         if back_good then
            rob.downBy(rz)
         end
         
         return false
      end
      
      rob.turnAround()

      if rz < height then
         if not areas.actThenMove(action, sides.up, 1, 1, width, length, rz, height) then
            rob.downBy(rz)
            return false
         end
      end
   end

   return rob.downBy(rz - 1)
end

function volumes.cubeDown(width, length, depth, action)
   local rz = 0
   
   for z = depth, 1, -1 do
      rz = z

      local good, retdata = areas.square(width, length, action, rz, depth)
      local back_good, back_retdata = areas.backToStart(table.unpack(retdata))
      if not good or not back_good then
         if back_good then
            rob.upBy(rz)
            return false
         end
      end
      
      rob.turnAround()

      if rz > 1 then
         if not areas.actThenMove(action, sides.down, 1, 1, width, length, rz, depth) then
            rob.upBy(rz)
            return false
         end
      end
   end

   return rob.upBy(depth - 1)
end


return volumes
