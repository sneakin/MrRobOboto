local bit32 = require("bit32")
local sneaky = require("sneaky/util")
local sides = require("sides")

local DIRT_VARIANTS = sneaky.reduce(sneaky.spairs({ "coarse_dirt", "podzol" }), {}, function(a, k, v) a[v] = k; return a end)

local BITS_LEAF_DECAYABLE = 4
local BITS_LEAF_CHECK_DECAY = 8
local LEAF_VARIANTS = sneaky.reduce(sneaky.spairs({ "oak", "spruce", "birch", "jungle" }), {}, function(a, k, v) a[v] = k - 1; return a end)

local STONE_VARIANTS = sneaky.reduce(sneaky.spairs({ "stone", "granite", "smooth_granite", "diorite", "smooth_diorite", "andesite", "smooth_andesite" }), {}, function(a, k, v) a[v] = k - 1; return a end)

local TORCH_FACING = sneaky.reduce(sneaky.spairs({ "east", "west", "south", "north", "up" }), {}, function(a, k, v) a[v] = k; return a end)

local CHEST_FACING = sneaky.reduce(sneaky.spairs({ "north", "north", "north", "south", "west", "east" }), {}, function(a, k, v) a[v] = k - 1; return a end)
local FURNACE_FACING = sneaky.reduce(sneaky.spairs({ "south", "west", "east" }), {}, function(a, k, v) a[v] = k + 2; return a end)

local BITS_LEVER_POWERED = 8
local LEVER_FACING = sneaky.reduce(sneaky.spairs({ "down_x", "east", "west", "south", "north", "up_z", "up_x", "down_z" }), {}, function(a, k, v) a[v] = k - 1; return a end)

local BITS_REPEATER_DELAY_2 = 4
local BITS_REPEATER_DELAY_3 = 8
local BITS_REPEATER_DELAY_4 = bit32.bor(BITS_REPEATER_DELAY_2, BITS_REPEATER_DELAY_3)
local REPEATER_FACING = sneaky.reduce(sneaky.spairs({ "south", "west", "north", "east" }), {}, function(a, k, v) a[v] = k - 1; return a end)

local COMPARATOR_MODE_SUBTRACT = 4
local COMPARATOR_POWERED = 8
local COMPARATOR_FACING = sneaky.reduce(sneaky.spairs({ "south", "west", "north", "east" }), {}, function(a, k, v) a[v] = k - 1; return a end)

local HOPPER_FACING = sneaky.reduce(sneaky.spairs({ "down", "", "north", "south", "west", "east" }), {}, function(a, k, v) a[v] = k - 1; return a end)

local DOOR_FACING = sneaky.reduce(sneaky.spairs({ "east", "south", "west", "north" }), {}, function(a, k, v) a[v] = k - 1; return a end)
local BITS_DOOR_OPEN = 4
local BITS_DOOR_UPPER_HALF = 8

local FENCE_GATE_FACING = sneaky.reduce(sneaky.spairs({ "south", "west", "north", "east" }), {}, function(a, k, v) a[v] = k - 1; return a end)
local BITS_FENCE_GATE_OPEN = 4
local BITS_FENCE_GATE_POWERED = 8

local BUTTON_FACING = sneaky.reduce(sneaky.spairs({ "down", "east", "west", "south", "north", "up" }), {}, function(a, k, v) a[v] = k - 1; return a end)
local BITS_BUTTON_POWERED = 8

local COMMAND_BLOCK_FACING = sneaky.reduce(sneaky.spairs({ "down", "up", "north", "south", "west", "east" }), {}, function(a, k, v) a[v] = k - 1; return a end)
local BITS_COMMAND_BLOCK_CONDITIONAL = 8

local COLORS = sneaky.reduce(sneaky.spairs({ "white", "orange", "magenta", "light_blue", "yellow", "lime", "pink", "gray", "silver", "cyan", "purple", "blue", "brown", "green", "red", "black" }), {}, function(a, k, v) a[v] = k - 1; return a end)

local WALL_SIGN_FACING = sneaky.reduce(sneaky.spairs({ "north", "north", "north", "south", "west", "east" }), {}, function(a, k, v) a[v] = k - 1; return a end)

local TALLGRASS_TYPES = sneaky.reduce(sneaky.spairs({ "dead_bush", "tall_grass", "fern" }), {}, function(a, k, v) a[v] = k - 1; return a end)

