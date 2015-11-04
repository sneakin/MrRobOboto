local rc = require("rob/clear")

local args = {...}

if not args[1] then
   print("Usage: clear-up width length height")
end

local width = tonumber(args[1])
local length = tonumber(args[2])
local height = tonumber(args[3])

print(rc.volumeUp(width, length, height))
