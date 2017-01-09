local sneaky = require("sneaky/util")
local Command = require("sneaky/command")
local serialization = require("serialization")

local BlockFile = {}
function BlockFile:new(stream)
  local c = sneaky.class(self, { stream = stream })
  c:init()
  return c
end

function BlockFile:init()
  self.stream:write("return {\n")
end

function BlockFile:write(kind, id, args, count)
  self.stream:write("  [\"" .. kind .. "\"] = { " .. tonumber(id) .. " },\t-- " .. tostring(count > 0) .. " " .. serialization.serialize(args) .. "\n")
end

function BlockFile:close()
  self.stream:write("}\n")
  self.stream:close()
  return self
end

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Use this to generate the tables needed to look up block IDs by name.",
    long_help = "If you run many mods, then you will need to run this outputing to ~$ROB/data/blocks~. Even then you may need to use the fuzzer to determine proper metadata string to value mappings.",
    usage = "[OUTPUT-DIR]",
    required_values = 1,
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
      min = Command.Argument.Integer({
          default = 0
      }),
      max = Command.Argument.Integer({
          default = 256
      }),
      selector = {
        description = "Pattern to match block names against."
      },
      exclude = {
        description = "Pattern to exclude block names against."
      }
    },
    run = function(options, args)
      local rob_world = require("rob/world")
      local fs = require("filesystem")
      local component = require("component")
      local world = component.debug.getWorld()
      local last_was_air = nil
      local block_count = 0

      assert(fs.isDirectory(args[1]), args[1] .. " must exist.")
      
      local data_files = sneaky.table(function(tbl, i)
          local f = io.open(args[1] .. "/" .. i .. ".lua", "w")
          local df = BlockFile:new(f)
          tbl[i] = df
          return df
      end)

      for bid = options.min, options.max do
        local ok, reason = pcall(world.setBlock, options.x, options.y, options.z, bid, 0)
        if ok then
          local data = world.getMetadata(options.x, options.y, options.z)
          local kind, args, count = rob_world.BlockMetadata.parse(data)

          if kind == "minecraft:air" and bid ~= 0 then
            if last_was_air then
              break
            else
              last_was_air = true
            end
          elseif (options.selector == nil or string.match(kind, options.selector))
            and (options.exclude == nil or not string.match(kind, options.exclude))
          then
            last_was_air = nil
            local prefix, _ = string.match(kind, "(.+):(.*)")
            assert(prefix, "bad block name: " .. kind)
            io.stderr:write(tostring(bid) .. "\t" .. tostring(kind) .. "\n")
            data_files[prefix]:write(kind, bid, args, count)
          else
            last_was_air = nil
          end
        elseif last_was_air then
          break
        else
          last_was_air = true
        end
      end

      for _, df in pairs(data_files) do
        df:close()
      end
    end
})
