local rob = require("rob")
local sides = require("sides")

local args = {...}
local dir = sides.front

if args[1] then
   dir = sides[args[1]]
end

rob.swing(dir)
