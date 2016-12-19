local event = require("event")
local NetStream = require("net/stream")

local NetServer = {}
function NetServer:listen(modem, port, handler)
  local e = {
    modem = modem,
    port = port,
    handler = handler
  }
  setmetatable(e, self)
  self.__index = self

  e:init()

  return e
end

function NetServer:init()
  self.modem.open(self.port)
  assert(self.modem.isOpen(self.port))
end

function NetServer:loop()
  while true do
    self:poll()
  end
end

function NetServer:background()
  event.listen("modem_message", function(type, to, from, port, distance, reply_port, body)
    self.handler(NetStream:new(self.modem, from, reply_port, self.port), body)
  end)
end

function NetServer:poll(timeout)
  local packet = { event.pull(timeout, "modem_message", nil, nil, self.port) }
  local type, to, from, port, distance, reply_port, body = table.unpack(packet)

  if type == "modem_message" then
    self.handler(NetStream:new(self.modem, from, reply_port, self.port), body)
  end
end

return NetServer