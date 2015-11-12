local number = require("sneaky/number")
local sides = require("sides")
local component = require("component")
local robot = component.robot
local rob = require("rob")
local robinv = require("rob/inventory")
local areas = require("rob/pathing/areas")
local volumes = require("rob/pathing/volumes")

local filler = {}

local default_blocks = {
   "stone", "dirt", "netherrack", "gravel", "sand", "grass"
}

function select_block(x, y, w, l, z, h)
   if robinv.count() <= 0 then
      assert(robinv.selectFirst(default_blocks), "no item")
   end

   return true
end

function fill_action_floor(points, dir, x, y, w, h, block_selector, ...)
   if not block_selector(x, y, w, h, ...) then
      return true
   end

   local real_dir = dir

   if dir == sides.back then
      real_dir = sides.forward
   elseif dir == sides.up then
      real_dir = sides.down
   elseif dir == sides.down then
      real_dir = sides.up
   else
      error("bad side") -- TODO reflection?
   end

   robot.place(real_dir)
   
   return true
end

function fill_action_3d(points, dir, x, y, w, l, z, h, block_selector)
   if not block_selector(x, y, w, l, z, h) then
      return true
   end

   local real_dir = dir

   if dir == sides.back then
      real_dir = sides.front
   elseif dir == sides.front then
      real_dir = sides.back
   elseif dir == sides.up then
      real_dir = sides.down
   elseif dir == sides.down then
      real_dir = sides.up
   else
      error("bad side " .. dir) -- TODO reflection?
   end
   
   robot.place(real_dir)
   
   return true
end

function return_func(points, x, y, width, length, turn_right)
   print("Floor return", x, y, width, length, turn_right)

   if turn_right then
      if number.odd(y) then
         points:
            turnRight():
            forward(length - y):
            turnRight():
            forward(x - 2):
            turn(2)
      else
         points:
            turnLeft():
            forward(y + 1):
            turnRight():
            forward(x):
            turn(2)
      end
   else
      if number.odd(y) then
         points:
            turnLeft():
            forward(length - y):
            turnRight():
            forward(x):
            turn(2)
      else
         points:
            turnRight():
            forward(length - y):
            turnRight():
            forward(x - 2):
            turn(2)
      end
   end
end

function filler.floor(width, length, block_selector, ...)
   block_selector = block_selector or select_block
   local mark = rob.checkpoint()

   block_selector(1, 1, width, length, ...)
   
   rob.forward()
   local area_mark = rob.checkpoint()
   areas.move_to_end(rob.checkpoints, width, length)
   areas.square_back_inner(rob.checkpoints, width, length, number.odd(length), fill_action_floor, return_func, area_mark, block_selector, ...)
   areas.moveThenAct(rob.checkpoints, fill_action_floor, sides.back, 1, length, width, length, block_selector, ...)
   rob.pop_to(mark)
end

function filler.fillUpConfined(width, length, height, block_selector)
   block_selector = block_selector or select_block
   local mark = rob.checkpoint()

   rob.forward()
   rob.turn(2)
   volumes.cubeBackUp(width, length, height, fill_action_3d, block_selector)
   rob.forward()
   rob.replace_from(mark, function(points)
                       points:down(height):turn(2)
   end)
end

function filler.fillUp(width, length, height, block_selector, ...)
   block_selector = block_selector or select_block
   local mark = rob.checkpoint()

   for z = 1,height do
      filler.floor(width, length, block_selector, z, height, ...)
      rob.up()
   end
end

function filler.fillDown(width, length, height, block_selector, ...)
   local mark = rob.checkpoint()
   
   for z = height,0,-1 do
      filler.floor(width, length, block_selector, z, height, ...)
      rob.down()
   end
end

return filler
