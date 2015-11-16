local filler = require("rob/filler")
local rob = require("rob")
local robinv = require("rob/inventory")

local args = {...}
local item = args[1]
local width = tonumber(args[2])
local length = tonumber(args[3])
local height = tonumber(args[4])
local initial_floor = tonumber(args[5])

robinv.selectFirst(item)

local good, err = pcall(filler.fillUp, width, length, height, initial_floor,
                        function(x, y, w, h, z, h)
                           if robinv.count() <= 0 then
                              robinv.selectFirst(item)
                           end

                           return true
end)
rob.rollback_all()

if good then
   print("Success!")
else
   print("Failed.")
end
