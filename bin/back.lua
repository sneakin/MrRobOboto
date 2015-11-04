local rob = require("rob")

local args = {...}
local n = tonumber(args[1] or 1)

print(rob.backBy(n))
