local Site = require("rob/site")
local vec3d = require("vec3d")
local sides = require("sides")
local zones = require("rob/site/zones")

local site = Site:new("Tiny Test")

site:add_node("Origin", vec3d:new(0, 64, 0))

site:add_zone("mine", zones.mine, vec3d:new(1, 1, 1), vec3d:new(16, 64, 16))

site:add_zone("building-north", zones.glass_building, vec3d:new(8, 64, -32), 16, 16, 5, 4, sides.north)
site:add_zone("building-south", zones.glass_building, vec3d:new(-8, 64, 32), 16, 16, 5, 1, sides.south)
site:add_zone("building-east", zones.glass_building, vec3d:new(32, 64, 8), 16, 16, 5, 8, sides.east)
site:add_zone("building-west", zones.glass_building, vec3d:new(-32, 64, -8), 16, 16, 5, 4, sides.west)

site:add_bipath("Origin", sides.north, "building-north:entry", sides.south, {{ "forward", 32 }}, 32)
site:add_bipath("Origin", sides.south, "building-south:entry", sides.north, {{ "forward", 32 }}, 32)
site:add_bipath("Origin", sides.east, "building-east:entry", sides.west, {{ "forward", 32 }}, 32)
site:add_bipath("Origin", sides.west, "building-west:entry", sides.east, {{ "forward", 32 }}, 32)

site:add_bipath("Origin", sides.east, "mine:cornerstone", sides.south, { { "forward", 1 }, { "turn", 1 }, { "forward", 1 }, { "down", 64 }})

return site

