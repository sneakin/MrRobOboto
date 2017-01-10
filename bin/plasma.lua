local event = require("event")
local component = require("component")
local gpu = component.gpu
local screen = component.screen

local width, height = gpu.getResolution()
local done = nil

local colors = require("sneaky/colors")
local palette = colors:new()
local scheme = {
  very_high = palette:get("red"),
  high = palette:get("magenta"),
  med = palette:get("cyan"),
  low = palette:get("blue"),
  zero = palette:get("black")
}

function loop()
  gpu.setBackground(palette:get("black"))
  
  while not done do
    local t = os.time()
    
    for y = 1, height do
      for x = 1, width do
        local tx = width * math.sin(t * 6.28 / 1900)
        local ty = height * math.sin(t * 6.28 / 3100)
        local ax = math.sin(t * 6.28 / 2000)
        local ay = math.sin((t + 0.5) * 6.28 / 4100)
        local az = math.sin((t + 1) * 6.28 / 1000)
        local vx = ax * math.sin((x - tx) * 6.28 / width * (y - ty) * 6.28 / height)
        local vy = ay * math.sin((x - tx) * 6.28 / width * (y - ty) * 6.28 / height)
        local vz = az * math.sin((2*x - tx) * 6.28 / width * (y/2 - ty) * 6.28 / height)
        local v = math.abs(vx + vy + vz)
        if v > 1.5 then
          gpu.setForeground(scheme.very_high)
          gpu.set(x, y, 'X')
        elseif v > 1.5 then
          gpu.setForeground(scheme.high)
          gpu.set(x, y, 'X')
        elseif v > 0.75 then
          gpu.setForeground(scheme.med)
          gpu.set(x, y, '*')
        elseif v > 0.25 then
          gpu.setForeground(scheme.low)
          gpu.set(x, y, '.')
        else
          gpu.setForeground(scheme.zero)
          gpu.set(x, y, ' ')
        end
      end
    end
    local ev = event.pull(10, "key_down")
    if ev then
      done = true
    end
  end

  gpu.setBackground(palette:get("black"))
  gpu.setForeground(palette:get("white"))
end

loop()
