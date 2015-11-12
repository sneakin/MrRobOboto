local sneaky = require("sneaky/util")
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

if good then
   print("Success!")
else
   print("Failed.")
   sneaky.print_error(err, debug.traceback())
end

rob.rollback_all()
