local NetStream = require("net/stream")
local sneaky = require("sneaky/util")
local rsh = {
  DEFAULT_PORT = 23,
  TIMEOUT = 3
}

function rsh:new(modem, host, port)
   return sneaky.class(self, { client = NetStream:new(modem, host, port or rsh.DEFAULT_PORT) })
end

function rsh:execute(cmd, ...)
  self.client:send(cmd, ...)
  return self
end

function rsh:poll(timeout)
  return self.client:recvfrom(timeout or rsh.TIMEOUT)
end

function rsh:close()
  self.client:close()
  return self
end

function rsh:getLastDistance()
  return self.client:getLastDistance()
end

return rsh