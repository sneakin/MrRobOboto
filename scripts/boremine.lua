local rob = require("rob")

local args = {...}
local depth = args[1] or 16
local length = args[2] or 16

commands = {
  "bore " .. depth,
  "tunnel " .. length,
  "up " .. depth,
  "turn 2"
}

print(rob.execCommands(commands))
