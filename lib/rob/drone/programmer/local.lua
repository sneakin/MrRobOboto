local sneaky = require("sneaky/util")
local component = require("component")
local LocalProgrammer = {}

function LocalProgrammer:new()
  return sneaky.class(self, { })
end

function LocalProgrammer:eeprom()
  return component.eeprom
end

function LocalProgrammer:set(data)
  self:eeprom().set(data)
end

function LocalProgrammer:set_data(data)
  self:eeprom().setData(data)
end

function LocalProgrammer:set_label(label)
  self:eeprom().setLabel(label)
end

function LocalProgrammer:stop()
end

return LocalProgrammer
