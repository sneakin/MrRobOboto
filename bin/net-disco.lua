local rsh = require("net/rsh")
local component = require("component")
local modem = component.modem

local times = 3

local nodes = {}
local client = rsh:new(modem)

for i = 1, times do
  print("(" .. tostring(i) .. "/" .. tostring(times) .. ") Querying...")
  client:execute("net-addr")

  local ok, line, from

  repeat
    ok, from, line = client:poll()
    if ok and line then
      nodes[from] = client:getLastDistance()
    end
  until not ok

  os.sleep(1)
end

for address, dist in pairs(nodes) do
  print(address, dist)
end
