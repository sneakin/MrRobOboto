local sneaky = require("sneaky/util")
local event = require("event")
local nano = {}

function nano:new(modem, port, timeout)
  local i = sneaky.class(self, { modem = modem,
                                 port = 1,
                                 timeout = timeout or 1
  })
  i:setResponsePort(port or 1)
  return i
end

function nano:send(...)
  self.modem.broadcast(self.port, "nanomachines", ...)
  return self
end

function nano:call(response, ...)
  self:send(...)
  local packet = { event.pull(self.timeout, "modem_message", nil, nil, self.port, nil, "nanomachines", response) }
  --local type, to, from, port, distance = table.unpack(packet)
  return table.unpack(sneaky.subtable(packet, 8))
end

function nano:setResponsePort(port)
  self:send("setResponsePort", port)
  self.modem.close(self.port)
  self.modem.open(port)
  self.port = port
  return self
end

nano.COMMANDS = {
  setInput = 2,
  saveConfiguration = 0
}

nano.REQUESTS = {
  getPowerState = "power",
  getHealth = "health",
  getHunger = "hunger",
  getAge = "age",
  --getName = "name", -- FIXME once OC fixes this to not crash
  getExperience = "experience",
  getTotalInputCount = "totalInputCount",
  getSafeActiveInputs = "safeActiveInputs",
  getMaxActiveInputs = "maxActiveInputs",
  getInput = { "input", 1 },
  getActiveEffects = "effects"
}

for cmd, num_args in pairs(nano.COMMANDS) do
  nano[cmd] = function(self, ...)
    assert(#{...} >= num_args, "too few arguments: " .. tostring(num_args) .. " wanted")
    return self:send(cmd, ...)
  end
end

for request, response in pairs(nano.REQUESTS) do
  local num_args = 0

  if type(response) == "table" then
    response, num_args = table.unpack(response)
  end
  
  nano[request] = function(self, ...)
    assert(#{...} >= num_args, "too few arguments: " .. tostring(num_args) .. " wanted")
    return self:call(response, request, ...)
  end
end

function nano:setAll(on)
  for i = 1, self:getTotalInputCount() do
    self:setInput(i, on or false)
  end

  return self
end

function nano:fuzz(timeout)
  timeout = timeout or 3
  local count = self:getTotalInputCount()

  for i = 1, count do
    self:setInput(i, true)
    os.sleep(timeout)
    
    for j = 1,  count do
      if i ~= j then
        self:setInput(j, true)
        os.sleep(timeout)
        print(i, j, self:getActiveEffects())
        self:setInput(j, false)
        os.sleep(timeout)
      end
    end
    
    self:setInput(i, false)
    os.sleep(timeout)
  end
end

return nano
