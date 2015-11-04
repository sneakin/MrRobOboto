local tunneler = require("rob/tunneler")

local args = {...}
local length = tonumber(args[1] or 1)

print(tunneler.dig(length))
