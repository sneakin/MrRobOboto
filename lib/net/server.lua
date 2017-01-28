local event = require("event")
local sneaky = require("sneaky/util")
local NetStream = require("net/stream")
local MultikeyTable = require("sneaky/multikey_table")

-- todo associate the right modem with client streams
-- todo link cards
-- todo bind to a modem/address, port

local NetServer = {}
function NetServer:listen(modem, port, handler)
  local e = {
    modem = modem,
    port = port,
    handler = handler,
    _clients = MultikeyTable:new()
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
  self:stop(nil, true)
end

function NetServer:loop()
  while true do
    self:poll()
  end
end

function NetServer:stream_for(remote_addr, remote_port, distance)
  local s = self._clients:get({remote_addr, remote_port})

  if s and not s:alive() then
    s:close()
    s = nil
  end
  
  if not s then
    s = NetStream:new(self.modem, remote_addr, remote_port, self.port, distance)
    self._clients:set({remote_addr, remote_port}, s)
  end

  return s
end

function NetServer:background()
  self.handler_id = event.listen("modem_message",
                                 function(type, to, from, port, distance, seq_id, reply_port, ...)

                                   if port == self.port then
                                     local client = self:stream_for(from, reply_port, distance)
                                     client:on_receive(type, to, from, port, distance, seq_id, reply_port, ...)
                                     self.handler(client, ...)
                                   end

                                   self:collectgarbage()
  end)
  return self.handler_id
end

function NetServer:stop(id, gc)
  self:collectgarbage(gc)
  if not gc then
    self.modem.close(self.port)
  end
  event.cancel(id or self.handler_id)
  if not id then
    self.handler_id = nil
  end
end

function NetServer:collectgarbage(gc)
  for keys, client in self._clients:pairs() do
    if not client:alive() then
      client:close(gc)
    end
  end
end

function NetServer:poll(timeout)
  local packet = { event.pull(timeout, "modem_message", nil, nil, self.port) }
  local type, to, from, port, distance, seq_id, reply_port = table.unpack(packet)
  local body = sneaky.subtable(packet, 8)

  if type == "modem_message" then
    local client = self:stream_for(from, reply_port)
    client:on_receive(table.unpack(packet))
    self.handler(client, table.unpack(body))
  end
end

return NetServer
