local rob = require("rob")
local WallFiller = require("rob/fillers/wall_filler")

local args = {...}
local item = args[1]
local width = tonumber(args[2])
local length = tonumber(args[3])
local height = tonumber(args[4])

local good, err = pcall(WallFiller.fill, width, length, height, item)
rob.rollback_all()

if good then
   print("Success!")
else
   print("Failed.")
   if err then
      print(err)
      if type(err) == "table" then
         for k,v in pairs(err) do
            print(k, v)
         end
      end
   end
   if debug and debug.traceback() then
      print(debug.traceback())
   end
end
