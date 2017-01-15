local router = require("rob/site/router")
local vec3d = require("vec3d")
local sides = require("sides")

local r = router:new()

r:add_node("Alpha", vec3d:new(0, 0, 0))
r:add_node("Beta", vec3d:new(10, 10, 10))
r:add_node("Gamma", vec3d:new(10, 0, 0))

r:add_path("Alpha", sides.south, "Beta", sides.west, { { "forward", 10 }, { "turn", 1 }, { "forward", 10 }, { "up", 10 } })

r:add_path("Alpha", sides.east, "Gamma", sides.west, { { "forward", 10 } })
r:add_path("Gamma", sides.south, "Beta", sides.north, { { "forward", 10 } })

return r
