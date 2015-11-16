local args = {...}

local path = args[1]

package.path = package.path .. ";" .. path .. "/lib/?.lua"
package.path = package.path .. ";" .. path .. "/lib/?/init.lua"

pkg=require(args[2])
print(loadstring(args[3])())
