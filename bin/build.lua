local rob = require("rob")

local args = {...}

if #args <= 5 then
   print("Usage: build type width length level_height levels style initial_floor")
   os.exit()
end

local building_name = args[1]
local width = tonumber(args[2])
local length = tonumber(args[3])
local level_height = tonumber(args[4])
local levels = tonumber(args[5])
local style = args[6] or "default"
local initial_floor = tonumber(args[7])

local building = require("rob/buildings/" .. building_name)
local styles = require("rob/buildings/styles")

local blocks = styles[style]
if not blocks then
   print("Style " .. style .. " was not found.")
   print("Try one of:")
   for k, v in pairs(styles) do
      print("\t" .. k)
   end
   
   os.exit()
end

print("Building " .. building_name .. " at " .. width .. "x" .. length .. " with " .. levels .. " " .. level_height .. " tall levels starting at " .. (initial_floor or 1))

local good, err = pcall(building.build, width, length, level_height, levels, blocks, initial_floor)
rob.rollback_all()

if good then
   print("Success!")
else
   print("Failed.")
end
