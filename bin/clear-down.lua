local sneaky = require("sneaky/util")
local rc = require("rob/clear")
local rob = require("rob")

local args = {...}

if not args[1] then
   print("Usage: clear-down width length depth")
end

local width = tonumber(args[1])
local length = tonumber(args[2])
local depth = tonumber(args[3])

local good, err = pcall(rc.volumeDown, width, length, depth)

if good then
   print("Success!")
else
   print("Failed.")
   sneaky.print_error(err)
end

rob.rollback_all()
