local filler = require("rob/filler")
local rob = require("rob")
local robinv = require("rob/inventory")

local args = {...}
local item = args[1]
local width = tonumber(args[2])
local length = tonumber(args[3])
local height = tonumber(args[4])

robinv.selectFirst(item)

local good, err = pcall(filler.fillDown, width, length, height,
                        function(x, y, w, h, z, h)
                           if robinv.countInternalSlot() <= 0 then
                              robinv.selectFirst(item)
                           end

                           return true
end)
rob.rollback_all()

if good then
   print("Success!")
else
   print("Failed.")
   print(err)
   for k,v in pairs(err) do
      print(k, v)
   end
   if debug and debug.traceback() then
      print(debug.traceback())
   end
end