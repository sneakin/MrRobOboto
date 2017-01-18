local sneaky = require("sneaky/util")
local Command = require("sneaky/command")
local sides = require("sides")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Turns a computer off if no redstone signal is supplied while enabling wake on redstone.",
    long_help = "To build a kiosk, a pressure plate will need to be wired to a computer with a Redstone card and a Redstone switchable power connection. The Redstone wire from the pressure plate needs power one side of the computer while the computer is on while at the same time ensuring power is connected. When the pressure plate is unpowered, the computer will detect the lack of Redstone signal and turn off. Cutting the power is more of a safety measure.",
    arguments = {
      threshold = Command.Argument.Integer({
          description = "The redstone signal's strength to trigger a change.",
          default = 1
      }),
      side = Command.Argument.Side({
          description = "Side to watch for redstone changes. Defaults to all."
      }),
      kill = {
        description = "Kill the last installed daemon.",
        boolean = true,
        default = nil
      },
      pid = {
        description = "Path to the file to store the event listener ID.",
        default = "/tmp/kiosk-powerd.pid"
      }
    },
    run = function(options, args)
      local event = require("event")
      local computer = require("computer")
      local fs = require("filesystem")
      local pid = require("sneaky/pid")
      local component = require("component")
      local rs = component.redstone

      function kill(pid_file)
        local pid = pid.read(options.pid)
        if pid then
          print("Killing listener " .. pid)
          event.cancel(pid)
          fs.remove(options.pid)
        end
      end

      if pid.exists(options.pid) then
        kill(options.pid)
      end

      if not options.kill then
        print("Setting threshold to " .. options.threshold .. " on side " .. (options.side or "all") .. ".")
        
        rs.setWakeThreshold(options.threshold)

        local state = "waiting"
        local timer
        
        local listener = event.listen("redstone_changed", function(_, entity, side, old_value, new_value)
                                        if timer
                                          and (not options.side or side == options.side)
                                          and new_value >= options.threshold
                                        then
                                          print("Shutdown canceled.")
                                          event.cancel(timer)
                                        elseif
                                          (not options.side or side == options.side)
                                          and new_value < options.threshold
                                        then
                                          print("Shutting down in five...")
                                          timer = event.timer(5, computer.shutdown)
                                        end
        end)

        if listener then
          pid.write(options.pid, listener)
          print("Ok", listener)
        else
          print("Error")
        end
      end
    end
})
