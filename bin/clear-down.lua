local rc = require("rob/clear")

local args = {...}

if not args[1] then
   print("Usage: clear-down width length depth")
end

local width = tonumber(args[1])
local length = tonumber(args[2])
local depth = tonumber(args[3])

print(rc.volumeDown(width, length, depth))
