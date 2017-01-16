local sneaky = require("sneaky/util")
local event = require("event")
local EffectsMap = require("net/nano_machines/effects_map")

local nano = {}

function nano:new(modem, port, timeout)
  local i = sneaky.class(self, { modem = modem,
                                 port = 1,
                                 timeout = timeout or 1,
                                 effects_map = EffectsMap:new(),
                                 cooling_down = 0
  })
  i:setResponsePort(port or 1)
  return i
end

function nano:send(...)
  if self.cooling_down > os.time() then
    os.sleep(self.timeout)
  end
  
  self.modem.broadcast(self.port, "nanomachines", ...)
  self.cooling_down = os.time() + 100
  
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

function nano:getStats()
  local health, max_health = self:getHealth()
  local hunger, max_hunger = self:getHunger()
  local power, max_power = self:getPowerState()

  return {
    power = (power or (0/0)) / (max_power or 100000),
    health = (health or (0/0)) / (max_health or 20),
    hunger = (hunger or (0/0)) / (max_hunger or 20),
    experience = self:getExperience()
  }
end

function nano:fuzz(at_one_time, timeout)
  timeout = timeout or 1
  local count = self:getTotalInputCount()
  local ranges = {}
  local safe_count = self:getSafeActiveInputs() or 2

  at_one_time = at_one_time or safe_count

  io.stderr:write("Turning off all " .. tostring(count) .. " inputs\n")
  self:setAll(nil)
  
  io.stderr:write("Generating permutations...\n")
  for i = 1, at_one_time do
    table.insert(ranges, sneaky.range(0, count, 1))
  end

  local perm_f = sneaky.permute(table.unpack(ranges))
  local inputs = {perm_f()}

  io.stderr:write("Here we go...\n")
  while inputs[1] do
    for _, i in ipairs(inputs) do
      if i ~= 0 then
        self:setInput(i, true)
      end
    end

    local stats = self:getStats()
    local effects = self:getActiveEffects()
    os.sleep(2)
    local new_stats = self:getStats()
    local diff = {}
    for i, stat in pairs(stats) do
      local delta = new_stats[i] - stats[i]
      if delta ~= 0 then
        diff[i] = delta
      end
    end
    print(serialization.serialize(inputs), effects, serialization.serialize(diff))
    if effects ~= "{}" then
      self.effects_map:add(sneaky.ifind(inputs, function(_, n) return n ~= 0 end),
                           self:parse_effects(effects),
                           diff)
    end

    for _, i in ipairs(inputs) do
      if i ~= 0 then
        self:setInput(i, false)
      end
    end

    if new_stats.health < 0.1 then
      print("HEALTH WARNING. Pausing...")
      io.stdin:read()
    end
    
    inputs = { perm_f() }
  end
end

function nano:parse_effects(str)
  local m = string.match(str, "{(.*)}")
  assert(m, "invalid effects string")
  return sneaky.reduce(string.gmatch(m, "([^,]+)"),
                       {},
                       function(a, v)
                         table.insert(a, v)
                         return a
  end)
end

return nano
