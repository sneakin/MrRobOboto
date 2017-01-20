local event = require("event")
local sides = require("sides")
local palette = require("sneaky/colors")
local component = require("component")
local modem = component.modem

local DRONE_PORT = 2
local TIMEOUT = 8

modem.open(DRONE_PORT)

local args = {...}
if args[1] == "pull" then
  repeat
    ev = { event.pull(TIMEOUT, "modem_message") }
    print(table.unpack(ev))
  until #ev == 0
elseif args[1] then
  modem.broadcast(DRONE_PORT, table.unpack(args))
  print(event.pull(TIMEOUT, "modem_message"))
else
  modem.broadcast(DRONE_PORT, "msg", "IT WORKS")
  print(event.pull(TIMEOUT, "modem_message"))
  modem.broadcast(DRONE_PORT, "drone", "light_color", palette.instance32:rand())
  print(event.pull(TIMEOUT, "modem_message"))
  os.sleep(1)
  modem.broadcast(DRONE_PORT, "status")
  print(event.pull(TIMEOUT, "modem_message"))
  modem.broadcast(DRONE_PORT, "eval", "return 2 + 3, 'hello'")
  print(event.pull(TIMEOUT, "modem_message"))
  modem.broadcast(DRONE_PORT, "drone", "detect", sides.down)
  print(event.pull(TIMEOUT, "modem_message"))
  modem.broadcast(DRONE_PORT, "fly", 0, 10, 0)
  print(event.pull(TIMEOUT, "modem_message"))
  modem.broadcast(DRONE_PORT, "fly", 0, -10, 0)
  print(event.pull(TIMEOUT, "modem_message"))
  modem.broadcast(DRONE_PORT, "eval", "return drone.getStatusText()")
  print(event.pull(TIMEOUT, "modem_message"))
  modem.broadcast(DRONE_PORT, "shutdown")
  print(event.pull(TIMEOUT, "modem_message"))
  print(event.pull(TIMEOUT, "modem_message"))
end

modem.close(DRONE_PORT)
