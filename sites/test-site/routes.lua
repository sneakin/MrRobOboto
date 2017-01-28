local sides = require("sides")
local rotated_sides = require("rob/rotated_sides")
local router = require("rob/site/router")
local v = require("vec3d")
local building = require("rob/buildings/glass")

local routes = {
   nodes = {
      { "street:building-1", v:new(241, 66, 116) },
      { "street:building-2", v:new(238, 66, 122) },
      { "building-2:zone-1:entry", v:new(238, 67, 135) },
      { "building-2:zone-1:exit", v:new(237, 67, 135) },
      { "tunnel-1:north:entrance", v:new(220, 65, 115) },
      { "tunnel-1:north:exit", v:new(221, 65, 115) },
      { "tunnel-1:south:entrance", v:new(221, 65, 330) },
      { "tunnel-1:south:exit", v:new(220, 65, 330) },
      { "street:building-3", v:new(204, 69, 105) },
      { "street:building-4", v:new(256, 67, 124) },
      { "mine-1:entrance", v:new(257, 69, 58) }
   },
   paths = {
      -- building-1
      { "building-1:exit", sides.west, "street:building-1", sides.east, { { "forward", 6 } } },

      -- street
      { "street:building-1", sides.south, "building-1:entry", sides.west, { { "forward", 1 }, { "turn", 1 }, { "forward", 6 } } },
      { "street:building-1", sides.south, "street:building-2", sides.north, { { "forward", 6 } } },
      { "street:building-2", sides.north, "street:building-1", sides.south, { { "forward", 6 } } },
      { "street:building-2", sides.south, "building-2:entry", sides.north, { { "turn", -1 }, {"forward", 1 }, {"turn", 1}, { "forward", 5 } } },
      { "street:building-3", sides.west, "building-3:entry", sides.north, { { "forward", 1 }, { "turn", 1 }, { "forward", 5 } } },
      { "building-3:exit", sides.north, "street:building-3", sides.south, { { "forward", 5 } } },


      -- building-2
      { "building-2:exit", sides.north, "street:building-2", sides.south, { { "forward", 5 } } },
      { "building-2:entry", sides.south, "building-2:zone-1:entry", sides.north, { { "forward", 8 } } },
      { "building-2:zone-1:entry", sides.east, "building-2:zone-1:exit", sides.west, { { "forward", 1 } } },
      { "building-2:zone-1:exit", sides.north, "building-2:exit", sides.south, { { "forward", 8 } } },

      -- tunnel
      { "street:building-1", sides.west, "tunnel-1:north:entrance", sides.east, { { "forward", 20 }, { "down", 2 } } },
      { "tunnel-1:north:exit", sides.east, "street:building-1", sides.west, { { "up", 2 }, { "forward", 19 } } },
      { "tunnel-1:north:entrance", sides.south, "tunnel-1:south:exit", sides.north, { { "forward", 215 } } },
      { "tunnel-1:south:entrance", sides.north, "tunnel-1:north:exit", sides.south, { { "forward", 215 } } },

      -- south:building-1
      { "tunnel-1:south:exit", sides.west, "south:building-1:cornerstone", sides.east, { { "forward", 8 } } },
      { "tunnel-1:south:exit", sides.west, "south:building-1:entry", sides.east, { { "up", 1 }, { "forward", 4 }, { "turn", 1 }, { "forward", 7 }, { "turn", -1 }, { "forward", 4 } } },
      { "south:building-1:exit", sides.east, "tunnel-1:south:entrance", sides.south, { { "forward", 4 }, { "turn", 1 }, { "forward", 7 }, { "turn", -1 }, { "forward", 5 }, { "turn", 1 }, { "forward", 1 }, { "down", 1 } } },
   },
   bipaths  = {
      { "street:building-1", sides.west, "mining-tower-1:entry", sides.west, { { "forward", 14}, { "turn", -1 }, { "forward", 56 }, { "turn", -1 }, { "forward", 26 } } },
      { "tunnel-1:north:entrance", sides.east, "tunnel-1:north:exit", sides.west, { { "forward", 1 } } },
      { "tunnel-1:south:entrance", sides.west, "tunnel-1:south:exit", sides.east, { { "forward", 1 } } },
      { "street:building-2", sides.south, "street:building-4", sides.west, { { "forward", 3 }, { "turn", 1 }, { "forward", 16 } } },
      { "street:building-1", sides.west, "street:building-3", sides.east, { { "forward", 28 }, { "turn", -1 }, { "forward", 10 }, { "up", 2 }, { "turn", 1 }, { "forward", 8 } } },
      { "street:building-4", sides.south, "building-4:entry", sides.north, { { "forward", 6 } } },
   }
}

