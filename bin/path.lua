local rob = require("rob")

local args = {...}
local cmd = args[1]

if cmd == "reset" then
   rob.checkpoints:reset()
elseif cmd == "rollback" then
   if args[2] then
      local n = tonumber(args[2])
      rob.rollback(n)
   else
      rob.rollback_all()
   end
elseif cmd == "print" then
   for i, point in ipairs(rob.checkpoints.points) do
      print(i, point)
   end
else
   print("Usage: path command [args...]")
end
