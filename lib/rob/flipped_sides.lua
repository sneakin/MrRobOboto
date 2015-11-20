local sides = require("sides")

local flipped_sides = {
      [ sides.front ] = sides.back,
      [ sides.back ] = sides.front,
      [ sides.left ] = sides.right,
      [ sides.right ] = sides.left,
      [ sides.up ] = sides.down,
      [ sides.down ] = sides.up,
      [ sides.east ] = sides.west,
      [ sides.west ] = sides.east,
      [ sides.north ] = sides.south,
      [ sides.south ] = sides.north,
      [ sides.unknown ] = sides.unknown,
      [ sides.forward ] = sides.back
}

return flipped_sides
