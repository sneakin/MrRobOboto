local sneaky = require("sneaky/util")

local path = {}

function path.follow(mover, p)
   for i, cmdlist in ipairs(p) do
      local cmd = cmdlist[1]
      local args = sneaky.subtable(cmdlist, 2)
      print(i, cmd, table.unpack(args))
      mover[cmd](table.unpack(args))
   end
end

return path
