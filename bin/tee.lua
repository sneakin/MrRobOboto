local args = {...}
local files = { ["/dev/stdout"] = io.stdout }

for _, path in ipairs(args) do
  local f = io.open(path, "w")
  if f then
    f.bufferMode = "no"
    files[path] = f
  else
    io.stderr:write("Error opening " .. path)
  end
end

local line

repeat
  line = io.stdin:read()
  if line then
    line = line .. "\n"
    for path, f in pairs(files) do
      if not f:write(line) and not f:flush() then
        error("Error writing to " .. path)
      end
    end
  end
until line == nil

for path, f in pairs(files) do
  f:close()
end
