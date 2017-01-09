local sneaky = require("sneaky/util")

local BOP_PLANT_0_VARIANTS = sneaky.reduce(sneaky.spairs({ "shortgrass", "mediumgrass", "bush", "sprout", "poisonivy", "berrybush", "shrub", "wheatgrass", "dampgrass", "koru", "cloverpatch", "leafpile", "deadleafpile", "deadgrass", "desertgrass", "desertsprouts" }), {}, function(a, k, v) a[v] = k - 1; return a end)

local BOP_PLANT_1_VARIANTS = sneaky.reduce(sneaky.spairs({ "dunegrass", "spectralfern", "thorn", "wildrice", "cattail", "rivercane", "tinycactus", "witherwart", "reed", "root", "rafflesia" }), {}, function(a, k, v) a[v] = k - 1; return a end)

return {
  [ "biomesoplenty:plant_0"] = {
    nil, "bright_green",
    function(args)
      return BOP_PLANT_0_VARIANTS[args.variant]
    end
  },
  [ "biomesoplenty:plant_1"] = {
    nil, "bright_green",
    function(args)
      return BOP_PLANT_1_VARIANTS[args.variant]
    end
  }
}
