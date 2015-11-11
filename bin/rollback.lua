local rob = require("rob")

local args = {...}

if args[1] then
   local num_points = tonumber(args[1])
   rob.checkpoints:rollback(num_points)
else
   rob.checkpoints:rollback_all()
end
