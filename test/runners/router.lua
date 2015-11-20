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
local to_dir
if args[3] then
   from_dir = sides[args[3]]
end
if args[4] then
   to_dir = sides[args[4]]
end

local a = routes:route(from, to)
if a then
   local b = routes:route(to, from)

   print("Moving to " .. to)
   local good, err = pcall(path.follow, rob, routes:to_path(a, from_dir))
   if good then
      if to_dir then
         facing = to_dir
      else
         facing = flipped_sides[a[#a].to_side]
      end

      print("Moving to " .. from .. " in the " .. facing .. " direction.")
      good, err = pcall(path.follow, rob, routes:to_path(b, facing))
      if good then
         print("Are we back at " .. from .. "?")
      end
   end

   if not good then
      rob.rollback_all()
      sneaky.print_error(err)
   end
else
   print("No route " .. from .. " to " .. to .. ".")
end
