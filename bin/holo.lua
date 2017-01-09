local sneaky = require("sneaky/util")
local Command = require("sneaky/command")
local vec3d = require("vec3d")
local colors = require("sneaky/colors")

function parse_color(palette, value)
  local c = palette:get(value)
  if c then
    return c
  end

  local r, g, b = string.match(value, "([0-9]+),([0-9]+),([0-9]+)")
  if r and g and b then
    return palette:rgb(r, g, b)
  end
end

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Adjusts parameters of the holographic projector.",
    arguments = {
      tx = Command.Argument.Float({
          description = "Amount to translate by along the X axis."
      }),
      ty = Command.Argument.Float({
          description = "Amount to translate by along the Y axis."
      }),
      tz = Command.Argument.Float({
          description = "Amount to translate by along the Z axis."
      }),
      scale = Command.Argument.Float({
          description = "Amount to scale the hologram."
      }),
      c1 = {
        description = "The first color in the palette."
      },
      c2 = {
        description = "The second color in the palette."
      },
      c3 = {
        description = "The third color in the palette."
      },
      clear = {
        description = "Clear the holographic projection.",
        boolean = true
      }
    },
    run = function(options, args)
      local vec3d = require("vec3d")
      local colors = require("sneaky/colors")
      local component = require("component")
      local holo = component.hologram

      if options.clear then
        holo.clear()
      end

      --- translation
      local translation = vec3d:new(holo.getTranslation())
      for a, b in pairs({ x = "tx", y = "ty", z = "tz" }) do
        if options[b] then
          translation[a] = options[b]
        end
      end

      holo.setTranslation(translation.x, translation.y, translation.z)      

      --- scale
      if options.scale then
        holo.setScale(options.scale)
      end

      --- color
      for n, color in ipairs({ options.c1, options.c2, options.c3 }) do
        if color then
          local c = parse_color(colors.instance32, color)
          if c then
            holo.setPaletteColor(n, c)
          else
            error("Invalid color: " .. color)
          end
        end
      end
    end
})
