local number = require("sneaky/number")
local sides = require("sides")
local robot = require("robot")
local component = require("component")
local crobot = component.robot
local rob = require("rob")
local number = require("sneaky/number")
local checkpoints = require("rob/checkpoints")

local areas = {}

function areas.move_to_end(points, width, length)
   if number.odd(length) then
      points:forward(width - 1)
   end

   points:turnLeft()
   points:forward(length - 1)

   if number.odd(length) then
      points:turnRight()
   else
      points:turnLeft()
   end
end

function areas.actThenMove(points, action, dir, ...)
   -- print("actThenMove", action, dir, ...)

   if action then
      action(points, dir, ...)
   end
   
   points:move(dir)
end

function areas.moveThenAct(points, action, dir, ...)
   -- print("moveThenAct", action, dir, ...)
   points:move(dir)

   if action then
      action(points, dir, ...)
   end
end

function areas.return_func(points, width, length)
   if number.even(length) then
      points:
         turnLeft():
         forward(length - 1):
         turnLeft()
   else
      points:
         turnRight():
         forward(length - 1):
         turnRight():
         forward(width - 1):
         turn(2)
   end
end

function areas.squareInner(points, width, length, action, ...)
   local rx, ry = 1, 1

   local mark = points:getMark()
   
   for y = 1,length do
      ry = y
      print("Plane progress " .. ry .. "/" .. length)
      
      for x = 1,width-1 do
         if number.even(y) then
            rx = width - (x-1)
         else
            rx = x
         end
         
         areas.actThenMove(points, action, sides.forward, rx, ry, width, length, ...)
      end

      points:replaceFrom(mark, areas.return_func, width, y)

      if y == length then break end

      if number.even(y) then
         points:turnRight()
      else
         points:turnLeft()
      end

      if number.even(ry) then
         rx = rx - 1
      else
         rx = rx + 1
      end

      areas.actThenMove(points, action, sides.forward, rx, ry, width, length, ...)

      if number.even(y) then
         points:turnRight()
      else
         points:turnLeft()
      end
   end

   return true, {rx, ry, sides.forward}
end

function areas.debugAction(...)
   print(...)
   return true
end

function areas.square_p(points, width, length, action, ...)
   rob.busy()
   local ret = areas.squareInner(points, width, length, action or areas.debugAction, ...)
   rob.cool()
   return ret
end

function areas.square(width, length, action, ...)
   return areas.square_p(rob.checkpoints, width, length, action, ...)
end

function areas.return_back_func(points, width, length, turn_right)
   local turn_cond = number.even
   if turn_right then turn_cond = number.odd end

   if turn_cond(length) then
      if turn_right then
         points:
            turnLeft():
            forward(length - 1):
            turnRight():
            forward(width - 1)
      else
         points:
            turnLeft():
            forward(length - 1):
            turnLeft()
      end
   else
      if turn_right then
         points:
            turnRight():
            forward(length - 1):
            turnRight()
      else
         points:
            turnRight():
            forward(length - 1):
            turnLeft():
            forward(width - 1)
      end
   end
end

function areas.square_back_inner(points, width, length, turn_right, action, ...)
   local rx, ry = 1, 1
   local turn_cond = number.even
   if turn_right then turn_cond = number.odd end

   local mark = points:getMark()
   
   for y = 1,length do
      ry = y
      print("Plane progress " .. ry .. "/" .. length)
      
      for x = 1,width-1 do
         if turn_cond(y) then
            rx = width - (x-1)
            --rx = width - x
         else
            rx = x
         end
         
         areas.moveThenAct(points, action, sides.back, rx, ry, width, length, ...)
      end

      points:replaceFrom(mark, areas.return_back_func, width, y, turn_right)

      if y == length then break end

      if turn_cond(y) then
         points:turnLeft()
      else
         points:turnRight()
      end

      if turn_cond(ry) then
         rx = rx - 1
      else
         rx = rx + 1
      end

      areas.moveThenAct(points, action, sides.back, rx, ry, width, length, ...)

      if turn_cond(y) then
         points:turnLeft()
      else
         points:turnRight()
      end
   end

   return true, {rx, ry, sides.back}
end

function areas.square_back_p(points, width, length, turn_right, action, ...)
   rob.busy()
   
   local ret = areas.square_back_inner(points, width, length, turn_right, action or areas.debugAction, ...)

   rob.cool()

   return ret
end

function areas.square_back(width, length, turn_right, action, ...)
   return areas.square_back_p(rob.checkpoints, width, length, turn_right, action, ...)
end


--------

return areas