local OC_FACING = sneaky.reduce(sneaky.spairs({ "south", "west", "north", "east" }), {}, function(a, k, v) a[v] = k - 1; return a end)
local BITS_OC_PITCH_UP = 4

local BOP_PLANT_0_VARIANTS = sneaky.reduce(sneaky.spairs({ "shortgrass", "mediumgrass", "bush", "sprout", "poisonivy", "berrybush", "shrub", "wheatgrass", "dampgrass", "koru", "cloverpatch", "leafpile", "deadleafpile", "deadgrass", "desertgrass", "desertsprouts" }), {}, function(a, k, v) a[v] = k - 1; return a end)

local BOP_PLANT_1_VARIANTS = sneaky.reduce(sneaky.spairs({ "dunegrass", "spectralfern", "thorn", "wildrice", "cattail", "rivercane", "tinycactus", "witherwart", "reed", "root", "rafflesia" }), {}, function(a, k, v) a[v] = k - 1; return a end)


function bits_torch(args)
  return TORCH_FACING[args.facing]
end

function bits_button(args)
  local v = BUTTON_FACING[args.facing]

  if args.powered == "true" then
    v = bit32.bor(v, BITS_BUTTON_POWERED)
  end

  return v
end

function bits_repeater(args)
  local v = REPEATER_FACING[args.facing]
  if args.delay == "2" then
    v = bit32.bor(v, BITS_REPEATER_DELAY_2)
  elseif args.delay == "3" then
    v = bit32.bor(v, BITS_REPEATER_DELAY_3)
  elseif args.delay == "4" then
    v = bit32.bor(v, BITS_REPEATER_DELAY_4)
  end
  return v    
end  

function bits_comparator(args)
  local v = COMPARATOR_FACING[args.facing]
  if args.mode == "subtract" then
    v = bit32.bor(v, COMPARATOR_MODE_SUBTRACT)
  end
  if args.powered == "true" then
    v = bit32.bor(v, COMPARATOR_POWERED)
  end
  return v
end

function bits_command_block(args)
  local v = COMMAND_BLOCK_FACING[args.facing]

  if args.conditional == "true" then
    v = bit32.bor(v, BITS_COMMAND_BLOCK_CONDITIONAL)
  end

  return v
end

function bits_fluid(args)
  return tonumber(args.level)
end

local OC_PITCH = { down = 0, up = 4, north  = 8 }

function bits_oc_yaw(args)
  return bit32.bor(OC_FACING[args.yaw] or 0, OC_PITCH[args.pitch])
end

function bits_oc_facing(args)
  return OC_FACING[args.facing]
end

function bits_oc_powered_facing(args)
  return OC_FACING[args.facing] * 2
end

function nbt_sign(old, new_data)
  old.value.Text1.value = new_data.value.Text1.value
  old.value.Text2.value = new_data.value.Text2.value
  old.value.Text3.value = new_data.value.Text3.value
  old.value.Text4.value = new_data.value.Text4.value
  
  return old
end

local vec3d = require("vec3d")

-- todo seems to be off by 1 in the -x(!) and -z
-- todo tp off by 1 in the Y
function adjust_command_coords(cmd, origin, volume, adjustment)
  local coords = {}
  local new_cmd = cmd
  local match = string.gmatch(new_cmd, "(-?[0-9]+)")
  local depth = 0

  repeat
    -- match a triplet of nummbers
    local x = match()
    depth = depth + 1
    if x then
      local y = match()
      depth = depth + 1
      if y then
        local z = match()
        depth = depth + 1
        if z then
          -- is the triplet inside the volume?
          local v = vec3d:new(tonumber(x), tonumber(y), tonumber(z))
          local nv = v - origin

          if nv.x < volume.x
            and nv.x >= 0
            and nv.y < volume.y
            and nv.y >= 0
            and nv.z < volume.z
            and nv.z >= 0
          then
            local fv = nv + adjustment
            
            local vs = tostring(v.x)
              .. " "
              .. tostring(v.y)
              .. " "
              .. tostring(v.z)
            local fvs = tostring(fv.x)
              .. " "
              .. tostring(fv.y)
              .. " "
              .. tostring(fv.z)
            new_cmd = string.gsub(new_cmd, vs, fvs)
          else
            -- reset the matcher, but to where the last valid number was
            match = string.gmatch(new_cmd, "(-?[0-9]+)")
            for i = 1, depth - 2 do
              match()
            end
            depth = depth - 2
          end
        end
      end
    end
  until x == nil

  return new_cmd
