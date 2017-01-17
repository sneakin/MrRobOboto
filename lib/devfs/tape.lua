-- A tossed together, but surprisingly working,
-- devfs entry for Computronic's tape drives.
-- These entries are ~/dev/tape~ for the primary drive
-- and ~/dev/tapes/by-id/address~ for all drives.
local sneaky = require("sneaky/util")
local component = require("component")

local Node = {}

function component_get(address)
  return component.proxy(component.get(address))
end

function Node:new(address, mode)
  local comp = component_get(address)
  assert(comp ~= nil, "bad component address")
  
  return sneaky.class(self, {
                        address = address,
                        mode = mode,
                        drive = comp
  })
end

function Node:read(n)
  assert(self.mode == "r")
  assert(self:position() < self:size(), "EOT")

  local data = self.drive.read(n)
  if data:match("^[\0]+") then
    return nil
  else
    return data
  end
end

function Node:write(...)
  assert(self.mode == "w")

  for _, block in ipairs({...}) do
    local returning = nil
    if self:position() + block:len() >= self:size() then
      returning = true
    end
    
    self.drive.write(block)

    if returting then
      return false
    end
  end

  return true
end

function Node:size()
  return self.drive.getSize()
end

function Node:position()
  return self.drive.getPosition()
end

function Node:seek(mode, n)
  if mode == "cur" then
    return self.drive.seek(n)
  elseif mode == "set" then
    self.drive.seek(-self:size())
    return self.drive.seek(n)
  elseif mode == "end" then
    self.drive.seek(self:size())
    return self.drive.seek(-n)
  else
    error("Unsupported mode")
  end
end

function Node:setLabel(label)
  return self.drive.setLabel(label)
end

function Node:close()
end

------

local IdDir = {}

function IdDir.open(path, mode)
  return Node:new(path, mode)
end

function tape_drives()
  return sneaky.iter_map(sneaky.search(component.list(),
                                       function(addr, kind)
                                         return kind == "tape_drive"
                                      end),
                         function(addr, kind)
                           return addr, component.proxy(addr)
  end)
end

function IdDir.list()
  local r = {}
  
  for addr, drive in tape_drives() do
    if drive.isReady() then
      table.insert(r, string.sub(addr, 1, 8))
    end
  end

  return r
end

function IdDir.isDirectory(path)
  return false
end

function IdDir.exists(path)
  local a = component_get(path)
  if a and a.isReady() then
    return true
  else
    return false
  end
end

-------

local LabelDir = {}

function LabelDir.find_drive_with_label(label)
  for _, drive in tape_drives() do
    if drive.getLabel() == label then
      return drive
    end
  end
end

function LabelDir.open(path, mode)
  local drive = LabelDir.find_drive_with_label(path)
  assert(drive, "Invalid tape label")
  return Node:new(drive.address, mode)
end

function LabelDir.list()
  local r = {}

  for _, drive in tape_drives() do
    local l = drive.getLabel()
    if drive.isReady() and l and l ~= "" then
      table.insert(r, l)
    end
  end

  return r
end

function LabelDir.isDirectory(path)
  return false
end

function LabelDir.exists(path)
  local drive = LabelDir.find_drive_with_label(path)
  return drive and drive.isReady()
end

-------

local primary_node = {
  tape_drives = tape_drives
}

function primary_node.open(mode)
  local tape = component.tape_drive
  return Node:new(tape.address, mode)
end

local devfs = require("devfs")
devfs.create("tape", primary_node)
devfs.create("tapes/by-id", IdDir)
devfs.create("tapes/by-label", LabelDir)

return primary_node
