local rob = require("rob")

local args = {...}
local times = tonumber(args[1]) or 1

rob.turn(times)

if rob.hasNavigation() then
  print(rob.navigation.getFacing())
end