end

function adjust_command_targets(cmd, origin, volume, adjustment)
  local selector_kind, args = string.match(cmd, "@([a-z])[[](.*)[]]")
  if not selector_kind or not args then
    return cmd
  end
  
  local parts = {}
  
  for part in string.gmatch(args, "[^,]+") do
    local lh, rh = string.match(part, "(.*)=(.*)")
    if lh == "x" or lh == "y" or lh == "z" then
      local x = tonumber(rh) - origin[lh]
      if x < volume[lh] and x >= 0 then
        table.insert(parts, lh .. "=" .. tostring(x + adjustment[lh]))
      else
        table.insert(parts, part)
      end
    else
      table.insert(parts, part)
    end
  end

  local new_args = sneaky.join(parts, ",")
  local new_selector = "@" .. selector_kind .. "[" .. new_args .. "]"
  local old_selector = "@" .. selector_kind .. "[[].*[]]"
  local new_cmd = string.gsub(cmd, old_selector, new_selector)

  return new_cmd
end

function command_block_save_nbt(nbt, origin, volume, adjustment)
  nbt.value.Command.value = adjust_command_coords(adjust_command_targets(nbt.value.Command.value, origin, volume, adjustment), origin, volume, adjustment)
  return nbt
end

function nbt_command_block(old, new_data, origin, volume, adjustment)
  old.value.Command.value = adjust_command_coords(adjust_command_targets(new_data.value.Command.value, origin, volume, adjustment), origin, volume, adjustment)
  old.value.TrackOutput.value = new_data.value.TrackOutput.value
  old.value.auto.value = new_data.value.auto.value
  return old
end

function sign_save_nbt(nbt, origin, volume, adjustment)
  for _, field in ipairs({"Text1", "Text2", "Text3", "Text4"}) do
    nbt.value[field].value = adjust_command_coords(adjust_command_targets(nbt.value[field].value, origin, adjustment), origin, volume, adjustment)
  end
  return nbt
end

