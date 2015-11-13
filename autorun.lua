local shell = require("shell")
local component = require("component")

local args = {...}

local path = args[1] or shell.getWorkingDirectory()
shell.setPath(shell.getPath() .. ":" .. path .. "bin" .. ":" .. path .. "scripts")
package.path = package.path .. ";" .. path .. "lib/?.lua"
package.path = package.path .. ";" .. path .. "lib/?/init.lua"
print("Added " .. path .. " to the search paths.")

-- TODO let require("rob") set all this up
local robot = false
for kind, addr in pairs(component.list()) do
   if kind == "robot" then
      robot = true
      break
   end
end

if robot then
   rob = require("rob")
end

sneaky = require("sneaky/util")
