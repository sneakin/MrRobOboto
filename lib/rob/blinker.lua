local event = require("event")
local component = require("component")
local _, robot = pcall(function() return component.robot end)

local light_timer = nil
local light_color = 0xff
local light_on = false

local blinker = {}

function blinker.tick()
  if light_on then
    robot.setLightColor(light_color)
  else
    robot.setLightColor(0)
  end
  light_on = not light_on
end

function blinker.blink(delay, color)
  light_color =color
  if not light_timer then
    light_timer = event.timer(delay, blinker.tick, math.huge)
  end
end

function blinker.off()
  if light_timer then
    event.cancel(light_timer)
  end

  light_timer = nil
end

return blinker
