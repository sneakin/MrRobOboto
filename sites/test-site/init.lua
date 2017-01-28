local sneaky = require("sneaky/util")
local Site = require("rob/site")
local vec3d = require("vec3d")
local sides = require("sides")
local zones = require("rob/site/zones")

local site = ...

site.name = "test-site"

local routes_path = sneaky.pathjoin(sneaky.dirname(debug.getinfo(2, "S").source), "routes.lua"):sub(2)
print(routes_path)
local routes_f, reason = assert(loadfile(routes_path))
routes_f(site._router)

return site
