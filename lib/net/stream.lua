local event = require("event")
local Net = require("net")

local NetStream = {}

function NetStream:new(modem, remote, port, src_port)
  local e = {
    modem = modem,
    port = port,
    remote = remote,
    src_port = src_port or Net.random_port(modem)
  }
  setmetatable(e, self)
  self.__index = self

  e:init()

  return e
end

function NetStream:__tostring()
  return (self.remote or "broadcast") .. ":" .. self.port
end

function NetStream:init()
  self.modem.open(self.src_port)
  assert(self.modem.isOpen(self.src_port))
end

function NetStream:close()
  self.modem.close(self.src_port)
end

function NetStream:recv(timeout)
  local packet = { event.pull(timeout, "modem_message", nil, self.remote, self.src_port) }
  local type, to, from, port, distance, reply_port, body, a1, a2, a3 = table.unpack(packet)

  if type == "modem_message" then
    return body, a1, a2, a3
  end
end

function NetStream:send(...)
  if self.remote then
    self.modem.send(self.remote, self.port, self.src_port, ...)
  else
    self.modem.broadcast(self.port, self.src_port, ...)
  end
end

return NetStream
