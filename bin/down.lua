local rob = require("rob")

local args = {...}

if args[1] == "all" then
   print(rob.bottomOut())
else
   print(rob.downBy(tonumber(args[1] or 1)))
end
