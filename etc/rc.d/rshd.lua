local shell = require("shell")
local pid = require("sneaky/pid")
local listener

function start(args)
  shell.execute("rshd " .. (args or ""))
end

function stop(msg)
  local p = pid.read("/tmp/rshd.pid")
  if p then
    shell.execute("rshd -kill " .. p)
  end
end
