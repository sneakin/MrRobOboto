local filler = require("rob/filler")
local inv = require("rob/inventory")

local glass = {}

function corner(x, y, w, l)
   return ((x == 1 or x == w) and (y == 1 or y == l))
end

function cable_conduit(x, y, w, l)
   return (x == 2 and y == 2) or
      (x == (w - 1) and y == 2) or
      (x == 2 and y == (l - 1)) or
      (x == (w - 1) and y == (l - 1))
end

function cable_conduit_wall(x, y, w, l)
   return (x <= 3 and y <= 3) or
      (x >= (w - 2) and y <= 3) or
      (x <= 3 and y >= (l - 2)) or
      (x >= (w - 2) and y >= (l - 2))
end

function lamp_spot(x, y, z, w, l, h)
   if z == (h - 1) and
      (y == 2 or y == 3 or y == (l - 1) or y == (l - 2)) and
      (x == 2 or x == 3 or x == (w - 1) or x == (w - 2))
   then
      -- exclude the corners
      if (x == 3 and y == 3) or
         (x == 3 and y == (l - 2)) or
         (x == (w - 2) and y == 3) or
         (x == (w - 2) and y == (l - 2))
      then
         return false
      else
         return true
      end
   else
      return false
   end
end

glass.default_blocks = {
   floor = "stone",
   ceiling  = "stone",
   outer_wall = "stone",
   inner_wall = "stone",
   cable = "opencomputers:cable",
   lamp = "lamp",
   glass = "glass"
}

glass.red_brick_blocks = {
   floor = "plank",
   ceiling = "wool",
   outer_wall = "brick",
   inner_wall = "brick",
   cable = "opencomputers:cable",
   lamp = "lamp",
   glass ="glass"
}

function selector(x, y, w, l, z, h, blocks, ...)
   print("selector", x, y, w, l, z, h, blocks, ...)
   if z == 1 or z == h then -- floor
      if x == 1 or x == w
         or y == 1 or y == l
      then
         inv.selectFirst(blocks.outer_wall)
      else
         if cable_conduit(x, y, w, l) then
            inv.selectFirst(blocks.cable)
         else
            if z == 1 then
               inv.selectFirst(blocks.floor)
            else
               inv.selectFirst(blocks.ceiling)
            end
         end
      end
   else
      -- walls
      if x == 1 or x == w
      or y == 1 or y == l
      then
         -- corners
         if corner(x, y, w, l)
            or cable_conduit_wall(x, y, w, l)
         then
            inv.selectFirst(blocks.outer_wall)
         else
            inv.selectFirst(blocks.glass)
         end
      elseif cable_conduit(x, y, w, l)
      then
         inv.selectFirst(blocks.cable)
      elseif cable_conduit_wall(x, y, w, l)
      then
         if lamp_spot(x, y, z, w, l, h) then
            inv.selectFirst(blocks.lamp)
         else
            inv.selectFirst(blocks.inner_wall)
         end
      else
         return false
      end
   end

   return true
end

function glass.build(width, length, level_height, levels, blocks)
   blocks = sneaky.merge(default_blocks, blocks)
   for level = 1, levels do
      filler.fillUp(width, length, level_height, selector, blocks)
   end
end

return glass
