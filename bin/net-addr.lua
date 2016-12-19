local component = require("component")

local args = {...}
local num = tonumber(args[1])

local i = 1

for addr, comp in component.list() do
  if comp == "modem" then
    if (num == nil or num == i) then
      print(addr)
    end

    i = i + 1
  end
end
