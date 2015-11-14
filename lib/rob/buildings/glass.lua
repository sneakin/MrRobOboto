local sneaky= require("sneaky/util")
local filler = require("rob/filler")
local inv = require("rob/inventory")
local rob = require("rob")
local sides = require("sides")

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

function ladder_wall(x, y, z, w, l, h)
   return ((x == 5 or x == 4) and y == (l - 1))
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

function quadrant_for(x, y, w, l)
   if x - (w / 2) < 0 then
      if y - (l / 2) < 0 then
         return 3
      else
         return 4
      end
   else
      if y - (l / 2) < 0 then
         return 2
      else
         return 1
      end
   end
end

function cable_for(x, y, w, l, blocks)
   local quads = { blocks.cable_q1, blocks.cable_q2, blocks.cable_q3, blocks.cable_q4 }
   return quads[quadrant_for(x, y, w, l)]
end


glass.default_blocks = {
   floor = "minecraft.*stone",
   ceiling  = "minecraft.*stone",
   roof = "minecraft.*stone",
   outer_wall = "minecraft.*stone",
   inner_wall = "minecraft.*stone",
   cable_q1 = "opencomputers:cable",
   cable_q2 = "cable.redstone",
   cable_q3 = "opencomputers:cable",
   cable_q4 = "cable.redstone",
   lamp_q1 = "colorfullamp",
   lamp_q2 = "illumination.lamp",
   lamp_q3 = "colorfullamp",
   lamp_q4 = "illumination.lamp",
   glass = "glass",
   ladder = "ladder"
}

glass.red_brick_blocks = {
   floor = "plank",
   ceiling = "wool",
   roof = "brick",
   outer_wall = "brick",
   inner_wall = "brick",
   cable_q1 = "opencomputers:cable",
   cable_q2 = "cable.redstone",
   cable_q3 = "opencomputers:cable",
   cable_q4 = "cable.redstone",
   lamp_q1 = "colorfullamp",
   lamp_q2 = "illumination.lamp",
   lamp_q3 = "colorfullamp",
   lamp_q4 = "illumination.lamp",
   glass ="glass",
   ladder = "ladder"
}

glass.stone_brick_blocks = {
   floor = "plank",
   ceiling = "wool",
   roof = "stonebrick",
   outer_wall = "stonebrick",
   inner_wall = "stonebrick",
   cable_q1 = "opencomputers:cable",
   cable_q2 = "cable.redstone",
   cable_q3 = "opencomputers:cable",
   cable_q4 = "cable.redstone",
   lamp_q1 = "colorfullamp",
   lamp_q2 = "illumination.lamp",
   lamp_q3 = "colorfullamp",
   lamp_q4 = "illumination.lamp",
   glass ="glass",
   ladder = "ladder"
}

function glass.selector(x, y, w, l, z, h, blocks, ...)
   print("selector", x, y, w, l, z, h, blocks, ...)
   if z == 1 or z == h then -- floor
      if x == 1 or x == w
         or y == 1 or y == l
      then
         inv.selectFirst(blocks.outer_wall)
      elseif cable_conduit(x, y, w, l) then
         inv.selectFirst(cable_for(x, y, w, l, blocks))
      elseif z == 1 then
         inv.selectFirst(blocks.floor)
      else
         inv.selectFirst(blocks.ceiling)
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
         inv.selectFirst(cable_for(x, y, w, l, blocks))
      elseif cable_conduit_wall(x, y, w, l)
      then
         if lamp_spot(x, y, z, w, l, h) then
            local lamps = { blocks.lamp_q1, blocks.lamp_q2, blocks.lamp_q3, blocks.lamp_q4 }
            local quad = quadrant_for(x, y, w, l)
            inv.selectFirst(lamps[quad] or blocks.inner_wall)
         else
            inv.selectFirst(blocks.inner_wall)
         end
      else
         return false
      end
   end

   return true
end

function roof_selector(x, y, w, l, blocks, ...)
   print("roof_selector", x, y, w, l, blocks, ...)
   if x == 1 or x == w or
      y == 1 or y == l
   then
      inv.selectFirst(blocks.outer_wall)
   elseif cable_conduit(x, y, w, l) then
      inv.selectFirst("lamp")
   else
      inv.selectFirst(blocks.roof)
   end

   return true
end

function glass.build_ladder(width, length, level_height, levels, blocks)
   rob.forward(5).turn().forward(1).turn()

   local mark = rob.checkpoint()
   
   for z = level_height * levels, 1, -1 do
      rob.swing(sides.down)
      rob.down()
      rob.swing(sides.front)

      inv.selectFirst(blocks.ladder)
      rob.place(sides.front)
   end

   for level = 1, levels do
      for z = 1, (level_height - 1) do
         rob.up()
      end

      inv.selectFirst(blocks.ceiling)
      rob.place(sides.down)

      rob.up()
      if level == levels then
         inv.selectFirst(blocks.roof)
      else
         inv.selectFirst(blocks.floor)
      end
      rob.place(sides.down)

      rob.replace_from(mark, function(points)
                          points:up((levels - level) * level_height)
      end)
   end
end

function glass.build(width, length, level_height, levels, blocks)
   assert(width > 7, "width must be >7")
   assert(length > 7, "length must be >7")
   assert(level_height > 3, "level_height must be >3")
   assert(levels > 0, "levels must be >0")
   
   blocks = sneaky.merge(glass.default_blocks, blocks)
   for level = 1, levels do
      filler.fillUp(width, length, level_height, glass.selector, blocks)
   end

   filler.floor(width, length, roof_selector, blocks)

   rob.up()
   glass.build_ladder(width, length, level_height, levels, blocks)
end

function glass.check_requirements(width, length, level_height, levels, blocks)
   local reqs = glass.requirements(width, length, level_height, levels, blocks)
   local needs = inv.needList(reqs)
   if not (needs == {}) then
      print("The following are required:")
      for item, number in pairs(needs) do
         print(number, item)
      end
      return false
   end

   return true
end

function glass.requirements(width, length, level_height, levels, block_types)
   local blocks = {}
   for kind, specific in pairs(glass.default_blocks) do
      blocks[kind] = 0
   end

   blocks.floor = (width - 1) * (length - 1) * levels - 5
   blocks.ceiling = (width - 1) * (length - 1) * levels - 5
   blocks.roof = width * length - 5
   blocks.outer_wall = 2 * width + 2 * length
   blocks.inner_wall = 3 * 4 * (level_height - 2) * levels
   blocks.cable_q1 = level_height * levels
   blocks.cable_q2 = level_height * levels
   blocks.cable_q3 = level_height * levels
   blocks.cable_q4 = level_height * levels
   blocks.lamp_q1 = 2 * levels + 1
   blocks.lamp_q2 = 2 * levels + 1
   blocks.lamp_q3 = 2 * levels + 1
   blocks.lamp_q4 = 2 * levels + 1
   blocks.glass = (width - 6) * (level_height - 2) * 2 + (length - 6) * (level_height - 2) * 2
   blocks.ladder = level_height * levels

   if block_types then
      local ret = {}
      for kind, specific in pairs(block_types) do
         ret[specific] = (ret[specific] or 0) + blocks[kind]
      end
      return ret
   else
      return blocks
   end
end

return glass
