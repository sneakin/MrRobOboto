local sneaky = require("sneaky/util")

local BOP_PLANT_0_VARIANTS = sneaky.reduce(sneaky.spairs({ "shortgrass", "mediumgrass", "bush", "sprout", "poisonivy", "berrybush", "shrub", "wheatgrass", "dampgrass", "koru", "cloverpatch", "leafpile", "deadleafpile", "deadgrass", "desertgrass", "desertsprouts" }), {}, function(a, k, v) a[v] = k - 1; return a end)

local BOP_PLANT_1_VARIANTS = sneaky.reduce(sneaky.spairs({ "dunegrass", "spectralfern", "thorn", "wildrice", "cattail", "rivercane", "tinycactus", "witherwart", "reed", "root", "rafflesia" }), {}, function(a, k, v) a[v] = k - 1; return a end)

local BITS_LEAF_DECAYABLE = 4
local BITS_LEAF_CHECK_DECAY = 8
local BOP_LEAVES_0_VARIANTS = sneaky.reduce(sneaky.spairs({ "yellow_autumn", "orange_autumn", "bamboo", "magic" }), {}, function(a, k, v) a[v] = k - 1; return a end)
local BOP_LEAVES_1_VARIANTS = sneaky.reduce(sneaky.spairs({ "umbran", "dead", "fir", "ethereal" }), {}, function(a, k, v) a[v] = k - 1; return a end)
local BOP_LEAVES_2_VARIANTS = sneaky.reduce(sneaky.spairs({ "origin", "pink_cherry", "white_cherry", "maple" }), {}, function(a, k, v) a[v] = k - 1; return a end)

local BOP_DIRT_VARIANTS = sneaky.reduce(sneaky.spairs({ "loamy", "sandy", "silty" }), {}, function(a, k, v) a[v] = k - 1; return a end)
local BOP_DIRT_COARSE = 8

local BOP_GRASS_VARIANTS = sneaky.reduce(sneaky.spairs({ "spectral_mass", "overgrown_stone", "loamy", "sandy", "silty", "origin", "overgrown_netherrack", "daisy" }), {}, function(a, k, v) a[v] = k - 1; return a end)

local BOP_LOG_AXIS_Y = 4
local BOP_LOG_AXIS_Z = 8
local BOP_LOG_AXIS_NONE = 12
local BOP_LOG_0_VARIANTS = sneaky.reduce(sneaky.spairs({ "sacred_oak", "cherry", "umbran", "fir" }), {}, function(a, k, v) a[v] = k - 1; return a end)
local BOP_LOG_1_VARIANTS = sneaky.reduce(sneaky.spairs({ "ethereal", "magic", "mangrove", "palm" }), {}, function(a, k, v) a[v] = k - 1; return a end)
local BOP_LOG_2_VARIANTS = sneaky.reduce(sneaky.spairs({ "redwood", "willow", "pine", "hellbark" }), {}, function(a, k, v) a[v] = k - 1; return a end)
local BOP_LOG_3_VARIANTS = sneaky.reduce(sneaky.spairs({ "jacaranda", "mahogany", "ebony", "eucalyptus" }), {}, function(a, k, v) a[v] = k - 1; return a end)

local BOP_FLOWER_0_VARIANTS = sneaky.reduce(sneaky.spairs({ "clover", "swampflower", "deathbloom", "glowflower", "blue_hydrangea", "orange_cosmos", "pink_daffodil", "wildflower", "violet", "white_anemone", "enderlotus", "bromeliad", "wilted_lily", "pink_hibiscus", "lily_of_the_valley", "burning_blossom" }), {}, function(a, k, v) a[v] = k - 1; return a end)
local BOP_FLOWER_1_VARIANTS = sneaky.reduce(sneaky.spairs({ "lavendar", "goldenrod", "bluebells", "miners_delight", "icy_iris", "rose", "lavendar" }), {}, function(a, k, v) a[v] = k - 1; return a end)

