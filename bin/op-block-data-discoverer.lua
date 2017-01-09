local sneaky = require("sneaky/util")
local Command = require("sneaky/command")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "A more person friendly form of the generator.",
    arguments = {
      x = Command.Argument.Integer({
          description = "X coordinate of the space to change.",
          required = true
      }),
      y = Command.Argument.Integer({
          description = "Y coordinate of the space to change.",
          required = true
      }),
      z = Command.Argument.Integer({
          description = "Z coordinate of the space to change.",
          required = true
      }),
      min = Command.Argument.Integer({
          default = 0
      }),
      max = Command.Argument.Integer({
          default = 256
      })
    },
    run = function(options, args)
      local rob_world = require("rob/world")
      local component = require("component")
      local world = component.debug.getWorld()
      local serialization = require("serialization")
      local last_was_air = nil

      for bid = options.min, options.max do
        local ok, reason = pcall(world.setBlock, options.x, options.y, options.z, bid, 0)
        if ok then
          local data = world.getMetadata(options.x, options.y, options.z)
          local kind, args, count = rob_world.BlockMetadata.parse(data)

          if kind == "minecraft:air" and bid ~= 0 then
            if last_was_air then
              io.stderr:write(bid, "NUM_BLOCKS")
              break
            else
              print(bid, "invalid?", reason)
              last_was_air = true
            end
          else
            last_was_air = nil
            print(bid, kind, count > 0, serialization.serialize(args))
          end
        else
          print(bid, "invalid?", reason)
        end
      end
    end
})
