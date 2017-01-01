local shell = require("shell")
local pid = require("sneaky/pid")
local listener

function start(args)
  shell.execute("kiosk-powerd " .. (args or ""))
end

function stop(msg)
  local p = pid.read("/tmp/kiosk-powerd.pid")
  if p then
    shell.execute("kiosk-powerd -kill " .. p)
  end
end
