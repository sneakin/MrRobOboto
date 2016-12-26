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

local Command = require("sneaky/command")
local sneaky = require("sneaky/util")
local rsh = require("net/rsh")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "RemoteSHell Daemon",
    long_help = "RSHD runs shell commands that are sent to the specified networking port. Completely insecure.",
    arguments = {
      port = Command.Argument.Integer({
          description = "Port to listen for messages.",
          default = rsh.DEFAULT_PORT
      }),
      path = {
        description = "Restrict commands to this $PATH."
      }
    },
    run = function(options, args)
      local NetServer = require("net/server")
      local shell = require("shell")

      local component = require("component")
      local modem = component.modem

      local port = options.port
      local path = options.path

      if path then
        shell.setPath(path)
      end

      function rshd_handle(stream, cmd, ...)
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
      end
      
      local server = NetServer:listen(modem, port, rshd_handle)

      -- server:loop()
      print("rshd listening on " .. port)
      server:background()
    end
})
