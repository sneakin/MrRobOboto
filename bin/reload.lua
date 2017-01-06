local sneaky = require("sneaky/util")

local args = {...}
for _, a in ipairs(args) do
  local ok, reason = pcall(sneaky.reload, a)
  if ok then
    print("Reloaded " .. a)
  else
    error(reason)
  end
end
