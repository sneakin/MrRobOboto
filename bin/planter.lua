local rob = require("rob")
local planter = require("rob/planter")

local args = {...}

if not args[1] and not args[2] then
   print("Usage: planter item width [[length] [[spacing-x] [spacing-y]]]")
   os.exit()
end

local item = args[1]
local w = tonumber(args[2])
local l = tonumber(args[3] or w)
local sx = tonumber(args[4] or 3)
local sy = tonumber(args[5] or sx)

local good, err = pcall(planter.plant, item, w, l, sx, sy)

rob.rollback_all()

if good then
   print("Success!")
else
   print("Failed")
end
