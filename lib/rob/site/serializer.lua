local sneaky = require("sneaky/util")
local fs = require("filesystem")
local serialization = require("serialization")
local ser = {}

function make_directory(path)
  fs.makeDirectory(path)
end

function create_init(site, path)
  if not fs.exists(path) then
    title = serialization.serialize(site.name)
    local out = io.open(path, "w")
    out:write("local site = ...", "\n",
              "site.name = " .. serialization.serialize(site.name), "\n",
              "return site", "\n")
    out:close()
  end
end

function ser.save(site, path)
  make_directory(path)
  create_init(site, sneaky.pathjoin(path, "init.lua"))
  if site._dir ~= path then
    site._dir = path
    site._robots = site._robots:copy(sneaky.pathjoin(path, "robots"))
  end
end

return ser
