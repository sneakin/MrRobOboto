local fs = require("filesystem")
local net = require("internet")
local shell = require("shell")

REPO_URL = "https://github.com/sneakin/MrRobOboto/raw/master/"
MANIFEST = REPO_URL .. "MANIFEST" -- TODO: how to keep this automatically in sync?

-------

function load_manifest(url)
  local retval = {}
  local result, response = pcall(net.request, url)
  if result then
    for chunk in response do
      for line in string.gmatch(chunk, "[^\n]+") do
        table.insert(retval, line)
      end
    end
  end

  return retval
end

function mkdir_p(path)
  local p = "/"
  for n, segment in ipairs(fs.segments(path)) do
    p = fs.concat(p, segment)
    if not fs.isDirectory(p) and not fs.makeDirectory(p) then
      return nil
    end
  end

  return true
end

function fetch_file(url, out_path)
  local f = io.open(out_path, "wb")
  if not f then
    return nil
  end

  local result, response = pcall(net.request, url)
  if result then
    for chunk in response do
      f:write(chunk)
    end
    f:close()

    return true
  else
    return nil
  end
end

--------

local args = {...}

local dir = fs.canonical(fs.concat(shell.getWorkingDirectory(), args[1] or ""))
print("Installing into " .. dir)

print("Fetching manifest...")
local manifest = load_manifest(MANIFEST)

for n, file in ipairs(manifest) do
  local url = REPO_URL .. file
  local p = fs.concat(dir, file)

  print("(" .. n .. "/" .. #manifest .. ") Fetching " .. url .. " to " .. p)

  if not mkdir_p(fs.path(p)) then
    error("Failed to mkdir " .. p)
  end

  if not fetch_file(url, p) then
    error("Failed to download.")
  end
end

print("")
print("If you installed onto a disk, then eject and reinsert the disk to automatically setup $PATH")
print("")
