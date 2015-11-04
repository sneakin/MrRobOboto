local borer = require("rob/borer")

local args = {...}
local depth = tonumber(args[1] or 1)

print(borer.bore(depth))
