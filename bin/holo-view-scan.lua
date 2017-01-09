local sneaky = require("sneaky/util")
local Command = require("sneaky/command")
local vec3d = require("vec3d")

local Holo = {
  MAX_SIZE = vec3d:new(48, 32, 48)
}

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Holographically projects a scan.",
    arguments = {
      tx = Command.Argument.Integer({
          description = "Amount to translate the scan by along the X axis.",
          default = 0
      }),
      ty = Command.Argument.Integer({
          description = "Amount to translate the scan by along the Y axis.",
          default = 0
      }),
      tz = Command.Argument.Integer({
          description = "Amount to translate the scan by along the Z axis.",
          default = 0
      })
    },
    run = function(options, args)
      local vec3d = require("vec3d")
      local rob_world = require("rob/world")
      local colors = require("sneaky/colors")
      local component = require("component")
      local holo = component.hologram

      local unitv = vec3d:new(1, 1, 1)
      local translation = unitv - vec3d:new(options.tx, options.ty, options.tz)

      holo.clear()

      local f = io.stdin
      local line
      
      local original_origin = f:read()
      local stats = f:read()
      local counter = 0
      
      repeat
        repeat
          line = f:read()
        until line == nil or string.sub(line, 1, 2) ~= "--"

        if line == nil then
          break
        end

        local m = string.gmatch(line, "([^ \t]+)")
        local ox = tonumber(m())
        local oy = tonumber(m())
        local oz = tonumber(m())
        local meta_string = m()
        local block = tonumber(m())
        local meta = tonumber(m()) or 0
        -- m = string.gmatch(line, "\t({.*})$")
        -- local raw_nbt = m()
        -- local nbt = serialize.unserialize(raw_nbt or "nil")

        local p = vec3d:new(ox, oy, oz) + translation
        local color = 0

        if p.x > 0 and p.x <= Holo.MAX_SIZE.x
          and p.y > 0 and p.y <= Holo.MAX_SIZE.y
          and p.z > 0 and p.z <= Holo.MAX_SIZE.z
        then
          if block > 0 then
            color = 2
            
            print(p, block, meta_string)
            local _, bd = rob_world.getBlockDataById(block)
            if bd then
              if bd.name == "minecraft:water" then
                color = 3
              elseif string.match(bd.name, "redstone") or string.match(bd.name, "command") then
                color = 1
              end
            else
              io.stderr:write("Unknown block: " .. block)
            end
          end
          
          holo.set(p.x, p.y, p.z, color)

          counter = counter + 1
        end

        if (counter % 256) == 0 then
          os.sleep(1)
        end
      until line == nil
    end
})
