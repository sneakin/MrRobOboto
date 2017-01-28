local event = require("event")
local Net = require("net")
local sneaky = require("sneaky/util")
local computer = require("computer")

local NetStream = {}

function NetStream:new(modem, remote, port, src_port, last_distance)
  local e = sneaky.class(self, {
    modem = modem,
    port = port,
    remote = remote,
    src_port = src_port or Net.random_port(modem),
    _last_distance = last_distance,
    _next_seq_id = 0,
    _last_seq_received = nil,
    _last_time = computer.uptime(),
    ttl = 60 * 6
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

function NetStream:close(gc)
  if not gc then
    self.modem.close(self.src_port)
  end
end

function NetStream:closed()
  return not self.modem.isOpen(self.src_port)
end

function NetStream:__gc()
  self:close(true)
end

function NetStream:recvloop(timeout)
  while true do
    local packet = { event.pull(timeout, "modem_message", nil, self.remote, self.src_port) }
    local kind, to, from, port, distance, seq_id, reply_port = table.unpack(packet)

    if kind == "modem_message"
      and (self.remote == nil or (self.remote == from))
      and (from ~= self._last_from
             or (from == self._last_from
                   and seq_id ~= self._last_seq_received))
    then
      return table.unpack(packet)
    elseif kind == nil then
      return nil
    end
  end
end

function NetStream:recvfrom(timeout)
  local packet = { self:recvloop(timeout) }
  local kind, to, from, port, distance, seq_id, reply_port = table.unpack(packet)
  local body = sneaky.subtable(packet, 8)

  if kind == "modem_message" then
    self:on_receive(table.unpack(packet))
    return body[1], from, table.unpack(sneaky.subtable(body, 2))
  else
    return nil, "timeout"
  end
end

function NetStream:on_receive(kind, to, from, port, distance, seq_id, reply_port, ...)
  self._last_distance = distance
  self._last_seq_received = seq_id
  self._last_from = from
  self._last_time = computer.uptime()
  return self
end

function NetStream:getLastDistance()
  return self._last_distance or 0
end

function NetStream:alive()
  return (computer.uptime() <= (self._last_time + self.ttl)) and not self:closed()
end

function NetStream:recv(timeout)
  local packet = {self:recvfrom(timeout)}
  return packet[1], table.unpack(sneaky.subtable(packet, 3))
end

function NetStream:inc_seq()
  self._next_seq_id = self._next_seq_id + 1
  return self._next_seq_id
end

function NetStream:send(...)
  if self.remote then
    self.modem.send(self.remote, self.port, self:inc_seq(), self.src_port, ...)
  else
    self.modem.broadcast(self.port, self:inc_seq(), self.src_port, ...)
  end

  return self
end

return NetStream
