local event = require("event")
local sneaky = require("sneaky/util")
local NetStream = require("net/stream")

-- todo associate the right modem with client streams
-- todo link cards
-- todo bind to a modem/address, port

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

function NetServer:__gc()
  if self.handler_id then
    event.cancel(self.handler_id)
  end
  self:close()
end

function NetServer:loop()
  while true do
    self:poll()
  end
end

function NetServer:background()
  self.handler_id = event.listen("modem_message",
                                 function(type, to, from, port, distance, reply_port, ...)
                                   if port == self.port then
                                     self.handler(NetStream:new(self.modem, from, reply_port, self.port, distance), ...)
                                   end
  end)
  return self.handler_id
end

function NetServer:stop(id)
  event.cancel(id or self.handler_id)
  if not id then
    self.handler_id = nil
  end
end

function NetServer:poll(timeout)
  local packet = { event.pull(timeout, "modem_message", nil, nil, self.port) }
  local type, to, from, port, distance, reply_port = table.unpack(packet)
  local body = sneaky.subtable(packet, 7)

  if type == "modem_message" then
    self.handler(NetStream:new(self.modem, from, reply_port, self.port), table.unpack(body))
  end
end

return NetServer
