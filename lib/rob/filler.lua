local sides = require("sides")
local robot = require("robot")
local component = require("component")
local crobot = component.robot
local rob = require("rob")

local filler = {}

function filler.backToStart(width, length)
   if length%2 == 0 then
      robot.turnLeft()
   else
      robot.turnRight()
   end

   local good, y = rob.forwardBy(length-1)
   if not good then
      return false, 0, y
   end

   robot.turnRight()
   local good, x = rob.forwardBy(width-1)
   if not good then
      return false, x, y
   end

   return true, x+1, y+1
end

function filler.actThenMove(action, dir, ...)
   print("actThenMove", action, dir, ...)
   local r, why = action(dir, ...)
   if r then
      return crobot.move(dir)
   else
      print(r, why)
      return false
   end
end

function filler.areaInner(width, length, action, ...)
   local rx, ry = 1, 1
   
   for y = 1,length do
      ry = y
      print("Progress " .. ry .. "/" .. length)
      
      for x = 1,width-1 do
         if y%2 == 0 then
            rx = width - (x-1)
         else
            rx = x
         end
         
         local r, d = filler.actThenMove(action, sides.forward, rx, ry, width, length, ...)
         if not r then
            return false, rx, ry
         end
      end

      if y == length then break end

      if y%2 == 0 then
         robot.turnRight()
      else
         robot.turnLeft()
      end

      local r, d = filler.actThenMove(action, sides.forward, rx, ry+1, width, length, ...)
      if not r then
         return false, rx, ry
      end

      if y%2 == 0 then
         robot.turnRight()
      else
         robot.turnLeft()
      end
   end

   if (ry % 2 == 0) then
      rx = rx - 1
   else
      rx = rx + 1
   end

   return true, rx, ry
end

function filler.debugAction(...)
   print(...)
   return true
end

function filler.area(width, length, action)
   rob.busy()
   
   local good, x, y = filler.areaInner(width, length, action or filler.debugAction)
   if not good then
      print("Failed to traverse area", x, y)
   end
   
   if good then
      rob.cool()
   else
      rob.notcool()
   end

   local ret_good, rx, ry = filler.backToStart(x, y)
   if not ret_good then
      print("Failed to return to the start.", rx, ry)
   end

   return (good and ret_good), x - rx, y - ry
end

function filler.volumeUp(width, length, height, action)
   local rz = 0
   
   for z = 1, height do
      rz = z
      
      if not filler.area(width, length, action, rz, height) then
         rob.downBy(rz)
         return false
      end
      
      rob.turnAround()

      if rz < height then
         if not filler.actThenMove(action, sides.up, 1, 1, width, length, rz, height) then
            rob.downBy(rz)
            return false
         end
      end
   end

   return rob.downBy(rz - 1)
end

function filler.volumeDown(width, length, depth, action)
   local rz = 0
   
   for z = depth, 1, -1 do
      rz = z
      
      if not filler.area(width, length, action, rz, depth) then
         rob.upBy(rz)
         return false
      end
      
      rob.turnAround()

      if rz > 1 then
         if not filler.actThenMove(action, sides.down, 1, 1, width, length, rz, depth) then
            rob.upBy(rz)
            return false
         end
      end
   end

   return rob.upBy(depth - 1)
end

--------

return filler
