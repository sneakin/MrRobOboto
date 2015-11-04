local planter = require("rob/planter")

local args = {...}

if not args[1] and not args[2] then
   print("Usage: planter width length")
   os.exit()
end

local w = tonumber(args[1])
local l = tonumber(args[2])
local sx = tonumber(args[3] or 4)
local sy = tonumber(args[4] or sx)

print(planter.plant(w, l, sx, sy))
