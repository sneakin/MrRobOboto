-- Remote shell daemon
-- Allows local shell commands to run remotely
-- No security

-- Usage: rshd [port] [PATH]

local NetServer = require("net/server")
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
  print("Executing '" .. cmd .. "' for " .. tostring(stream))
  local output = io.popen(cmd)
  if output then
    local inline, outline
    repeat
      inline = stream:recv(1)
      if inline then
        print(">", inline)
        output:write(inline)
      end

      outline = output:read()
      print("<", outline)
      stream:send(true, outline)
    until inline == nil and outline == nil

    output:close()
  else
    stream:send(nil, "not-found")
  end

  print(">EOF\n")
end)

-- server:loop()
server:background()
