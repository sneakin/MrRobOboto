local sneaky = require("sneaky/util")

function table_lookup(tbl, arg)
  return function(args)
    return tbl[args[arg]] or 0
  end
end

local RESOURCE_TYPES = sneaky.reduce(sneaky.spairs({ "basalt", "copper_ore", "lead_ore", "tin_ore", "uranium_ore", "bronze_block", "copper_block", "lead_block", "steel_block", "tin_block", "uranium_block", "reinforced_stone", "machine", "advanced_machine", "reactor_vessel" }), {}, function(a, k, v) a[v] = k - 1; return a end)
local LEAF_TYPES = sneaky.reduce(sneaky.spairs({ "rubber" }), {}, function(a, k, v) a[v] = k - 1; return a end)
local LEAF_DECAYABLE = 4
local LEAF_CHECK_DECAY = 8

local RUBBER_WOOD_STATE = sneaky.reduce(sneaky.spairs({ "plain_y", "plain_x", "plain_z", "dry_north", "dry_south", "dry_west", "dry_east", "wet_north", "wet_south", "wet_west", "wet_east" }), {}, function(a, k, v) a[v] = k - 1; return a end)

return {
  [ "ic2:leaves" ] = {
    nil, "bright_green",
    function(args)
      local v = LEAF_TYPES[args.type] or 0
      if args.decayable == "true" then
        v = bit32.bor(v, LEAF_DECAYABLE)
      end
      if args.check_decay == "true" then
        v = bit32.bor(v, LEAF_CHECK_DECAY)
      end
      return v
    end
  },
  [ "ic2:resource" ] = {
    nil, "yellow", table_lookup(RESOURCE_TYPES, "type")
  },
  [ "ic2:rubber_wood" ] = {
    nil, "light_brown", table_lookup(RUBBER_WOOD_STATE, "state")
  }
}
