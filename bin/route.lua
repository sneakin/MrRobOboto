local sneaky = require("sneaky/util")
local routes = sneaky.reload("./sites/test-site/routes")
local path = require("rob/path")
local rob = require("rob")
local sides = require("sides")
local flipped_sides = require("rob/flipped_sides")

local args = {...}
local from = args[1] or "building-1:charger:b"
local to = args[2] or "building-2:zone-1:entry"
local from_dir

if args[3] then
   from_dir = sides[args[3]]
end

local a = routes:route(from, to)
if a then
   print("Moving to " .. to)
   rob.busy()
   
   local mark = rob.checkpoint()
   local p, facing = routes:to_path(a, from_dir)
   local good, err = pcall(path.follow, rob, p)
   if good then
      print("Made it?")
      print("Now facing " .. (facing or "???"))
      rob.cool()
   else
      rob.rollback_to(mark)
      print("Error moving:")
      sneaky.print_error(err)
      rob.notcool()
   end
else
   print("No route " .. from .. " to " .. to .. ".")
end
