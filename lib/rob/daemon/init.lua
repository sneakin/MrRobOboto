local sneaky = require("sneaky/util")
local component = require("component")
local computer = require("computer")
local event = require("event")
local serialization = require("serialization")
local rpc = require("net/rpc/client")
local rob = require("rob")
local vec3d = require("vec3d")

local daemon = {
  DEFAULT_PORT = 59,
  DEFAULT_STATUS_INTERVAL = 30
}

function daemon:new(modem, port)
  local i = sneaky.class(self, {})
  i:init(modem, port)
  return i
end

function daemon:init(modem, port)
  self.modem = modem
  self.port = port
  self.broadcast_rpc = rpc:new(modem, nil, port)
  self._coordinators = {}

  self._status_handler = event.timer(daemon.DEFAULT_STATUS_INTERVAL,
                                     function()
                                       local ok, reason = pcall(self.tick, self)
                                       if not ok then
                                         io.stderr:write("Error sending status: " .. tostring(reason), "\n")
                                       end
                                     end,
                                     math.huge)

  self._mover_callback = rob.robot:add_callback(function(facing, offset, old_facing, doffset)
      self:send_status(old_facing, doffset)
  end)
  self:tick()
end

function daemon:stop()
  self.broadcast_rpc:close()
  if self._coordinator then
    self._coordinator:close()
  end
  if self._status_handler then
    event.cancel(self._status_handler)
  end
  if self._mover_callback then
    rob.robot:remove_callback(self._mover_callback)
  end
end

function daemon:tick()
  if self:is_coordinated() then
    self:send_status()

    if not self.name then
      rob.busy()
      self:find_whoami()
    elseif not self:been_located() then
      rob.busy()
      self:locate()
    else
      rob.cool()
    end
  else
    rob.notcool()
    self:find_coordinator()
  end
end

function daemon:is_coordinated()
  return self._coordinator ~= nil
end

function daemon:has_coordinator(addr)
  return sneaky.findFirst(self._coordinators,
                          function(n, c) return c.address == addr end)
end

function daemon:add_coordinator(name, addr, location, last_seen)
  table.insert(self._coordinators, {
                 name = name,
                 address = addr,
                 location = location,
                 last_seen = last_seen or os.time()
  })
  return self
end

function daemon:set_coordinator(address)
  if self._coordinator then
    self._coordinator:close()
  end
  
  self._coordinator = rpc:new(self.modem, address, self.port)
  io.stderr:write("Set coordinator to " .. tostring(address), "\n")
  
  return self
end

function daemon:pick_coordinator()
  assert(#self._coordinators > 0, "not enough coordinators")

  local iter = sneaky.pairsByValues(self._coordinators, function(a, b) return a.last_seen and b.last_seen and a.last_seen < b.last_seen end)
  local i, coord = iter()
  assert(coord ~= nil, "no coordinator found")

  self:set_coordinator(coord.address)

  return self
end

function daemon:find_coordinator()
  local coordinators = self.broadcast_rpc
    :mcall("disco", "secret")
  
  if coordinators then
    for addr, coord in pairs(coordinators) do
      io.stderr:write(tostring(addr) .. " replied with coordinator " .. tostring(coord.name) .. "@" .. tostring(coord.address) .. "\n")
      if not self:has_coordinator(coord.address) then
        self:add_coordinator(coord.node, coord.address, coord.location)
      end
    end

    if not self._coordinator then
      self:pick_coordinator()
    end
  else
    io.stderr:write("Awaiting coordination...\n")
  end
end

function daemon:been_located()
  return self._location ~= nil
end

function daemon:locate()
  self._location = true
end

function daemon:find_whoami()
  local ok, data = self.broadcast_rpc
    :call("whoami",
          "secret",
          component.computer.address,
          component.isAvailable("robot") and component.robot.address)

  if ok then
    self.name = data.name
    rob.facing(data.facing)
    local offset = vec3d:new(data.offset)
    rob.offset(offset)
    local origin = vec3d:new(data.origin)
    rob.origin(origin)
    
    io.stderr:write("I am " .. tostring(self.name) .. " according to " .. tostring(data.from) .. ".\n")
    io.stderr:write("I am at " .. tostring(offset) .. " + " .. tostring(origin) .. " facing " .. tostring(data.facing) .. ".\n")
  else
    io.stderr:write("whoami!? " .. tostring(data) .. "\n")
  end
end

function daemon:send_status(old_facing, doffset)
  local status = {
    energy = computer.energy(),
    max_energy = computer.maxEnergy(),
    facing = rob.facing(),
    offset = rob.offset(),
    doffset = doffset,
    origin = rob.origin()
  }
  io.stderr:write("Sending status: " .. serialization.serialize(status), "\n")
  local ok, reason = self._coordinator:call("robot_update", status)
  if not ok then
    io.stderr:write("Error sending status: " .. tostring(reason) .. "\n")
    self:close_coordinator()
  end
end

function daemon:close_coordinator()
  if self._coordinator then
    self._coordinator:close()
  end
  
  self._coordinator = nil
end

function daemon.start()
  if daemon.instance then
    daemon.stop()
  end

  daemon.instance = daemon:new(component.modem, daemon.DEFAULT_PORT)
  daemon.instance:start()
end

function daemon.stop()
  if daemon.instance then
    daemon.instance:stop()
    daemon.instance = nil
  end
end

return daemon
