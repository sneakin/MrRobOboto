local sneaky = require("sneaky/util")
local CallbackList = require("sneaky/callback_list")
local fs = require("filesystem")
local serialization = require("serialization")
local StoredTable = {
  ELEMENT_EXT = "lua"
}

local NullKind = {}
function NullKind:from_table(tbl)
  return tbl
end
function NullKind.to_table(tbl)
  if type(tbl) == "table" then
    return sneaky.copy(tbl)
  else
    return tbl
  end
end

local Proxy = require("sneaky/proxy")
local RecordProxy = sneaky.copy(Proxy)
StoredTable.RecordProxy = RecordProxy

function RecordProxy:new(tbl, id, to)
  return sneaky.class(self, { tbl = tbl, id = id, to = to })
end

function RecordProxy:save()
  self.tbl:save(self.id, self)
  return self
end

function RecordProxy:reload()
  local i = self.tbl:load(self.id)
  self.to = i
  return self
end

function RecordProxy:test()
  local to = { a = 1, b = 2 }
  local save_args, load_args
  local tbl = {
    save = function(t, k, v)
      save_args = { k, v }
    end,
    load = function(t, k)
      load_args = k
      return { x = 1 }
    end
  }
  local r = RecordProxy:new(tbl, "some-id", to)
  assert(r.id == "some-id", r.id)
  assert(r.a == 1, r.a)
  assert(r.b == 2, r.b)

  assert(r:save() == r)
  assert(save_args[1] == "some-id", save_args[1])
  assert(save_args[2] == r, save_args[2])

  assert(r:reload() == r)
  assert(load_args == "some-id", load_args)
  assert(r.x == 1)
  assert(r.a == nil)
end


function StoredTable:new(dir, klass)
  assert(fs.isDirectory(dir) or not fs.exists(dir), "not a directory")
  assert(klass == nil or klass.from_table, "not a class")

  if not fs.exists(dir) then
    fs.makeDirectory(dir)
  end
  
  return sneaky.class(self, { dir = dir,
                              kind = klass or NullKind,
                              _observers = CallbackList:new()
  })
end

function StoredTable:__index(key)
  return StoredTable[key] or self:load(key)
end

function StoredTable:__newindex(key, value)
  return self:save(key, value)
end

function StoredTable:path_for(key, tmp)
  local ext = StoredTable.ELEMENT_EXT
  if tmp then
    ext = "tmp"
  end

  return sneaky.pathjoin(self.dir, key .. "." .. ext)
end

function StoredTable:path_key(path)
  local f = sneaky.basename(path)
  f = f:gsub("[.]" .. sneaky.extname(path), "")
  return f
end

function StoredTable:instantiate(key, data)
  if type(data) == "table" then
    return RecordProxy:new(self, key, self.kind:from_table(data))
  else
    return data
  end
end


function StoredTable:save(key, value)
  if value then
    local orig_path = self:path_for(key, true)
    local f = io.open(orig_path, "w")
    local data
    data = serialization.serialize(self.kind.to_table(value))
    f:write(data):close()

    local path = self:path_for(key)
    local new = (not fs.exists(path))
    fs.remove(path)
    fs.rename(orig_path, path)
    self._observers:call("save", self[key], new)
  else
    fs.remove(self:path_for(key))
    self._observers:call("delete", key)
  end
  
  return self[key]
end

function StoredTable:load(key)
  local f = io.open(self:path_for(key), "r")
  local data
  if f then
    data = serialization.unserialize(f:read("*a"))
    if not data then
      data = {}
    end
  end
  return self:instantiate(key, data)
end

function StoredTable:copy(dest)
  local new_tbl = StoredTable:new(dest, self.kind)
  for k,v in self:pairs() do
    new_tbl[k] = v
  end
  return new_tbl
end

function StoredTable:keys()
  return sneaky.iter_map(sneaky.search(fs.list(self.dir), function(file) return sneaky.extname(file) == StoredTable.ELEMENT_EXT end),
                         function(file) return self:path_key(file) end)
end

function StoredTable:pairs()
  return sneaky.iter_map(self:keys(),
                         function(key)
                           return key, self:load(key)
  end)
end

function StoredTable:len()
  return sneaky.count(self:keys())
end

function StoredTable:observe(func)
  return self._observers:add(func)
end

function StoredTable:unobserve(id)
  return self._observers:remove(id)
end

StoredTable.TestRecord = {
  from_table = function(self, tbl)
    local i = sneaky.class(self, {
                             name = tbl[1],
                             age = tbl[2]
    })
    return i
  end,
  to_table = function(self)
    return { self.name, self.age }
  end,
  __eq = function(self, other)
    return self.name == other.name and self.age == other.age
  end
}

function StoredTable.test()
  fs.remove("/tmp/stored-table")
  local s = StoredTable:new("/tmp/stored-table")
  s["hello"] = 123
  s["world"] = 345

  assert(s["hello"] == 123, s["hello"])
  assert(s["world"] == 345, s["world"])
  assert(s:len() == 2)
  assert(s:len() == 2)

  s = StoredTable:new("/tmp/stored-table")
  assert(s["hello"] == 123, s["hello"])
  assert(s["world"] == 345, s["world"])
  assert(s:len() == 2)
  assert(s:len() == 2)

  local keys = s:keys()
  local result = { keys(), keys() }
  table.sort(result)
  assert(result[1] == "hello", result[1])
  assert(result[2] == "world", result[2])

  fs.remove("/tmp/stored-table")

  s = StoredTable:new("/tmp/stored-table", StoredTable.TestRecord)
  local called = false
  for k, v in s:pairs() do
    called = true
  end
  assert(called == false)
  
  s["alice"] = StoredTable.TestRecord:from_table({ "Alice", 23 })
  s["bob"] = StoredTable.TestRecord:from_table({ "Bob", 45 })
  --s["bob"] = { "Bob", 45 }
  assert(s["alice"].name == "Alice")
  assert(s["alice"].age == 23)
  assert(s["bob"].name == "Bob")
  assert(s["bob"].age == 45)

  assert(s:len() == 2)

  a = s:copy("/tmp/stored-table-2")
  assert(fs.isDirectory("/tmp/stored-table-2"))
  assert(a.dir == "/tmp/stored-table-2")
  for k,v in s:pairs() do
    assert(a[k] == s[k])
  end
  
  fs.remove("/tmp/stored-table")
  fs.remove("/tmp/stored-table-2")
end

return StoredTable
