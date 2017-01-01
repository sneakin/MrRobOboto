local Command = require("sneaky/command")
local sneaky = require("sneaky/util")
local component = require("component")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Controls a Computronics Colorful Lamp.",
    usage = "brightness_or_red [green [blue]]",
    required_values = 1,
    arguments = {
      lamp = {
        description = "[Short] address of the lamp to change. Defaults to all."
      },
      dryrun = {
        description = "Do not actually change the lights.",
        boolean = true,
        default = false
      },
      info = {
        description = "Print list of lamps.",
        aborts = true,
        abort_message = function(cmd)
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

      local lamps = {}
      if options.lamp then
        local full = component.get(options.lamp)
        if full then
          table.insert(lamps, full)
        else
          error("No such lamp.")
        end
      else
        for addr, name in component.list() do
          if name == "colorful_lamp" then
            table.insert(lamps, addr)
          end
        end
      end

      local red = tonumber(args[1] or 0)
      local green = tonumber(args[2] or red)
      local blue = tonumber(args[3] or red)
      color = bits.bor(bits.lshift(bits.rshift(red, 2), 10),
                       bits.lshift(bits.rshift(green, 2), 5),
                       bits.lshift(bits.rshift(blue, 2), 0))

      if color then
        print("Setting color to " .. color)
      end

      for n, addr in ipairs(lamps) do
        print("  " .. addr)
        local light = component.proxy(addr)
        if not options.dryrun and color then
          light.setLampColor(color)
        end
      end
      
      return 0
    end
})
