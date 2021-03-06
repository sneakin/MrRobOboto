local number = require("sneaky/number")
local sides = require("sides")
local _, robot = pcall(require, "robot")
local component = require("component")
local _, crobot = pcall(function() return component.robot end)
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

function areas.return_back_func(points, x, y, width, length, turn_right)
   print(x, y, width, length, turn_right)
   if turn_right then
      if number.odd(y) then
         points:
            turnLeft():
            forward(y - 1):
            turnRight():
            forward(width - x + 1)
      else
         points:
            turnRight():
            forward(y - 1):
            turnRight():
            forward(width - x - 1)
      end
   else
      if number.odd(y) then
         points:
            turnRight():
            forward(y - 1):
            turnLeft():
            forward(x)
      else
         points:
            turnLeft():
            forward(y - 1):
            turnLeft():
            forward(x - 2)
      end
   end
end

function areas.square_back_inner(points, width, length, turn_right, action, return_func, mark, ...)
   local rx, ry = 1, 1
   local turn_cond = number.even
   if turn_right then turn_cond = number.odd end

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
         points:replaceFrom(mark, return_func, rx, ry, width, length, turn_right)
      end

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
   
   local ret = areas.
      square_back_inner(points, width, length, turn_right,
                        action or areas.debugAction,
                        areas.return_back_func,
                        points:getMark(),
                        ...)

   rob.cool()

   return ret
end

function areas.square_back(width, length, turn_right, action, ...)
   return areas.square_back_p(rob.checkpoints, width, length, turn_right, ...)
end


--------

return areas
