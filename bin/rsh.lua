-- Remote shell client

-- Usage: rsh host[:port] cmd [arguments...]

local rsh = require("net/rsh")
local sneaky = require("sneaky/util")
local component = require("component")
local modem = component.modem

local args = {...}
local host = args[1]
local port = 23
local cmd = args[2]
local cmd_args = sneaky.subtable(args, 3)

if host == "0" then
  host = nil
end

local client = rsh:new(modem, host, port)

print("Executing " .. sneaky.join({cmd, table.unpack(cmd_args)}))
client:execute(cmd, table.unpack(cmd_args))

local ok, line, from

repeat
  ok, from, line = client:poll()
  if ok and line then
    print(tostring(from) .. ">", line)
  elseif not ok then
    print("Error", ok, line)
    break
  end
until not ok

client:close()
