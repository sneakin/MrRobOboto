local args = {...}
print(...)

local path = string.match(args[2], "(.+/).+$")

local package_paths = {}
for p in string.gmatch(package.path, "[^;]+") do
  if not string.match(p, path) then
    table.insert(package_paths, p)
  end
end

local paths = {
  "lib/?.lua",
  "lib/?/init.lua",
  "mock/lib/?.lua",
  "mock/lib/?/init.lua"
}
for _, p in ipairs(paths) do
  table.insert(package_paths, path .. p)
end

package.path = table.concat(package_paths, ";")

--pkg=require(args[2])
--print(loadstring(args[3])())

return {}
