local component = require("component")
local robot = component.robot
local table = require("table")
local sides = require("sides")
local rob = require("rob")

local borer = {}

function borer.bore(depth)
  rob.busy()

  local cur_depth = 0

  for i = 1, depth do
    local r, why = robot.swing(sides.down)
    if not r then
      print(why)
      if why == "block" then
        break
      elseif not why == "air" then
       print("bye")
        return false, i
      end
    end

    robot.suck(sides.down)
    robot.move(sides.down)

    cur_depth = cur_depth + 1
  end

  -- for n = cur_depth,1,-1 do
  --  robot.move(sides.up)
  -- end

  rob.cool()

  return true, depth
end

return borer