local BOP_DOUBLE_PLANT_UPPER = 8
local BOP_DOUBLE_PLANT_VARIANTS = sneaky.reduce(sneaky.spairs({ "flax", "tall_cattail", "eyebulb" }), {}, function(a, k, v) a[v] = k - 1; return a end)

local BOP_WATERLILY_VARIANTS = sneaky.reduce(sneaky.spairs({ "medium", "small", "tiny", "flower" }), {}, function(a, k, v) a[v] = k - 1; return a end)

function table_lookup(tbl, arg)
  return function(args)
    return tbl[args[arg]] or 0
  end
end

function leaves_table(tbl)
  return function(args)
    local v = tbl[args.variant] or 0

    if args.check_decay == "true" then
      v = bit32.bor(v, BITS_LEAF_CHECK_DECAY)
    end
    if args.decayable == "false" then
      v = bit32.bor(v, BITS_LEAF_DECAYABLE)
    end

    return v
  end
end

function log_table(tbl)
  return function(args)
    local v = tbl[args.variant] or 0
    if args.axis == "y" then
      v = bit32.bor(v, BOP_LOG_AXIS_Y)
    end
    if args.axis == "z" then
      v = bit32.bor(v, BOP_LOG_AXIS_Z)
    end
    if args.axis == "none" then
      v = bit32.bor(v, BOP_LOG_AXIS_NONE)
    end
    return v
  end
end

return {
  [ "biomesoplenty:plant_0"] = {
    nil, "bright_green", table_lookup(BOP_PLANT_0_VARIANTS, "variant")
  },
  [ "biomesoplenty:plant_1"] = {
    nil, "bright_green", table_lookup(BOP_PLANT_1_VARIANTS, "variant")
  },
  [ "biomesoplenty:leaves_0"] = {
    nil, "bright_green", leaves_table(BOP_LEAVES_0_VARIANTS)
  },
  [ "biomesoplenty:leaves_1"] = {
    nil, "bright_green", leaves_table(BOP_LEAVES_1_VARIANTS)
  },
  [ "biomesoplenty:leaves_2"] = {
    nil, "bright_green", leaves_table(BOP_LEAVES_2_VARIANTS)
  },
  [ "biomesoplenty:dirt" ] = {
    nil, "brown",
    function(args)
      local v = BOP_DIRT_VARIANTS[args.variant] or 0
      if args.coarse == "true" then
        v = bit32.bor(v, BOP_DIRT_COARSE)
      end
      return v
    end
  },
  [ "biomesoplenty:grass" ] = {
    nil, "brown", table_lookup(BOP_GRASS_VARIANTS, "variant")
  },
  [ "biomesoplenty:double_plant" ] = {
    nil, "bright_green",
    function(args)
      local v = BOP_DOUBLE_PLANT_VARIANTS[args.variant] or 0
      if args.half == "upper" then
        v = bit32.bor(v, BOP_DOUBLE_PLANT_UPPER)
      end
      return v
    end
  },
  [ "biomesoplenty:flower_0" ] = {
    nil, "bright_green", table_lookup(BOP_FLOWER_0_VARIANTS, "variant")
  },
  [ "biomesoplenty:flower_1" ] = {
    nil, "bright_green", table_lookup(BOP_FLOWER_1_VARIANTS, "variant")
  },
  [ "biomesoplenty:log_0" ] = {
    nil, "brown", log_table(BOP_LOG_0_VARIANTS)
  },
  [ "biomesoplenty:log_1" ] = {
    nil, "brown", log_table(BOP_LOG_1_VARIANTS)
  },
  [ "biomesoplenty:log_2" ] = {
    nil, "brown", log_table(BOP_LOG_2_VARIANTS)
  },
  [ "biomesoplenty:log_3" ] = {
    nil, "brown", log_table(BOP_LOG_3_VARIANTS)
  },
  [ "biomesoplenty:waterlily" ] = {
    nil, "bright_green", table_lookup(BOP_WATERLILY_VARIANTS, "variant")
  },
}
