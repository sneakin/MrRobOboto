-- Remote shell client

-- Usage: rsh host[:port] cmd [arguments...]

local NetStream = require("net/stream")
local component = require("component")
local modem = component.modem

local args = {...}
local host = args[1]
local port = 23
local cmd = args[2]
local arg1 = args[3]

if host == "0" then
  host = nil
end

local client = NetStream:new(modem, host, port)

client:send(cmd, arg1)

local ok, line

repeat
  ok, line = client:recv(10)
  if ok and line then
    print(line)
  elseif not ok then
    print(ok, line)
    break
  end
until line == nil

client:close()
