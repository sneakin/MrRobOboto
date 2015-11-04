local math = require("math")
local table = require("table")
local component = require("component")
local robot = component.robot
local rob = require("rob")
local util = require("sneaky/util")

local pathing = {}

function pathing.follow_path_forward(nodes)
  for n, cmd in ipairs(nodes) do
    local nturns, distance = table.unpack(cmd)

    print("Turning " .. nturns .. " and moving " .. distance)

    for i = 1, math.abs(nturns) do
      robot.turn(nturns > 0)
    end

    local r, d = rob.forwardBy(distance)
    if not r then
      print("Failed")
      return false, n, d
    end
  end

  return true, #nodes
end

function pathing.follow_path_backward(nodes, bad_node, distance_along)
  print("Pathing backwards", bad_node, distance_along)
  for n = bad_node,1,-1 do
    local node = nodes[n]
    if n == bad_node then
      print("Moving back " .. distance_along)
      rob.backBy(distance_along - 1)
    else
       print("Moving back " .. node[2])
       rob.backBy(node[2])
    end

    for nt = 1, math.abs(node[1]) do
       robot.turn(node[1] < 0)
    end
  end
end

function pathing.reverseTurns(nodes)
  for k,v in ipairs(nodes) do
    nodes[k][1] = -nodes[k][1]
  end

  return nodes
end

function pathing.reversePath(nodes)
  return util.reverse(pathing.reverseTurns(nodes))
end

return pathing
