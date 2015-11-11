local sides = require("sides")
local robot = require("robot")
local component = require("component")
local crobot = component.robot
local rob = require("rob")
local areas = require("rob/pathing/areas")
local number = require("sneaky/number")
local inv = require("rob/inventory")

local lumberjack = {}

function clear_action(checkpoints, dir)
   if crobot.detect(dir) then
      local good, why = crobot.swing(dir)
      if not good then
         if not (why == "air") then
            print(why)
            return false
         end
      end

      for t = 1,4 do
         rob.turn()
         crobot.suck(sides.forward)
      end
   end

   crobot.suck(sides.forward)
   crobot.suck(sides.down)

   return true
end

function return_action(checkpoints, dir, x, y, w, h, sapling_slot, spacing)
   print("return_action",x,y,w,h,sapling_slot)
   crobot.suck(sides.down)

   if sapling_slot then
      -- todo need to pass sapling_slot updates along
      if robot.count(sapling_slot) == 0 then
         sapling_slot = inv.selectFirst("sapling")
      end

      if robot.count(sapling_slot) > 0 then
         crobot.select(sapling_slot)

         if x % spacing == 0 then
            if y % spacing == 0 then
               crobot.place(sides.forward)
            end
         end
      end
   end
   
   return true
end

function lumberjack.clear(width, length, spacing)
   spacing = spacing or 4
   print("Lumberjacking " .. width .. "x" .. length .. " " .. spacing)

   local mark = rob.checkpoint()

   inv.selectFirst("_axe")
   areas.square(width, length, clear_action)

   -- local good, retdata = planter.plant(width, length)
   print("Planting saplings")
   local sapling_slot = inv.selectFirst("sapling")
   --local planter_good, planter_retdata = planter.plant(width, length)

   areas.square_back(width, length, number.odd(length), return_action, sapling_slot, spacing)

   rob.pop_to(mark)
end


--------

return lumberjack
