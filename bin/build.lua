local rob = require("rob")

local args = {...}
local building = args[1]
local width = tonumber(args[2])
local length = tonumber(args[3])
local level_height = tonumber(args[4])
local levels = tonumber(args[5])
local style = args[6]
local initial_floor = tonumber(args[7])

local building = require("rob/buildings/" .. building)
local styles = require("rob/buildings/styles")

local blocks = styles[style]

local good, err = pcall(building.build, width, length, level_height, levels, blocks, initial_floor)
rob.rollback_all()

if good then
   print("Success!")
else
   print("Failed.")
end
