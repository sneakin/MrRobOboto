local shell = require("shell")
local component = require("component")
local args = {...}

local disk = args[1]
local dir = "/mnt/" .. string.sub(disk.address, 1, 3) .. "/"
print("Adding " .. dir .. " to the search paths.")
shell.setPath(shell.getPath() .. ":" .. dir .. "bin" .. ":" .. dir .. "scripts")
package.path = package.path .. ";" .. dir .. "lib/?.lua"
package.path = package.path .. ";" .. dir .. "lib/?/init.lua"

-- TODO let require("rob") set all this up
local robot = false
for addr, kind in pairs(component.list()) do
   if kind == "robot" then
      robot = true
      break
   end
end

if robot then
   rob = require("rob")

  local shell = require("shell")
  shell.execute("rshd")
end

sneaky = require("sneaky/util")
