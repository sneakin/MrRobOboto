local rob = require("rob")
local sides = require("sides")

local args = {...}

local dir = args[1]

if dir == nil then
  print("Usage: turn-to dir")
  for i, j in ipairs(sides) do
    print(i, j)
  end
else
  rob.face(dir)
end
