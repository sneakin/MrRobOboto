local sneaky = require("sneaky/util")
local Command = require("sneaky/command")
local rob_world = require("rob/world")
local serialize = require("serialization")

-- todo now the /fill command is off by getting its dimensions adjusted
--   per command adjusting
--   only adjust in the build...check against min and min+dim, could still catch coords on builds near the origin
-- todo simplify the json(?) value,id pairs when saving
-- fixme flip powered levers post build

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Uses the debug card to build using op-scanner's output",
    arguments = {
      x = Command.Argument.Integer({
          description = "X value to start building."
      }),
      y = Command.Argument.Integer({
          description = "Y value to start building."
      }),
      z = Command.Argument.Integer({
          description = "Z value to start building."
      }),
      dry_run = {
        description = "Do not build anything.",
        boolean = true,
        default = false
      }
    },
    run = function(options, args)
      local vec3d = require("vec3d")
      local component = require("component")
      local dc = component.debug
      local world = dc.getWorld()

      -- todo build water and lava last, collect and then build
      -- signs updated <25%
      -- command blocks had no commands, and will need coordinates adjusted
      
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

      function set_block(x, y, z, meta_string, block, meta, nbt, origin, volume)
        print(x, y, z, block, meta, meta_string)
        
        if not options.dry_run then
          world.setBlock(x, y, z, 0, 0)
          world.setBlock(x, y, z, block, meta)
          if nbt then
            local kind, _ = rob_world.BlockMetadata.parse(meta_string)
            update_nbt(x, y, z, kind, nbt, origin, volume)
          end
        end
      end

      local f = io.stdin
      if args[1] then
        f = io.open(args[1], "r")
        if not f then
          error("Unable to open file: " .. tostring(args[1]))
        end
      end
      
      local second_pass = {}
      local fluid_pass = {}
      
      local origin = vec3d:new(options.x, options.y, options.z)
      
      local original_origin = f:read()
      local stats = f:read()
      local m = string.gmatch(stats, "([^ \t]+)")
      local width = m()
      local height = m()
      local length = m()
      local volume = vec3d:new(tonumber(width), tonumber(height), tonumber(length))

      print("Size:", width, height, length)

      local line
      local line_num = 0
      
      repeat
        repeat
          line = f:read()
          line_num = line_num + 1
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
        m = string.gmatch(line, "\t({.*})$")
        local raw_nbt = m()
        local nbt = serialize.unserialize(raw_nbt or "nil")
        local dx = ox + options.x
        local dy = oy + options.y
        local dz = oz + options.z

        if block == rob_world.BlockMetadata.blocks["minecraft:torch"].id
          or block == rob_world.BlockMetadata.blocks["minecraft:redstone_torch"].id
          or block == rob_world.BlockMetadata.blocks["minecraft:unlit_redstone_torch"].id
          or block == rob_world.BlockMetadata.blocks["minecraft:wall_sign"].id
          or block == rob_world.BlockMetadata.blocks["minecraft:lever"].id
          or block == rob_world.BlockMetadata.blocks["minecraft:stone_button"].id
          or block == rob_world.BlockMetadata.blocks["minecraft:wooden_button"].id
        then
          table.insert(second_pass, { dx, dy, dz, meta_string, block, meta, nbt, origin, volume })
        elseif block == rob_world.BlockMetadata.blocks["minecraft:water"].id
          or block == rob_world.BlockMetadata.blocks["minecraft:lava"].id
        then
          table.insert(fluid_pass, { dx, dy, dz, meta_string, block, meta, nbt, origin, volume })
        else
          set_block(dx, dy, dz, meta_string, block, meta, nbt, origin, volume)
        end
      until line == nil

      if not options.dry_run then
        for _, block in ipairs(second_pass) do
          set_block(table.unpack(block))
        end

        for _, block in ipairs(fluid_pass) do
          set_block(table.unpack(block))
        end
      end
      
      f:close()
    end
})
