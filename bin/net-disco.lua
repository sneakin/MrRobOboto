local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Gathers a list of other nodes on the network.",
    long_help = "RSHD must be running and net-addr present on the nodes to receive the request.",
    arguments = {
      count = Command.Argument.Integer({
          description = "Number of broadcasts to make.",
          default = 3
      }),
      timeout = Command.Argument.Integer({
          description = "Time to wait for replies.",
          default = 10
      })
    },
    run = function(options, args)
      local rsh = require("net/rsh")
      local component = require("component")
      local modem = component.modem

      local times = options.count

      local nodes = {}
      local client = rsh:new(modem)

      for i = 1, times do
        print("(" .. tostring(i) .. "/" .. tostring(times) .. ") Querying...")
        client:execute("net-addr")

        local ok, line, from

        repeat
          ok, from, line = client:poll(options.timeout)
          if ok and line then
            nodes[from] = client:getLastDistance()
          end
        until not ok

        os.sleep(1)
      end

      for address, dist in pairs(nodes) do
        print(address, dist)
      end

      return 0
    end
})
