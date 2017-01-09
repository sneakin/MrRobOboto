local sneaky = require("sneaky/util")
local serialize = require("serialization")
local sides = require("sides")
local filesystem = require("filesystem")

-----
local BlockMetadata = {}

BlockMetadata.DIRECTORIES = {
  sneaky.pathjoin(sneaky.root, "..", "data", "blocks"),
  sneaky.pathjoin(sneaky.root, "rob", "world", "blocks"),
}

--BlockMetadata.blocks = sneaky.table(function(tbl, i)
--    error("Unknown block, " .. tostring(i) .. ", please add it to block_data.lua")
--end)
BlockMetadata.blocks = {}

function BlockMetadata.massageBlockData(data)
  return sneaky.map(sneaky.spairs(data),
                    function(name, def)
                      return {
                        id = def[1],
                        name = name,
                        color = def[2],
                        convertor = def[3],
                        nbt_updater = def[4],
                        nbt_saver = def[5]
                      }
  end)
end

function BlockMetadata.loadBlockDataFrom(path)
  local new_blocks, failed = loadfile(path)
  if new_blocks then
    BlockMetadata.blocks = sneaky.deep_merge(BlockMetadata.blocks, BlockMetadata.massageBlockData(new_blocks()))
  else
    error(failed)
  end
end

function BlockMetadata.loadBlockDataDir(dir)
  for name in filesystem.list(dir) do
    if string.match(name, "[.]lua$") then
      BlockMetadata.loadBlockDataFrom(sneaky.pathjoin(dir, name))
    end
  end
end

function BlockMetadata.reloadBlockData()
  for _, dir in ipairs(BlockMetadata.DIRECTORIES) do
    BlockMetadata.loadBlockDataDir(dir)
  end
end

BlockMetadata.reloadBlockData()

----

function BlockMetadata.parse(metadata)
  -- print("Metadata", metadata)
  local kind = string.match(metadata, "[A-Za-z:_][A-Za-z:_0-9]*") or metadata
  local args = string.match(metadata, "[[](.*)[]]")

  -- print("Kind", kind, "Args", args)
  local args_table = {}
  local count = 0

  if args then
    for arg in string.gmatch(args, "[^,]+") do
      local name, value = string.match(arg, "(.*)=(.*)")
      if name and value then
        args_table[name] = value
        count = count + 1
      end
    end

    -- print(serialize.serialize(args_table))
  end
  
  return kind, args_table, count
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

function getBlockDataById(id)
  return sneaky.findFirst(BlockMetadata.blocks, function(k, v)
                            return v.id == id
  end)
end

function getBlockData(name)
  local iter = sneaky.search(BlockMetadata.blocks, ":" .. name .. "$", function(k,v) return k end)
  local kind, block = iter()
  if block then
    return block
  end

  iter = sneaky.search(BlockMetadata.blocks, ":" .. name, function(k,v) return k end)
  local kind, block = iter()
  if block then
    return block
  end

  iter = sneaky.search(BlockMetadata.blocks, name, function(k,v) return k end)
  local kind, block = iter()
  if block then
    return block
  end

  error("Block not found: " .. tostring(name))
end


-------
local world = {
  BlockMetadata = BlockMetadata,
  BlockNBT = BlockNBT,
  getBlockDataById = getBlockDataById,
  getBlockData = getBlockData
}

return world
