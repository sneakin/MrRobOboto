local sides = require("sides")
local robot = require("robot")
local component = require("component")
local crobot = component.robot
local rob = require("rob")
local areas = require("rob/pathing/areas")
local volumes = require("rob/pathing/volumes")

local clear = {}

function clear_action(dir)
   if crobot.detect(dir) then
      local good, why = crobot.swing(dir)
      if not good then
         if not (why == "air") then
            print(why)
            return false
         end
      end
   end

   crobot.suck(sides.forward)
   crobot.suck(sides.down)

   return true
end

function clear.area(width, length)
   local good, retdata = areas.square(width, length, clear_action)
   if not good then
      return areas.backToStart(table.unpack(retdata))
   end

   return true
end

function clear.volumeUp(width, length, height)
   return volumes.cubeUp(width, length, height, clear_action)
end

function clear.volumeDown(width, length, depth)
   return volumes.cubeDown(width, length, depth, clear_action)
end

--------

return clear
