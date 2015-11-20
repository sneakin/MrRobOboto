local number = require("sneaky/number")
local sides = require("sides")
local rob = require("rob")
local areas = require("rob/pathing/areas")

local volumes = {}

function volumes.cubeUp(...)
   return volumes.cubeUpInner(areas.square_p, areas.return_func, rob.checkpoints, ...)
end

function volumes.cubeBackUp(...)
   return volumes.cubeUpInner(function(points, w, l, a, z, h, ...)
         areas.square_back_p(points, w, l, number.odd(l), a, z, h, ...)
                              end,
      areas.return_back_func,
      rob.checkpoints, ...)
end

function volumes.cubeUpInner(squarer, return_func, points, width, length, height, action, ...)
   local rz = 0
   local mark = points:getMark()

   for z = 1, height do
      print("Volume progress: " .. z .. "/" .. height)
      rz = z

      local z_mark = points:getMark()
      squarer(points, width, length, action, rz, height, ...)
      points:pop_to(z_mark)
      
      return_func(points, width, length, number.odd(length))

      if rz < height then
         areas.actThenMove(points, action, sides.up, 1, 1, width, length, rz, height, ...)
      end

      points:replaceFrom(mark, function(points)
                            points:down(z - 1)
      end)
   end
   
   return mark
end

function volumes.cubeDown(...)
   return volumes.cubeDownInner(areas.square_p, areas.return_func, rob.checkpoints, ...)
end

function volumes.cubeBackDown(...)
   local f = function(points, width, length, action, rz, depth, ...)
      areas.square_back_p(points, width, length, number.odd(length), action, rz, depth, ...)
   end
   return volumes.cubeDownInner(f, areas.return_back_func, rob.checkpoints, ...)
end

function volumes.cubeDownInner(squarer, return_func, points, width, length, depth, action, ...)
   local rz = 0
   local mark = points:getMark()
   
   for z = depth, 1, -1 do
      print("Volume progress: " .. z .. "/" .. depth)
      rz = z
      local z_mark = points:getMark()

      squarer(points, width, length, action, rz, depth, ...)
      points:pop_to(z_mark)

      return_func(points, width, length, number.odd(length))

      if rz > 1 then
         areas.actThenMove(points, action, sides.down, 1, 1, width, length, rz, depth, ...)
      end

      points:replaceFrom(mark, function(points)
                            points:up(z - 1)
      end)
   end

   return mark
end


return volumes
