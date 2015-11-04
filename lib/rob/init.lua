local math = require("math")
local event = require("event")
local shell = require("shell")
local component = require("component")
local crobot = component.robot
local sides = require("sides")
local robot = require("robot")
local nav = nil

for kind, addr in pairs(component.list()) do
  if kind == "navigation" then
    nav = component.navigation
  end
end

local rob = {}

function rob.navigation()
   return nav
end

function rob.hasNavigation()
   return not (nav == nil)
end

--
-- Motion procedures
--

function rob.moveBy(dir, blocks)
   for i = 1, (blocks or 1) do
      if not crobot.move(dir) then
         return false, i-1
      end
   end

   return true, (blocks or 1)
end

local dir_procs = {
   forwardBy = "forward",
   backBy = "back",
   upBy = "up",
   downBy = "down"
}
for name, dir in pairs(dir_procs) do
   rob[name] = function(n)
      return rob.moveBy(sides[dir], n)
   end

   rob[dir] = rob[name]
end

function rob.bottomOut()
   rob.downBy(256)
   return true
end

function rob.face(dir)
  if dir == sides.up or dir == sides.down then
    return false
  end

  local face = nav.getFacing()
  repeat
    robot.turnLeft()
    face = nav.getFacing()
    print("Facing", face, dir)
  until tonumber(face) == tonumber(dir)

  return true
end

function rob.turn(times)
   times = times or 1
   
   for i = 1, math.abs(times) do
      crobot.turn(times < 0)
   end
end

function rob.turnRight(times)
   return rob.turn(-times)
end

function rob.turnLeft(times)
   return rob.turn(times)
end

function rob.turnAround()
   return rob.turn(2)
end

function rob.swing(dir)
   return crobot.swing(dir)
end

--
-- Lamp state
--

local blinker = require("rob/blinker")

function rob.blink(delay, color)
   blinker.blink(delay, color)
end

function rob.setLightColor(color)
  blinker.off()
  robot.setLightColor(color)
end

--
-- Present state indicators
--

function rob.busy()
  rob.setLightColor(0xFF0000)
end

function rob.cool()
  rob.setLightColor(0xFF00)
end

function rob.notcool()
  rob.blink(0.5, 0xffff00)
end

--
-- Utility procedures
--

function rob.execCommands(commands)
  for _,c in ipairs(commands) do
     if not shell.execute(c) then
        print("Failed to execute: " .. c)
        return false
     end
  end

  return true
end


-----------

print("Loaded rob", rob)
return rob
