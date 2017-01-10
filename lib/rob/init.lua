local math = require("math")
local event = require("event")
local shell = require("shell")
local component = require("component")
local _, crobot = pcall(function() return component.robot end)
local _, robot = pcall(require, "robot")
local sides = require("sides")
local nav = nil
local checkpoints = require("rob/checkpoints")

for kind, addr in pairs(component.list()) do
  if kind == "navigation" then
    nav = component.navigation
  end
end

local rob = {
   checkpoints = checkpoints:new()
}

function rob.navigation()
   return nav
end

function rob.hasNavigation()
   return not (nav == nil)
end

function rob.checkpoint()
   return rob.checkpoints:getMark()
end

function rob.replace_from(mark, func)
   rob.checkpoints:replaceFrom(mark, func)
end

function rob.rollback()
   rob.checkpoints:rollback()
   return rob
end

function rob.rollback_to(mark)
   rob.checkpoints:rollback_to(mark)
   return rob
end

function rob.rollback_all()
   rob.checkpoints:rollback_all()
   return rob
end

function rob.pop_to(mark)
   rob.checkpoints:pop_to(mark)
   return rob
end

--
-- Motion procedures
--

function rob.moveBy(dir, blocks)
   rob.checkpoints:move_by(dir, blocks)
   return rob
end

local dir_procs = {
   forwardBy = "forward",
   backBy = "back",
   upBy = "up",
   downBy = "down"
}
for name, dir in pairs(dir_procs) do
   rob[name] = function(n)
      rob.checkpoints:move_by(sides[dir], n)
      return rob
   end

   rob[dir] = rob[name]
end

function rob.bottomOut()
   while not crobot.detect(sides.down) do
      rob.down()
   end
   
   return rob
end

function rob.face(dir)
  if dir == sides.up or dir == sides.down then
    return false
  end

  local face = nav.getFacing()
  repeat
    rob.turn()
    face = nav.getFacing()
    print("Facing", face, dir)
  until tonumber(face) == tonumber(dir)

  return true
end

function rob.turn(times)
   rob.checkpoints:turn(times)
   return rob
end

function rob.turnRight(times)
   return rob.turn(-(times or 1))
end

function rob.turnLeft(times)
   return rob.turn(times or 1)
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
-- Actions
--

function rob.place(dir)
   if not crobot.place(dir) then
      error({"place", dir})
   end
   
   return rob
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
