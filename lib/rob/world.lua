local sneaky = require("sneaky/util")
local serialize = require("serialization")
local sides = require("sides")

local BlockMetadata = {}

BlockMetadata.blocks = sneaky.map(sneaky.spairs(sneaky.reload("rob/world/block_data")),
                                  function(name, def)
                                    return {
                                      id = def[1],
                                      color = def[2],
                                      convertor = def[3],
                                      nbt_updater = def[4],
                                      nbt_saver = def[5]
                                    }
end)

setmetatable(BlockMetadata.blocks, {
               __index = function(i)
                 return {
                   id = 0,
                   color = nil,
                   convertor = nil,
                   nbt_updater = nil
                 }
               end
})

function BlockMetadata.parse(metadata)
  -- print("Metadata", metadata)
  local kind = string.match(metadata, "[A-Za-z:_][A-Za-z:_0-9]*") or metadata
  local args = string.match(metadata, "[[](.*)[]]")

  -- print("Kind", kind, "Args", args)
  local args_table = {}

  if args then
    for arg in string.gmatch(args, "[^,]+") do
      local name, value = string.match(arg, "(.*)=(.*)")
      if name and value then
        args_table[name] = value
      end
    end

    -- print(serialize.serialize(args_table))
  end
  
  return kind, args_table
end

function BlockMetadata.tonumber(metadata)
  if not metadata then
    return 0
  end

  local kind, args = BlockMetadata.parse(metadata)
  local func = BlockMetadata.blocks[kind].convertor
  if func then
    return func(args) or 0
  elseif #args > 0 then
    error("Unknown kind " .. kind .. " with arguments " .. serialize.serialize(args))
  else
    return 0
  end
end

-------

local BlockNBT = {}

function BlockNBT.to_table(nbt_data)
  if nbt_data.type == 10 then
    local tbl = {}
    for k,v in pairs(nbt_data.value) do
      tbl[k] = BlockNBT.to_table(v)
    end
    return tbl
  else
    return nbt_data.value
  end
end

local NBT_TYPES = {
  boolean = 1,
  number = 3,
  string = 8,
  table = 10
}

function BlockNBT.type_for(value)
  return NBT_TYPES[type(value)] or NBT_TYPES["string"]
end

function BlockNBT.from_table(tbl)
  if type(tbl) == "table" then
    local kids = {}
    for k, v in pairs(tbl) do
      kids[k] = BlockNBT.from_table(v)
    end
    return { type = NBT_TYPES["table"], value = kids }
  else
    return { value = tbl, type = BlockNBT.type_for(tbl) }
  end
end


-------
local world = {
  BlockMetadata = BlockMetadata,
  BlockNBT = BlockNBT
}

return world
