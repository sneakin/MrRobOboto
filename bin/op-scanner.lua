local sneaky = require("sneaky/util")
local Command = require("sneaky/command")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Uses the debug card to scan a volume printing out the blocks.",
    arguments = {
      x = Command.Argument.Integer({
          description = "X value to start scanning."
      }),
      y = Command.Argument.Integer({
          description = "Y value to start scanning."
      }),
      z = Command.Argument.Integer({
          description = "Z value to start scanning."
      }),
      w = Command.Argument.Integer({
          description = "Width(X) of the volume to scan.",
          default = 16
      }),
      l = Command.Argument.Integer({
          description = "Length(Z) of the volume to scan.",
          default = 16
      }),
      h = Command.Argument.Integer({
          description = "Height(Y) of the volume to scan.",
          default = 16
      }),
    },
    run = function(options, args)
      local serialize = require("serialization")
      local vec3d = require("vec3d")
      local rob_world = sneaky.reload("rob/world")

      local component = require("component")
      local dc = component.debug
      local world = dc.getWorld()

      local origin = vec3d:new(options.x, options.y, options.z)
      local volume = vec3d:new(options.w, options.h, options.l)
      
      print(options.x, options.y, options.z)
      print(options.w, options.h, options.l)

      function log(s)
        io.stderr:write(s .. "\n")
        print("-- " .. s)
      end

      for y = options.y, options.y + options.h - 1 do
        log("Plane " .. (y - options.y + 1) .. "/" .. options.h)

        for z = options.z, options.z + options.l - 1 do
          if options.w > 80 then
            log("Column " .. (z - options.z + 1) .. "/" .. options.l)
          end
          
          for x = options.x, options.x + options.w - 1 do
            local block = world.getBlockId(x, y, z)
            local meta = world.getMetadata(x, y, z)
            local kind, meta_table = rob_world.BlockMetadata.parse(meta)
            local nbt = world.getTileNBT(x, y, z)

            local nbt_saver = rob_world.BlockMetadata.blocks[kind].nbt_saver
            if nbt_saver then
              nbt = nbt_saver(nbt, origin, volume, vec3d:new())
            end
            
            print(x - options.x, y - options.y, z - options.z, meta, block, rob_world.BlockMetadata.tonumber(meta), serialize.serialize(nbt))
            io.stderr:write(".")
          end
          
          io.stderr:write("\n")
        end
      end

      log("EOF")
    end
})
