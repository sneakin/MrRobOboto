local component = require("component")
local robot = component.robot
local table = require("table")
local sides = require("sides")
local rob = require("rob")

local tunneler = {}

function start(length)
  rob.busy()

  local cur_pos = 1

  for i = 1, length do
    print("Progress " .. i .. "/" .. length)
    for _, dir in pairs({sides.forward, sides.down}) do
      local r, why = robot.swing(dir)
      if not r then
        print(why)
        if why == "block" then
          rob.notcool()
          return false, i - 1
        elseif not why == "air" then
         print("bye")
         rob.notcool()
         return false, i - 1
        end
      end
    end

    robot.suck(sides.forward)
    robot.suck(sides.down)
    if robot.move(sides.forward) then
      cur_pos = cur_pos + 1
    end
  end

  rob.cool()

  return true, cur_pos + 1
end

function returnBack(distance)
   robot.turn(false)
   robot.turn(false)
   rob.forwardBy(distance)
end

function tunneler.dig(length)
  local ret = true
  local success, dist_back = start(length)
  if not success then
     print("Failed")
     ret = false
  end

  returnBack(dist_back)

  if ret then
     rob.cool()
  else
     rob.notcool()
  end
  
  return ret
end

return tunneler