local BlockData = {
  ["minecraft:stone"] = {
    1, "gray",
    function(args)
      return STONE_VARIANTS[args.variant]
    end
  },
  ["minecraft:grass"] = {
    2, "green",
    function(args)
      return 0
    end
  },
  ["minecraft:dirt"] = {
    3, "brown",
    function(args)
      return DIRT_VARIANTS[args.variant]
    end
  },
  ["minecraft:leaves"] = {
    18, "dark_green",
    function(args)
      local v = LEAF_VARIANTS[args.variant]
      if args.check_decay == "true" then
        v = bit32.bor(v, BITS_LEAF_CHECK_DECAY)
      end
      if args.decayable == "false" then
        v = bit32.bor(v, BITS_LEAF_DECAYABLE)
      end

      return v
    end
  },
  ["minecraft:command_block"] = { 137, "orange", bits_command_block, nbt_command_block, command_block_save_nbt },
  ["minecraft:repeating_command_block"] = { 210, "purple", bits_command_block, nbt_command_block, command_block_save_nbt },
  ["minecraft:chain_command_block"] = { 211, "cyan", bits_command_block, nbt_command_block, command_block_save_nbt },
  ["minecraft:torch"] = { 50, "yellow", bits_torch },
  ["minecraft:redstone_lamp"] = { 123, "yellow", nil },
  ["minecraft:redstone_torch"] = { 76, "red", bits_torch },
  ["minecraft:unlit_redstone_torch"] = { 75, "dark_red", bits_torch },
  [ "minecraft:chest" ] = {
    54, "light_brown",
    function(args)
      return CHEST_FACING[args.facing]
    end
  },
  [ "minecraft:ender_chest" ] = {
    130, "light_brown",
    function(args)
      return CHEST_FACING[args.facing]
    end
  },
  [ "minecraft:furnace" ] = {
    61, "gray",
    function(args)
      return FURNACE_FACING[args.facing]
    end
  },
  [ "minecraft:wooden_door" ] = {
    64, "light_brown",
    function(args)
      local v = DOOR_FACING[args.facing]
      if args.open == "true" then
        v = bit32.bor(v, BITS_DOOR_OPEN)
      end
      if args.half == "upper" then
        v = bit32.bor(v, BITS_DOOR_UPPER_HALF)
      end
      return v
    end
  },
  [ "minecraft:stone_pressure_plate" ] = {
    70, "light_gray",
    function(args)
      if args.powered == "true" then
        return 1
      end
    end
  },
  [ "minecraft:wooden_pressure_plate" ] = {
    70, "light_gray",
    function(args)
      if args.powered == "true" then
        return 1
      end
    end
  },
  ["minecraft:redstone_wire"] = {
    55, "dark_red",
    function(args)
      return args.power
    end
  },
  ["minecraft:stone_button"] = { 77, "light_gray", bits_button },
  ["minecraft:wooden_button"] = { 143, "light_brown", bits_button },
  ["minecraft:lever"] = {
    69, "light_brown",
    function(args)
      local v = LEVER_FACING[args.facing]
      if args.powered == "true" then
        v = bit32.bor(v, BITS_LEVER_POWERED)
      end
      return v
    end
  },
  ["minecraft:powered_repeater"] = { 94, "red", bits_repeater },
  ["minecraft:unpowered_repeater"] = { 93, "dark_red", bits_repeater },
  ["minecraft:unpowered_comparator"] = { 149, "dark_red", bits_comparator },
  ["minecraft:powered_comparator"] = { 150, "red", bits_comparator },
  ["minecraft:fire"] = {
    51, "light_orange",
    function(args)
      return tonumber(args.age)
    end
  },
  ["minecraft:fence_gate"] = {
    107, "dark_gold",
    function(args)
      local v = FENCE_GATE_FACING[args.facing]

      if args.open == "true" then
        v = bit32.bor(v, BITS_FENCE_GATE_OPEN)
      end
      if args.powered == "true" then
        v = bit32.bor(v, BITS_FENCE_GATE_POWERED)
      end

      return v
    end
  },
  [ "minecraft:stained_glass"] = {
    95, "light_gray",
    function(args)
      return COLORS[args.color]
    end
  },
  [ "minecraft:wool" ] = {
    35, "white",
    function(args)
      return COLORS[args.color]
    end
  },
  ["minecraft:standing_sign"] = {
    63, "light_brown",
    function(args)
      return tonumber(args.rotation)
    end,
    nbt_sign, sign_save_nbt
  },
  ["minecraft:wall_sign"] = {
    68, "light_brown",
    function(args)
      return WALL_SIGN_FACING[args.facing]
    end,
    nbt_sign, sign_save_nbt
  },
  [ "minecraft:tallgrass" ] = {
    31, "green",
    function(args)
      return TALLGRASS_TYPES[args.type]
    end
  },
  [ "minecraft:water" ] = { 9, "blue", bits_fluid },
  [ "minecraft:lava" ] = { 11, "orange", bits_fluid },
  [ "minecraft:hopper" ] = {
    154, "light_gray",
    function(args)
      return HOPPER_FACING[args.facing]
    end
  },
  [ "opencomputers:keyboard" ] = { 395, "dark_gray", bits_oc_yaw },
  [ "opencomputers:screen1" ] = { 403, "dark_gray", bits_oc_yaw },
  [ "opencomputers:screen2" ] = { 405, "dark_gray", bits_oc_yaw },
  [ "opencomputers:screen3" ] = { 404, "dark_gray", bits_oc_yaw },
  [ "opencomputers:case1" ] = { 385, "dark_gray", bits_oc_powered_facing },
  [ "opencomputers:case2" ] = { 387, "dark_gray", bits_oc_powered_facing },
  [ "opencomputers:case3" ] = { 386, "dark_gray", bits_oc_powered_facing },
  [ "opencomputers:diskDrive" ] = { 391, "dark_gray", bits_oc_facing },
  [ "opencomputers:charger" ] = { 389, "dark_gray", bits_oc_facing },
  [ "opencomputers:raid" ] = { 400, "dark_gray", bits_oc_facing },
  [ "opencomputers:cable" ] = { 383, "dark_gray" },
  [ "biomesoplenty:plant_0"] = {
    333, "bright_green",
    function(args)
      return BOP_PLANT_0_VARIANTS[args.variant]
    end
  },
  [ "biomesoplenty:plant_1"] = {
    334, "bright_green",
    function(args)
      return BOP_PLANT_1_VARIANTS[args.variant]
    end
  },
  __test = {
    adjust_command_targets = adjust_command_targets,
    adjust_command_coords = adjust_command_coords
  }
}

return BlockData
