local sneaky = require("sneaky/util")
local number = require("sneaky/number")
local filler = require("rob/filler")
local inv = require("rob/inventory")
local rob = require("rob")
local sides = require("sides")
local styles = require("rob/buildings/styles")
local vec3d = require("vec3d")
local rotated_sides = require("rob/rotated_sides")

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

function roof_selector(x, y, w, l, blocks, ...)
   print("roof_selector", x, y, w, l, blocks, ...)
   if x == 1 or x == w or
      y == 1 or y == l
   then
      inv.selectFirst(blocks.outer_wall)
   elseif cable_conduit(x, y, w, l) then
      local lamps = { blocks.lamp_q1, blocks.lamp_q2, blocks.lamp_q3, blocks.lamp_q4 }
      local quad = quadrant_for(x, y, w, l)
      inv.selectFirst(lamps[quad] or blocks.roof)
   else
      inv.selectFirst(blocks.roof)
   end

   return true
end

function glass.build_roof(width, length, blocks)
   filler.floor(width, length, roof_selector, blocks)
end

function glass.build_door(length, level_height)
   local mark = rob.checkpoint()
   
   local width = 3
   if number.even(length) then
      width = 2
   end
   local height = math.max(2, level_height - 3)
   
   rob.turn()
   rob.forward(length / 2 - width / 2 - 1)

   for x = 1, width do
      rob.forward()

      local z_mark = rob.checkpoint()

      rob.turn(-1)
      rob.up() -- skip floor

      for z = 1, height do
         rob.swing(sides.forward)
         rob.up()
      end

      rob.rollback_to(z_mark)
   end

   rob.rollback_to(mark)
end

function glass.build(width, length, level_height, levels, blocks, initial_floor)
   assert(width > 7, "width must be >7")
   assert(length > 7, "length must be >7")
   assert(level_height > 3, "level_height must be >3")
   assert(levels > 0, "levels must be >0")

   initial_floor = initial_floor or 0
   blocks = sneaky.merge(styles.default, blocks)

   local mark = rob.checkpoint()
   local initial_level, layer = math.modf(initial_floor / level_height)
   
   for level = initial_level + 1, levels do
      local initial_layer = 1
      if level == (initial_level + 1) then
         initial_layer = math.max(1, math.floor(level_height * layer))
      end
      
      filler.fillUp(width, length, level_height, initial_layer, glass.selector, blocks)
   end

   glass.build_roof(width, length, blocks)

   rob.up()
   glass.build_ladder(width, length, level_height, levels, blocks)

   rob.rollback_to(mark)
   if initial_floor == 0 then
      glass.build_door(length, level_height)
   end
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
   for kind, specific in pairs(styles.default) do
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

function glass.routes(router, prefix, corner_stone, build_dir, width, length, level_height, levels)
   -- This building's routes look like:
   --    yzzzzz
   --   +y-----+
   --   |yzzzzz|
   --   +y-----+
   --   |yzzzzz|
   --   +y-----+
   -- xxxyzzzzz|
   -- --+------+--
   local bsides = {
      front = rotated_sides[build_dir].front,
      back = rotated_sides[build_dir].back,
      left = rotated_sides[build_dir].left,
      right = rotated_sides[build_dir].right,
      up = sides.up,
      down = sides.down
   }

   function coord(x, y, z)
      local v
      if build_dir == sides.north then
         v = vec3d:new(-x, y, -z)
      elseif build_dir == sides.east then
         v = vec3d:new(-z, y, -x)
      elseif build_dir == sides.south then
         v = vec3d:new(x, y, z)
      else
         v = vec3d:new(z, y, x)
      end
      return corner_stone + v
   end
   
   router:add_node(prefix .. ":cornerstone", coord(0, 0, 0))
   router:add_node(prefix .. ":roof", coord(0, levels * level_height + 1, 0))
   router:add_node(prefix .. ":entry", coord(length / 2, 1, 0))
   router:add_node(prefix .. ":exit", coord(length / 2 + 1, 1, 0))

   router:add_bipath(prefix .. ":cornerstone", bsides.up, prefix .. ":roof", bsides.down, { { "up", levels * level_height + 1 } })
   router:add_bipath(prefix .. ":entry", bsides.right, prefix .. ":cornerstone", bsides.left, { { "forward", length / 2 - 1 }, { "down", 1 } })
   router:add_bipath(prefix .. ":entry", bsides.left, prefix .. ":exit", bsides.right, { { "forward" } })

   for floor = 1, levels do
      router:add_node(prefix .. ":floor-" .. floor .. ":up", coord(4, floor * level_height + 1, 2))
      router:add_node(prefix .. ":floor-" .. floor .. ":down", coord(length - 4, floor * level_height + 1, 2))

      if floor == 1 then
         router:add_path(prefix .. ":entry", bsides.front, prefix .. ":floor-" .. floor .. ":up", bsides.left, { { "forward", 2 }, { "turn", -1 }, { "forward", length / 2 - 4 } })
         router:add_path(prefix .. ":floor-" .. floor .. ":down", bsides.right, prefix .. ":exit", bsides.front, { { "forward", length / 2 - 4 }, { "turn", -1 }, { "forward", 2 } })
      else
         router:add_path(prefix .. ":floor-" .. (floor - 1) .. ":up", bsides.up, prefix .. ":floor-" .. floor .. ":up", bsides.down, { { "up", level_height } })
         router:add_path(prefix .. ":floor-" .. floor .. ":down", bsides.up, prefix .. ":floor-" .. (floor - 1) .. ":down", bsides.down, { { "down", level_height } })
      end

      router:add_bipath(prefix .. ":floor-" .. floor .. ":up", bsides.left, prefix .. ":floor-" .. floor .. ":down", bsides.right, { { "forward", length - 7 } })
   end
end

return glass
