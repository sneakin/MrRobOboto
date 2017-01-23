local prog = require("rob/drone/programmer")
local sides = require("sides")

local PORT = 3
local args = {...}
assert(args[1], "no drone script given")
--local eeprom_writer = prog.Remote:new()
local eeprom_writer = prog.Local:new()
local p = prog:new(args[1], sides.east, sides.north, sides.west, eeprom_writer)
p:reprogram_loop(true, "")
