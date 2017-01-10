-- Remote shell client

-- Usage: rsh host[:port] cmd [arguments...]

local Command = require("sneaky/command")
local sneaky = require("sneaky/util")
local rsh = require("net/rsh")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "RemoteSHell client",
    long_help = "rsh runs shell commands on a running rshd. The syntax is that for io.popen.",
    usage = "command [cmd_args...]",
    allow_unknown = true,
    arguments = {
      port = Command.Argument.Integer({
          description = "Port on which to send messages.",
          default = rsh.DEFAULT_PORT
      }),
      host = {
        description = "Host on which to run a shell command. Defaults to broadcasting."
      },
      timeout = Command.Argument.Integer({
          description = "Number of seconds to wait for a response.",
          default = 3
      })
    },
    run = function(options, args)
      local component = require("component")
      local modem = component.modem

      local host = options.host
      local port = options.port
      local cmd = args[1]
      local cmd_args = sneaky.subtable(args, 2)

      local client = rsh:new(modem, host, port)

      io.stderr:write("Executing " .. sneaky.join({cmd, table.unpack(cmd_args)}) .. "\n")
      client:execute(cmd, table.unpack(cmd_args))

      local ok, line, from

      repeat
        ok, from, line = client:poll(options.timeout)
        if ok and line then
          if options.host then
            print(line)
          else
            print(tostring(from) .. ">", line)
          end
        elseif not ok then
          io.stderr:write("Error: " .. tostring(ok) .. ": " .. tostring(line))
          break
        end
      until not ok

      client:close()
    end
})
