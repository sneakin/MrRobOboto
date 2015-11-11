local shell = require("shell")
local args = {...}
local path = args[1] or shell.getWorkingDirectory()
shell.setPath(shell.getPath() .. ":" .. path .. "bin" .. ":" .. path .. "scripts")
package.path = package.path .. ";" .. path .. "lib/?.lua"
package.path = package.path .. ";" .. path .. "lib/?/init.lua"
print("Added " .. path .. " to the search paths.")

-- TODO let require("rob") set all this up
rob = require("rob")
sneaky = require("sneaky/util")
