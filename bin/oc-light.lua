local Command = require("sneaky/command")
local sneaky = require("sneaky/util")
local component = require("component")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Controls a Computronics Colorful Lamp.",
    usage = "brightness_or_red [green [blue]]",
    required_values = 1,
    arguments = {
      info = {
        description = "Print list of lamps.",
        aborts = true,
        abort_message = function(cmd)
          print("Lights:")
          for addr, name in component.list() do
            if name == "colorful_lamp" then
              local l = component.proxy(addr)
              print("  " .. addr .. " " .. l.getLampColor())
            end
          end
        end
      }
    },
    run = function(options, args)
      local bits = require("bit32")
      local brightness
      local color

      local red = tonumber(args[1] or 0)
      local green = tonumber(args[2] or red)
      local blue = tonumber(args[3] or red)
      color = bits.bor(bits.lshift(bits.rshift(red, 2), 10),
                       bits.lshift(bits.rshift(green, 2), 5),
                       bits.lshift(bits.rshift(blue, 2), 0))

      if color then
        print("Setting color to " .. color)
      end

      for addr, name in component.list() do
        if name == "colorful_lamp" then
          print("  " .. addr)
          local light = component.proxy(addr)
          if color then
            light.setLampColor(color)
          end
        end
      end

      return 0
    end
})
