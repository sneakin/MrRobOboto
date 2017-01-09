local sneaky = require("sneaky/util")
local Command = require("sneaky/command")
local serialization = require("serialization")

local MODES = sneaky.inverse({
  "replace",
  "keep",
  "substitute",
  "dryrun"
})

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Uses the debug card to fill a volume.",
    arguments = {
      x = Command.Argument.Integer({
          description = "X value to start scanning.",
          required = true
      }),
      y = Command.Argument.Integer({
          description = "Y value to start scanning.",
          required = true
      }),
      z = Command.Argument.Integer({
          description = "Z value to start scanning.",
          required = true
      }),
      w = Command.Argument.Integer({
          description = "Width(X) of the volume to scan.",
          required = true
      }),
      l = Command.Argument.Integer({
          description = "Length(Z) of the volume to scan.",
          required = true
      }),
      h = Command.Argument.Integer({
          description = "Height(Y) of the volume to scan.",
          required = true
      }),
      block = {
        description = "The block ID or name to use for the fill.",
        default = "minecraft:air",
        required = true
      },
      metadata = Command.Argument.Integer({
        description = "The block's metadata.",
        default = 0,
        required = true
      }),
      nbt = {
        description = "The blocks' tile NBT data.",
        parse_value = function(value)
          serialization.unserialize(value)
        end
      },
      mode = {
        description = "Controls how existing blocks are treated. Valid values: " .. sneaky.join(sneaky.keys_list(MODES)),
        default = "replace",
        validate = function(value)
          return MODES[value] ~= nil
        end
      },
      replacing = {
        description = "The type of block to substitute.",
        default = "minecraft:air"
      }
    },
    run = function(options, args)
      local vec3d = require("vec3d")
      local rob_world = sneaky.reload("rob/world")

      local component = require("component")
      local dc = component.debug
      local world = dc.getWorld()

      local replacing_id
      if options.mode == "substitute" then
        replacing_id = rob_world.getBlockData(options.replacing).id
      end

      local origin = vec3d:new(options.x, options.y, options.z)
      local volume = vec3d:new(options.w, options.h, options.l)

      print(options.x, options.y, options.z)
      print(options.w, options.h, options.l)

      function log(s)
        io.stderr:write(s .. "\n")
      end

      function update_nbt(x, y, z, block, new_nbt, origin, volume)
        local updater = rob_world.BlockMetadata.blocks[block].nbt_updater
        if updater then
          local nbt = world.getTileNBT(x, y, z)
          -- nbt.value.x.value = x
          -- nbt.value.y.value = y
          -- nbt.value.z.value = z
          nbt = updater(nbt, new_nbt, vec3d:new(), volume, origin)
          print(serialize.serialize(nbt))
          world.setTileNBT(x, y, z, nbt)
        end
      end

      function replace_block(x, y, z)
        world.setBlock(x, y, z, options.block, options.metadata)
        if options.nbt then
          update_nbt(x, y, z, block, origin, volume)
        end
      end

      function substitute_block(x, y, z, block)
        if world.getBlockId(x, y, z) == (block or replacing_id) then
          return replace_block(x, y, z)
        end
      end

      function keep_block(x, y, z)
        substitute_block(x, y, z, "minecraft:air")
      end

      function dryrun_block(x, y, z)
        print(x, y, z, options.block, options.metadata, options.nbt)
      end

      local MODE_FUN = {
        replace = replace_block,
        keep = keep_block,
        substitute = substitute_block,
        dryrun = dryrun_block
      }

      local set_block = assert(MODE_FUN[options.mode], "invalid mode")

      for y = options.y, options.y + options.h - 1 do
        log("Plane " .. (y - options.y + 1) .. "/" .. options.h)

        for z = options.z, options.z + options.l - 1 do
          if options.w > 80 then
            log("Column " .. (z - options.z + 1) .. "/" .. options.l)
          end
          
          for x = options.x, options.x + options.w - 1 do
            set_block(x, y, z)
            io.stderr:write(".")
          end
          
          io.stderr:write("\n")
        end
      end
    end
})
