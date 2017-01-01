local fs = require("filesystem")
local mod = {}

function mod.exists(path)
  return fs.exists(path)
end

function mod.read(path)
  local f = io.open(path, "r")
  if f then
    local line = f:read()
    local n = string.match(line, "([0-9]+)")
    f:close()
    if n then
      return tonumber(n)
    end
  end
end

function mod.write(path, pid)
  local f = io.open(path, "w")
  f:write(pid)
  f:close()
end

return mod
