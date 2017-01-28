local sneaky = require("sneaky/util")
local Command = require("sneaky/command")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Authorizes robots to access the site.",
    arguments = {
      list = {
        boolean = true,
        default = nil
      }
    },
    run = function(options, args)
      local Site = require("rob/site")
      local site = Site.instance()

      function prompt(msg)
        io.stdout:write(msg .. " ")
        local line = io.stdin:read()
        return sneaky.trim(line)
      end

      print("Seen robots:")
      print("  ", "Address", "Distance", "Last Seen")
      for addr, robot in site:unauthorized_robots() do
        print("  ", addr, robot.signal_strength, robot.last_seen)
      end

      if not options.list then
        for addr, robot in site:unauthorized_robots() do
          local ans = prompt("Authorize " .. addr .. "?")
          if string.sub(ans, 1, 1) == "y" then
            local name
            repeat
              name = prompt("What do you want to name this robot?")
            until name ~= ""
            
            site:bless_robot(name, addr, robot.computer_addr, robot.robot_addr)
          end
        end
      end
    end
})
