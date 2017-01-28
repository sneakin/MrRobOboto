local sides = require("sides")

local side_string = {
}
for _, side in ipairs({"north", "east", "south", "west"}) do
  side_string[sides[side]] = side
end

function sides.tostring(n)
  return side_string[n]
end

return sides
