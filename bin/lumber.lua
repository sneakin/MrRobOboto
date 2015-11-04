local jack = require("rob/lumberjack")

local args = {...}

if not args[1] and not args[2] then
   print("Usage: lumber width length")
   os.exit()
end

local w = tonumber(args[1])
local l = tonumber(args[2])

print(jack.clear(w, l))
