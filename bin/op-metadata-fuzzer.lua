local sneaky = require("sneaky/util")
local Command = require("sneaky/command")

Command:define({...}, {
    description = "Sets the block at X, Y, Z incrementing the metadata value displaying what is returned. Useful for filling in the BlockData tables.",
    arguments = {
      x = Command.Argument.Integer({
          description = "X coordinate of the space to change."
      }),
      y = Command.Argument.Integer({
          description = "Y coordinate of the space to change."
      }),
      z = Command.Argument.Integer({
          description = "Z coordinate of the space to change."
      }),
      bits = Command.Argument.Integer({
          description = "Sets the maximum value of the metadata as a power of 2.",
          default = 4
      }),
      debug = {
        description = "Print more.",
        boolean = true,
        default = false
      },
      delay = Command.Argument.Integer({
          description = "Time between setting blocks.",
          default = 1
      })
    },
    run = function(options, args)
      local serialize = require("serialization")
      local rob_world = sneaky.reload("rob/world")

      local component = require("component")
      local dc = component.debug
      local world = dc.getWorld()

      if #args < 1 then
        error("No block[s] specified")
      end

      function set_block(x, y, z, block, metadata)
        world.setBlock(x, y, z, 0, 0)
        
        local ok, reason = pcall(world.setBlock, x, y, z, block, metadata)
        if not ok then
          print("Unable to set block to " .. block .. " " .. metadata)
        end
        return ok, reason
      end

      function changed_values(a, b)
        local changes = {}
        
        for ak, av in pairs(a) do
          if av ~= b[ak] then
            changes[ak] = b[ak]
          end
        end

        return changes
      end

      function try_block(block)
        set_block(options.x, options.y, options.z, block, 0)
        local block_id = world.getBlockId(options.x, options.y, options.z)
        local original_meta = world.getMetadata(options.x, options.y, options.z)
        local last_kind, last_meta = rob_world.BlockMetadata.parse(original_meta)
        local bits = {}

        if options.debug then
          print(last_kind, serialize.serialize(last_meta))
        end
        
        print("* " .. block, block_id, last_kind, original_meta)
        
        for i = 0, 2^options.bits - 1 do
          set_block(options.x, options.y, options.z, block, i)
          
          local m = world.getMetadata(options.x, options.y, options.z)
          local kind, meta = rob_world.BlockMetadata.parse(m)
          local test_value = rob_world.BlockMetadata.tonumber(m)

          local changes = changed_values(last_meta, meta)
          if changes ~= {} then
            bits[i] = { changes, m }
          end

          if options.debug then
            print(i, test_value == i, original_meta == m, m, test_value, serialize.serialize(changes))
          end

          last_kind, last_meta = kind, meta

          if options.delay then
            os.sleep(options.delay)
          end
        end

        print("Values:")
        for i, v in pairs(bits) do
          local changes, meta = table.unpack(v)
          local computed = rob_world.BlockMetadata.tonumber(meta)
          print(i, serialize.serialize(changes), meta, computed, computed == i)
        end

        print("")
        print("Bits:")
        for bit = 0, options.bits do
          local i = 2^bit
          local changes = bits[i]
          print(bit, i, serialize.serialize(changes))
        end
      end

      for _, block in ipairs(args) do
        try_block(block)
      end
    end
})
