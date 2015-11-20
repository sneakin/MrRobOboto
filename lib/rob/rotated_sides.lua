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

return rotated_sides
