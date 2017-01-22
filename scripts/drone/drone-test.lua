local sneaky = require("sneaky/util")
local event = require("event")
local sides = require("sides")
local palette = require("sneaky/colors")
local component = require("component")
local modem = component.modem

local DRONE_PORT = tonumber(os.getenv("PORT") or 2)
local TIMEOUT = 8

function drone_call(...)
  modem.broadcast(DRONE_PORT, ...)
  return event.pull(TIMEOUT, "modem_message")
end

function print_drone_call(...)
  print(drone_call(...))
end

function print_events(kind)
  repeat
    ev = { event.pull(TIMEOUT, "modem_message") }
    print(table.unpack(ev))
  until #ev == 0
end  

modem.open(DRONE_PORT)

local args = {...}
if args[1] == "pull" then
  print_events("modem_message")
elseif args[1] then
  local cmd, args = args[1], sneaky.subtable(args, 2)
  if cmd == "fly" then
    args = sneaky.map(sneaky.pairs(args), function(n,v) return tonumber(v) end)
    print_drone_call(cmd, table.unpack(args))
    print_events("modem_message")
  elseif cmd == "load" and args[1] == nil then
    local data = io.read("*a")
    print_drone_call(cmd, data)
  else
    print_drone_call(cmd, table.unpack(args))
  end
else
  local calls = {
    { 1, "drone", "setStatusText", "IT WORKS" },
    { 1, "drone", "setLightColor", palette.instance32:rand() },
    { 0, "status" },
    { 0, "eval", "return 2 + 3, 'hello'" },
    { 0, "drone", "detect", sides.down },
    { 2, "fly", 0, 10, 0 },
    { 2, "fly", 0, -10, 0 },
    { 0, "eval", "return drone.getStatusText()" },
    { 0, "load", "return computer.energy(), computer.maxEnergy()" },
    { 0, "eval" },
    { 0, "load", "function abc() return 'def' end" },
    { 0, "eval" },
    { 0, "eval", "return abc()" },
    { 0, "eval", "no this will not work" },
    { 0, "logread" },
    { 0, "shutdown" }
  }
  for _, c in ipairs(calls) do
    print_drone_call(table.unpack(sneaky.subtable(c, 2)))
    if c[1] > 0 then
      os.sleep(c[1])
    end
  end

  print(event.pull(TIMEOUT, "modem_message"))
end

modem.close(DRONE_PORT)
