local sneaky = require("sneaky/util")
local serialization = require("serialization")
local stream = require("net/stream")
local rpc = {
  DEFAULT_TIMEOUT = 3
}

function rpc:new(modem, remote, port, timeout)
  local i = sneaky.class(self, { timeout = timeout or rpc.DEFAULT_TIMEOUT })
  i:init(modem, remote, port)
  return i
end

function rpc:init(modem, remote, port)
  self.stream = stream:new(modem, remote, port)
end

function rpc:close()
  self.stream:close()
end

function rpc:pcall(...)
  self.stream:send(serialization.serialize({...}))
  local ok, result = self.stream:recv(self.timeout)
  if not ok then
    return nil, result or "no reply"
  end
  
  return true, table.unpack(serialization.unserialize(result))
end

function rpc:call(...)
  local result = { self:pcall(...) }
  if result[1] then
    return table.unpack(sneaky.subtable(result, 2))
  else
    error(table.unpack(sneaky.subtable(result, 2)))
  end
end

function rpc:mcall(...)
  local results = {}
  self.stream:send(serialization.serialize({...}))
  repeat
    local ok, from, result = self.stream:recvfrom(self.timeout)

    if ok then
      results[from] = table.unpack(serialization.unserialize(result))
    else
      break
    end
  until not ok

  return results
end


return rpc
