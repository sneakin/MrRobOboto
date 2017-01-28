local sneaky = require("sneaky/util")
local sides = require("sides")

local rotated_sides = {
   [ sides.north ] = {
      front = sides.north,
      right = sides.east,
      back = sides.south,
      left = sides.west
   },
   [ sides.east ] = {
      front = sides.east,
      right = sides.south,
      back = sides.west,
      left = sides.north
   },
   [ sides.south ] = {
      front = sides.south,
      right = sides.west,
      back = sides.north,
      left = sides.east
   },
   [ sides.west ] = {
      front = sides.west,
      right = sides.north,
      back = sides.east,
      left = sides.south
   }
}

local TURN_MAPPING = {
  [ sides.north ] = 0,
  [ sides.west ] = 1,
  [ sides.south ] = 2,
  [ sides.east ] = 3
}

local REVERSE_TURN_MAPPING = sneaky.inverse(TURN_MAPPING)

function rotated_sides.turns_from(dir, amount)
  return REVERSE_TURN_MAPPING[(TURN_MAPPING[dir] + amount) % 4]
end

function rotated_sides.turns_to(dir, amount)
  return rotated_sides.turns_from(dir, -amount)
end
return rotated_sides
