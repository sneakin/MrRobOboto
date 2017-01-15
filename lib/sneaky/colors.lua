local bit32 = require("bit32")
local sneaky = require("sneaky/util")
local colors = require("colors")

function rgb(r, g, b, bpp)
  bpp = bpp or 8
  r = bit32.rshift(r, 8 - bpp)
  g = bit32.rshift(g, 8 - bpp)
  b = bit32.rshift(b, 8 - bpp)
  return bit32.bor(b, bit32.lshift(g, bpp), bit32.lshift(r, bpp * 2))
end

local COLORS = {
  black = { 0, 0, 0 },
  white = { 255, 255, 255 },
  red = { 255, 0, 0 },
  yellow = { 255, 255, 0 },
  green = { 0, 255, 0 },
  cyan = { 0, 255, 255 },
  blue = { 0, 0, 255 },
  magenta = { 255, 0, 255 }
}

local COLORS_N = {
  [0] = "black",
  [1] = "white",
  [2] = "red",
  [3] = "yellow",
  [4] = "green",
  [5] = "cyan",
  [6] = "blue",
  [7] = "magenta"
}

local palette = {
  rgb32 = rgb
}

function palette:new(bpp)
  return sneaky.class(self, {
  }):init(bpp)
end

function palette:rgb(r, g, b)
  return rgb(r, g, b, self._bpp)
end

function palette:init(bpp)
  self._bpp = bpp or 8
  self._rgb = {}
  for color, v in pairs(COLORS) do
    self._rgb[color] = self:rgb(table.unpack(v))
  end

  return self
end

function palette:get(color)
  return self._rgb[color]
end

function palette:rand(include_black)
  local c
  
  if include_black then
    c = COLORS_N[math.random(#COLORS_N)]
  else
    c = COLORS_N[1 + math.random(#COLORS_N - 1)]
  end

  return self._rgb[c]
end

palette.instance32 = palette:new(8)

return palette
