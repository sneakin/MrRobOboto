local prog = require("rob/drone/programmer")
local sides = require("sides")

local args = {...}
assert(args[1], "no drone script given")
local p = prog:new(sides.east, sides.north, sides.west)
p:reprogram_drone(io.open(args[1], "r"):read("*a"))
