local Net = require("net")
local component = require("component")
local modem = component.modem

for i = 1, Net.MAX_PORT do
  print(i, modem.isOpen(i))
end
