local sneaky = require("sneaky/util")
local component = require("component")
local Stream = require("net/stream")

local RemoteProgrammer = {}

function RemoteProgrammer:new(port, address, modem)
  local i = sneaky.class(self, { _address = address,
                              _port = port or 3,
                              _modem = modem or component.modem,
  })
  i:init()
  return i
end

function RemoteProgrammer:__gc()
  self:stop()
end

function RemoteProgrammer:init()
  self._programmer = Stream:new(self._modem, self._address, self._port)
  self:init_programmer()
end

function RemoteProgrammer:programmer_firmware()
  return sneaky.read_file(sneaky.pathjoin(sneaky.root, "..", "firmware", "programmer.lua"))
end

function RemoteProgrammer:call(...)
  self._programmer:send(...)
  local packet = { self._programmer:recv() }
  return table.unpack(packet)
end

function RemoteProgrammer:set(data)
  local ok, result = self:call("load", data)
  print(ok, result)
  assert(ok, result)

  local ok, result = self:call("set")
  print(ok, result)
  assert(ok, result)
  
  return self
end

function RemoteProgrammer:set_data(data)
  local ok, result = self:call("load", data)
  assert(ok, result)

  local ok, result = self:call("set_data")
  assert(ok, result)

  return self
end

function RemoteProgrammer:set_label(label)
  local ok, result = self:call("set_label", label)
  assert(ok, result)

  return self
end

function RemoteProgrammer:stop()
  self._programmer:send("shutdown", true)
  --local ok, result = self._programmer:recv()
  --assert(ok, result)
  return self
end

function RemoteProgrammer:init_programmer()
  local kind, ok, addr, app = self:call("disco")

  if ok and app == "netlua" then
    local fw = self:programmer_firmware()
    print("Sending programmer firmware " .. fw:len())
    local ok, result = self:call("load", fw)
    assert(ok, result)
    local ok, result = self:call("eval", fw)
    assert(ok, result)
  end

  return self
end

return RemoteProgrammer
