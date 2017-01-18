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
      }),
      clear = {
        description = "Do not clear prior to projecting.",
        boolean = true
      },
      verbose = {
        description = "Print out lines as they are read.",
        boolean = true
      },
      blue = {
        default = "minecraft:water"
      },
      red = {
        default = "redstone"
      }
    },
    run = function(options, args)
      local vec3d = require("vec3d")
      local rob_world = require("rob/world")
      local colors = require("sneaky/colors")
      local component = require("component")
      local holo = component.hologram

      local unitv = vec3d:new(1, 1, 1)
      local translation = unitv - vec3d:new(options.tx, options.ty, options.tz)

      if options.clear then
        holo.clear()
      end

      local f = io.stdin
      local line
      
      local original_origin = f:read()
      local stats = f:read()
      local counter = 0
      local line_num = 2
      
      repeat
        repeat
          line = f:read()
          line_num = line_num + 1
          if line and options.verbose then
            io.stderr:write(tostring(line_num) .. ": " .. line .. "\n")
          end
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

        if ox and oy and oz and block then
          local p = vec3d:new(ox, oy, oz) + translation
          local color = 0

          if p.x > 0 and p.x <= Holo.MAX_SIZE.x
            and p.y > 0 and p.y <= Holo.MAX_SIZE.y
            and p.z > 0 and p.z <= Holo.MAX_SIZE.z
          then
            if block > 0 then
              color = 2
              
              print(line_num, p, block, meta_string)
              local _, bd = rob_world.getBlockDataById(block)
              if bd then
                if string.match(bd.name, options.blue) then
                  color = 3
                elseif string.match(bd.name, options.red) then
                  color = 1
                end
              else
                io.stderr:write("Unknown block: " .. block)
              end
            end
            
            holo.set(p.x, p.y, p.z, color)

            counter = counter + 1
          end
        else
          io.stderr:write("Warning: trouble parsing line ", line_num)
        end

        os.sleep(0)
      until line == nil
    end
})
