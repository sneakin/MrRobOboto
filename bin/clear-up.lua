local rc = require("rob/clear")
local rob = require("rob")

local args = {...}

if not args[1] then
   print("Usage: clear-up width length height")
end

local width = tonumber(args[1])
local length = tonumber(args[2])
local height = tonumber(args[3])

local good, err = pcall(rc.volumeUp, width, length, height)

rob.rollback_all()

if good then
   print("Success!")
else
   print("Failed.")
   print(err)
   if type(err) == "table" then
      for k,v in pairs(err) do
         print(k, v)
      end
   end
   if debug and debug.traceback() then
      print(debug.traceback())
   end
end
