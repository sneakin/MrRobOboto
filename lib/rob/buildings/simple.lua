local sneaky = require("sneaky/util")
local number = require("sneaky/number")
local filler = require("rob/filler")
local inv = require("rob/inventory")
local rob = require("rob")
local sides = require("sides")
local styles = require("rob/buildings/styles")
local vec3d = require("vec3d")
local rotated_sides = require("rob/rotated_sides")

local simple = {}

function corner(x, y, w, l)
   return ((x == 1 or x == w) and (y == 1 or y == l))
end

function simple.selector(x, y, w, l, z, h, blocks, ...)
   print("selector", x, y, w, l, z, h, blocks, ...)
   if z == 1 or z == h then -- floor
      if x == 1 or x == w
      or y == 1 or y == l
      then
         inv.selectFirst(blocks.outer_wall)
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
         inv.selectFirst(blocks.outer_wall)
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
   else
      inv.selectFirst(blocks.roof)
   end

   return true
end

function simple.build(width, length, level_height, levels, blocks, initial_floor)
   assert(width > 1, "width must be >1")
   assert(length > 1, "length must be >1")
   assert(level_height > 0, "level_height must be >0")
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
      
      filler.fillUp(width, length, level_height, initial_layer, simple.selector, blocks)
   end

   filler.floor(width, length, roof_selector, blocks)

   rob.up()
   rob.rollback_to(mark)
end

function simple.requirements(width, length, level_height, levels, block_types)
   local blocks = {}
   for kind, specific in pairs(styles.default) do
      blocks[kind] = 0
   end

   blocks.floor = (width - 1) * (length - 1) * levels - 5
   blocks.ceiling = (width - 1) * (length - 1) * levels - 5
   blocks.roof = width * length - 5
   blocks.outer_wall = 2 * width + 2 * length

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

function simple.check_requirements(width, length, level_height, levels, blocks)
   local reqs = simple.requirements(width, length, level_height, levels, blocks)
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

function simple.routes(router, prefix, corner_stone, build_dir, width, length, level_height, levels)
end

return simple
