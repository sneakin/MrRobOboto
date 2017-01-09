local bit32 = require("bit32")
local sneaky = require("sneaky/util")

local OC_PITCH = { down = 0, up = 4, north  = 8 }
local OC_FACING = sneaky.reduce(sneaky.spairs({ "south", "west", "north", "east" }), {}, function(a, k, v) a[v] = k - 1; return a end)
local BITS_OC_PITCH_UP = 4


function bits_oc_yaw(args)
  return bit32.bor(OC_FACING[args.yaw] or 0, OC_PITCH[args.pitch])
end

function bits_oc_facing(args)
  return OC_FACING[args.facing]
end

function bits_oc_powered_facing(args)
  return OC_FACING[args.facing] * 2
end

return {
  [ "opencomputers:keyboard" ] = { nil, "dark_gray", bits_oc_yaw },
  [ "opencomputers:screen1" ] = { nil, "dark_gray", bits_oc_yaw },
  [ "opencomputers:screen2" ] = { nil, "dark_gray", bits_oc_yaw },
  [ "opencomputers:screen3" ] = { nil, "dark_gray", bits_oc_yaw },
  [ "opencomputers:case1" ] = { nil, "dark_gray", bits_oc_powered_facing },
  [ "opencomputers:case2" ] = { nil, "dark_gray", bits_oc_powered_facing },
  [ "opencomputers:case3" ] = { nil, "dark_gray", bits_oc_powered_facing },
  [ "opencomputers:diskDrive" ] = { nil, "dark_gray", bits_oc_facing },
  [ "opencomputers:charger" ] = { nil, "dark_gray", bits_oc_facing },
  [ "opencomputers:raid" ] = { nil, "dark_gray", bits_oc_facing },
  [ "opencomputers:cable" ] = { nil, "dark_gray" }
}