function charger(router, location, station, name, position, building_dir)
   local bsides = {
      front = rotated_sides[building_dir].front,
      back = rotated_sides[building_dir].back,
      left = rotated_sides[building_dir].left,
      right = rotated_sides[building_dir].right,
      up = sides.up,
      down = sides.down
   }
   local vfront = {
      [ sides.north ] = v:new(0, 0, -1),
      [ sides.east ] = v:new(-1, 0, 0),
      [ sides.south ] = v:new(0, 0, 1),
      [ sides.west ] = v:new(1, 0, 0)
   }

   local bback = -vfront[building_dir]
   local bfront = vfront[building_dir]

   router:add_node(name, position)
   router:add_node(name .. ":a", position + v:new(0, 1, 0))
   router:add_node(name .. ":b", position + bback)
   router:add_node(name .. ":c", position + v:new(0, -1, 0))
   router:add_node(name .. ":d", position + bfront)
   
   router:add_path(location .. ":up", bsides.front, name, bsides.right, { { "forward", 3 + station * 3}, { "turn", 1 }, { "up", 1 }, {"forward", 2} })
   router:add_path(name, bsides.right, location .. ":down", bsides.right, { { "turn", -1 }, { "down", 1 }, {"forward", 3 + station * 3}, { "turn", -1 }, { "forward", 1 } })
   router:add_bipath(name .. ":a", bsides.right, name, bsides.left, { { "forward", 2}, { "down", 1 } })
   router:add_bipath(name .. ":b", bsides.right, name, bsides.back, { { "forward", 2}, { "turn", 1 }, { "forward", 1 } })
   router:add_bipath(name .. ":c", bsides.right, name, bsides.left, { { "forward", 2}, { "up", 1 } })
   router:add_bipath(name .. ":d", bsides.right, name, bsides.front, { { "forward", 2}, { "turn", -1 }, { "forward", 1 } })

end

local args = {...}
local router = args[1] or router:new()

building.routes(router, "building-1", v:new(246, 66, 120), sides.east, 16, 10, 5, 8)
charger(router, "building-1:floor-1", 0, "building-1:charger-1", v:new(251, 68, 113), sides.east)
charger(router, "building-1:floor-1", 1, "building-1:charger-2", v:new(254, 68, 113), sides.east)
building.routes(router, "building-2", v:new(232, 66, 126), sides.south, 16, 16, 5, 4)
building.routes(router, "building-3", v:new(196, 68, 110), sides.south, 20, 16, 8, 8)
building.routes(router, "building-4", v:new(253, 66, 130), sides.south, 9, 9, 6, 8)
building.routes(router, "mining-tower-1", v:new(252, 67, 63), sides.east, 10, 10, 6, 8)
building.routes(router, "south:building-1", v:new(213, 65, 330), sides.west, 16, 16, 6, 2)

for i, node in ipairs(routes.nodes) do
   router:add_node(table.unpack(node))
end

for i, path in ipairs(routes.paths) do
   router:add_path(table.unpack(path))
end

for i, path in ipairs(routes.bipaths) do
   router:add_bipath(table.unpack(path))
end

return router
