local event = require("event")
local component = require("component")
local gpu = component.gpu
local screen = component.screen

local width, height = gpu.getResolution()

local colors = require("sneaky/colors")
local palette = colors:new()
local scheme = {
  very_high = palette:get("red"),
  high = palette:get("magenta"),
  med = palette:get("cyan"),
  low = palette:get("blue"),
  zero = palette:get("black")
}

local TIMEOUT = 60 * 100
local last_time = os.time()
local running = false

function loop()
  running = true
  gpu.setBackground(palette:get("black"))
  
  local done = nil
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
  local w, h = gpu.getResolution()
  gpu.fill(1, 1, w, h, " ")

  last_time = os.time()
  running = false
end

function timeout_callback()
  local now = os.time()
  
  if not running and (now - last_time) > TIMEOUT then
    loop()
  end
end

function key_callback()
  last_time = os.time()
end

function quit_callback()
  done = true
  stop()
end

local timeout_id, key_id, quitter_id

function stop()
  if timeout_id then
    event.cancel(timeout_id)
  end
  if key_id then
    event.cancel(key_id)
  end
  if quitter_id then
    event.cancel(quitter_id)
  end
  
  print("Plasma stopped", timeout_id, key_id, quitter_id)

  timeout_id, key_id, quitter_id = nil, nil, nil
end

local args = {...}

if args[1] == "test" then
  loop()
elseif args[1] == "stop" then
  event.push("plasma_quit")
else
  timeout_id = event.timer(TIMEOUT / 100, timeout_callback, math.huge)
  key_id = event.listen("key_down", key_callback)
  quitter_id = event.listen("plasma_quit", quit_callback)

  print("Plasma started", timeout_id, key_id, quitter_id)
end
