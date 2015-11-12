local computer = require("computer")
local sides = require("sides")
local robot = require("robot")
local component = require("component")
local crobot = component.robot
local rob = require("rob")
local areas = require("rob/pathing/areas")
local volumes = require("rob/pathing/volumes")

local clear = {}

function clear.action(points, dir)
   local times = 1
   while crobot.detect(dir) and times < 16 do
      times = times + 1
      
      local good, why = crobot.swing(dir)
      if why == "entity" then
         print(why)
         computer.beep(440, 3)
      elseif not good then
         if not (why == "air") then
            print(why)
            return false
         end
      end
   end

   crobot.suck(sides.forward)
   crobot.suck(sides.down)

   return times < 16
end

function clear.area(width, length)
   return areas.square(width, length, clear.action)
end

function clear.volumeUp(width, length, height)
   return volumes.cubeUp(width, length, height, clear.action)
end

function clear.volumeDown(width, length, depth)
   return volumes.cubeDown(width, length, depth, clear.action)
end

--------

return clear
