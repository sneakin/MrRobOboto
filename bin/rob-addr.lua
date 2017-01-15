local component = require("component")

print("computer", component.computer.address)
if component.isAvailable("robot") then
  print("robot", component.robot.address, component.robot.isRunning == nil)
end
if component.isAvailable("modem") then
  print("modem", component.modem.address, component.modem.isWireless())
end
