local sneaky = require("sneaky/util")
local Palette = require("sneaky/colors")
local number = require("sneaky/number")

local component = require("component")

local Canvas = {}

function Canvas:new(gpu, screen)
  local i = sneaky.class(self, { gpu = gpu or component.gpu, screen = screen or component.screen})
  i:init()
  return i
end

function Canvas:init()
  local srw, srh = self.gpu.getResolution()
  self.screen_res = { width = srw, height = srh }
  self.palette = Palette.instance32
end

function Canvas:set_foreground(r, g, b)
  if type(r) == "string" then
    self.fg = self.palette:get(r)
  elseif r and g and b then
    self.fg = self.palette:rgb(r, g, b)
  else
    self.fg = r
  end
  
  self.gpu.setForeground(self.fg)

  return self
end

function Canvas:set_background(r, g, b)
  if type(r) == "string" then
    self.bg = self.palette:get(r)
  elseif r and g and b then
    self.bg = self.palette:rgb(r, g, b)
  else
    self.bg = r
  end

  self.gpu.setBackground(self.bg)
  return self
end

function Canvas:reset()
  return self
    :set_background("black")
    :set_foreground("white")
end

function Canvas:clear()
  self.gpu.fill(1, 1, self.screen_res.width, self.screen_res.height, " ")
  return self
end

function Canvas:fill(x, y, w, h, char)
  self.gpu.fill(x, y, w, h, char or " ")
  return self
end

function Canvas:set(x, y, char)
  self.gpu.set(x, y, char or " ")
  return self
end

function Canvas:draw_line(x1, y1, x2, y2, char)
  if x1 > x2 then
    x1, x2 = x2, x1
    y1, y2 = y2, y1
  end
  --x1, x2 = minmax(x1, x2)
  --y1, y2 = minmax(y1, y2)

  local dx = x2 - x1
  local dy = y2 - y1
  local len = math.sqrt(dx * dx + dy * dy)
  if len <= 0 then
    return nil
  end
  local mx = dx / len
  local my = dy / len

  char = char or " "

  if my == 0 then -- horizontal line
    for x = x1, x2 - 1 do
      self:set(x, y1, char)
    end
  elseif mx == 0 then -- vertical line
    y1, y2 = number.minmax(y1, y2)
    for y = y1, y2 - 1 do
      self:set(x1, y, char)
    end
  else
    local x = x1
    local y = y1
    repeat do
        self:set(x, y, char)
        
        x = x + mx
        y = y + my
    end until x > x2 -- x is guarenteed to be < x2 due to swap
  end

  return self
end

function Canvas:draw_box(x1, y1, x2, y2, char)
  x1, x2 = number.minmax(x1, x2)
  y1, y2 = number.minmax(y1, y2)

  x2 = x2 - 1
  y2 = y2 - 1

  local the_char = char or "-"
  for x = x1, x2 do
    self:set(x, y1, the_char)
    self:set(x, y2, the_char)
  end

  the_char = char or "|"
  for y = y1, y2 do
    self:set(x1, y, the_char)
    self:set(x2, y, the_char)
  end

  if not char then
    self:set(x1, y1, "+")
    self:set(x1, y2, "+")
    self:set(x2, y1, "+")
    self:set(x2, y2, "+")
  end
  
  return self
end

return Canvas
