local bits = require("bit32")
local component = require("component")
local args = {...}
local brightness
local color

if not args[1] then
  print("Usage: lights brightness [color]")
  print("")
  print("Lights:")
  for addr, name in component.list() do
    if name == "colorful_lamp" then
      local l = component.proxy(addr)
      print("  " .. addr .. " " .. l.getLampColor())
    end
  end
  os.exit(1)
end

if args[1] then
  local red = tonumber(args[1] or 0)
  local green = tonumber(args[2] or red)
  local blue = tonumber(args[3] or red)
  color = bits.bor(bits.lshift(bits.rshift(red, 2), 10),
                   bits.lshift(bits.rshift(green, 2), 5),
                   bits.lshift(bits.rshift(blue, 2), 0))
end

if color then
  print("Setting color to " .. color)
end

for addr, name in component.list() do
  if name == "colorful_lamp" then
    print("  " .. addr)
    local light = component.proxy(addr)
    if color then
      light.setLampColor(color)
    end
  end
end