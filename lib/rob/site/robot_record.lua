local sneaky = require("sneaky/util")
local vec3d = require("vec3d")
local RobotRecord = {}

function RobotRecord:new(name, modem_addr, computer_addr, robot_addr, last_seen, authorized, blessed)
  return sneaky.class(self, { name = name,
                              modem_addr = modem_addr,
                              computer_addr = computer_addr,
                              robot_addr = robot_addr,
                              last_seen = last_seen,
                              authorized = authorized,
                              blessed = nil,
                              energy = nil,
                              max_energy = nil,
                              signal_strength = nil,
                              offset = vec3d:new(),
                              facing = nil,
                              origin = nil
  })
end

function RobotRecord:update_stats(stats, signal_strength)
  self.last_seen = os.time()
  self.energy = stats.energy or self.energy
  self.max_energy = stats.max_energy or self.max_energy
  self.signal_strength = signal_strength
  self.offset = vec3d:new(stats.offset) or self.offset
  self.facing = stats.facing or self.facing
  self.origin = stats.origin or self.origin
  
  return self
end

function RobotRecord:to_table()
  return {
    name = self.name,
    modem_addr = self.modem_addr,
    computer_addr = self.computer_addr,
    robot_addr = self.robot_addr,
    last_seen = self.last_seen,
    authorized = self.authorized,
    blessed = self.blessed,
    energy = self.energy,
    max_energy = self.max_energy,
    signal_strength = self.signal_strength,
    facing = self.facing,
    offset = self.offset,
    origin = self.origin
  }
end

function RobotRecord:from_table(tbl)
  local i = sneaky.class(self, tbl)
  i.offset = vec3d:new(i.offset)
  i.origin = i.origin and vec3d:new(i.origin)
  return i
end

function RobotRecord:position()
  if self.origin then
    return self.origin + self.offset
  end
end

return RobotRecord
