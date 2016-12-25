-- Remote shell daemon
-- Allows local shell commands to run remotely
-- No security

-- Usage: rshd [port] [PATH]

-- todo move towards more of a job server:
--   create a job
--   poll a specific job
--   write to a specific job
--   check status of job
--   kill job

local NetServer = require("net/server")
local sneaky = require("sneaky/util")
local shell = require("shell")

local component = require("component")
local modem = component.modem

local args = {...}
local port = tonumber(args[1] or 23)
local path = args[2]

if path then
  shell.setPath(path)
end

local server = NetServer:listen(modem, port, function(stream, cmd, ...)
  local full_cmd = sneaky.join({cmd, ...})
  print("Executing '" .. full_cmd .. "' for " .. tostring(stream))
  local output = io.popen(full_cmd)
  if output then
    local inline, outline
    repeat
      inline = stream:recv(1)
      if inline then
        print(tostring(stream) .. ">", inline)
        output:write(inline)
      end

      outline = output:read()
      print(tostring(stream) .. "<", outline)
      stream:send(true, outline)
    until inline == nil and outline == nil

    output:close()
  else
    stream:send(nil, "not-found")
  end

  print(tostring(stream) .. ">EOF\n")
end)

-- server:loop()
print("rshd listening on " .. port)
server:background()