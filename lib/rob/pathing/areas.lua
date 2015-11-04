local sides = require("sides")
local robot = require("robot")
local component = require("component")
local crobot = component.robot
local rob = require("rob")
local number = require("sneaky/number")

local areas = {}

function areas.backToStart(width, length, dir, turn_right)
   if not dir then dir = sides.forward end
   local turn_cond = number.even
   if turn_right then turn_cond = number.odd end
   
   if turn_cond(length) then
      robot.turnLeft()
   else
      robot.turnRight()
   end

   local good, y = rob.moveBy(dir, length-1)
   if not good then
      return false, {0, y}
   end

   robot.turnRight()
   
   local good, x = rob.moveBy(dir, width-1)
   if not good then
      return false, {x, y}
   end

   return true, {x+1, y+1}
end

function areas.actThenMove(action, dir, ...)
   print("actThenMove", action, dir, ...)
   local r, why

   if action then
      r, why = action(dir, ...)

      if not r then
         print(r, why)
         return false
      end
   end
   
   return crobot.move(dir)
end

function areas.moveThenAct(action, dir, ...)
   print("moveThenAct", action, dir, ...)
   local r, why = crobot.move(dir)
   if r then
      if action then
         return action(dir, ...)
      else
         return true
      end
   else
      print(r, why)
      return false
   end
end

function areas.squareInner(width, length, action, ...)
   local rx, ry = 1, 1
   
   for y = 1,length do
      ry = y
      print("Progress " .. ry .. "/" .. length)
      
      for x = 1,width-1 do
         if number.even(y) then
            rx = width - (x-1)
         else
            rx = x
         end
         
         local r, d = areas.actThenMove(action, sides.forward, rx, ry, width, length, ...)
         if not r then
            return false, {rx, ry, sides.forward}
         end
      end

      if y == length then break end

      if number.even(y) then
         robot.turnRight()
      else
         robot.turnLeft()
      end

      local r, d = areas.actThenMove(action, sides.forward, rx, ry+1, width, length, ...)
      if not r then
         return false, {rx, ry, sides.forward}
      end

      if number.even(y) then
         robot.turnRight()
      else
         robot.turnLeft()
      end
   end

   if number.even(ry) then
      rx = rx - 1
   else
      rx = rx + 1
   end

   return true, {rx, ry, sides.forward}
end

function areas.debugAction(...)
   print(...)
   return true
end

function areas.square(width, length, action, ...)
   rob.busy()
   
   local good, retdata = areas.squareInner(width, length, action or areas.debugAction, ...)
   if not good then
      print("Failed to traverse area", table.unpack(retdata))
   end

   -- todo switch to returing retdata and letting the caller decide how to get back
   if good then
      rob.cool()
   else
      rob.notcool()
   end

   return good, retdata

   --return (good and ret_good), { x - rx, y - ry }
end

function areas.squareBackInner(width, length, turn_right, action, ...)
   local rx, ry = 1, 1
   local turn_cond = number.even
   if turn_right then turn_cond = number.odd end
   
   for y = 1,length do
      ry = y
      print("Progress " .. ry .. "/" .. length)
      
      for x = 1,width-1 do
         if turn_cond(y) then
            rx = width - (x-1)
         else
            rx = x
         end
         
         local r, d = areas.moveThenAct(action, sides.back, rx, ry, width, length, ...)
         if not r then
            return false, {rx, ry, sides.back}
         end
      end

      if y == length then break end

      if turn_cond(y) then
         robot.turnLeft()
      else
         robot.turnRight()
      end

      local r, d = areas.actThenMove(action, sides.back, rx, ry+1, width, length, ...)
      if not r then
         return false, {rx, ry, sides.back}
      end

      if turn_cond(y) then
         robot.turnLeft()
      else
         robot.turnRight()
      end
   end

   if turn_cond(ry) then
      rx = rx - 1
   else
      rx = rx + 1
   end

   return true, {rx, ry, sides.back}
end

function areas.squareBack(width, length, turn_right, action, ...)
   rob.busy()
   
   local good, retdata = areas.squareBackInner(width, length, turn_right, action or areas.debugAction, ...)
   if not good then
      print("Failed to traverse area", table.unpack(retdata))
   end
   
   if good then
      rob.cool()
   else
      rob.notcool()
   end

   return good, retdata
end


--------

return areas
