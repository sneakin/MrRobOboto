local event = require("event")
local Net = require("net")
local sneaky = require("sneaky/util")

local NetStream = {}

function NetStream:new(modem, remote, port, src_port, last_distance)
  local e = sneaky.class(self, {
    modem = modem,
    port = port,
    remote = remote,
    src_port = src_port or Net.random_port(modem),
    _last_distance = last_distance
  })

  e:init()

  return e
end

function NetStream:__tostring()
  return (self.remote or "broadcast") .. ":" .. self.port
end

function NetStream:src_address()
  return self.modem.address
end

function NetStream:remote_address()
  return self.remote
end

function NetStream:init()
  self.modem.open(self.src_port)
  assert(self.modem.isOpen(self.src_port))
end

function NetStream:close()
  self.modem.close(self.src_port)
end

function NetStream:__gc()
  self:close()
end

function NetStream:recvfrom(timeout)
  local packet = { event.pull(timeout, "modem_message", nil, self.remote, self.src_port) }
  local kind, to, from, port, distance, reply_port = table.unpack(packet)
  local body = sneaky.subtable(packet, 7)

  if kind == "modem_message" then
    self._last_distance = distance
    return body[1], from, table.unpack(sneaky.subtable(body, 2))
  else
    return nil, "timeout"
  end
end

function NetStream:getLastDistance()
  return self._last_distance or 0
end

function NetStream:recv(timeout)
  local packet = {self:recvfrom(timeout)}
  return packet[1], table.unpack(sneaky.subtable(packet, 3))
end

function NetStream:send(...)
  if self.remote then
    self.modem.send(self.remote, self.port, self.src_port, ...)
  else
    self.modem.broadcast(self.port, self.src_port, ...)
  end
end

return NetStream
