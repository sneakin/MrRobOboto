local sneaky = require("sneaky/util")
local TableTables = {}

function TableTables:new()
  return sneaky.class(self, { _tables = {}, _values = {}  })
end

function TableTables:set(keys, value)
  local keys = sneaky.copy(keys)
  table.sort(keys)
  return self:_set(keys, value)
end

function TableTables:_set(keys, value)
  if #keys == 1 then
    self._values[keys[1]] = value
  elseif #keys > 1 then
    local tbl = self._tables[keys[1]]
    if not tbl then
      tbl = TableTables:new()
      self._tables[keys[1]] = tbl
    end

    tbl:set(sneaky.subtable(keys, 2), value)
  else
    error("No keys given")
  end
end

function TableTables:get(keys)
  local keys = sneaky.copy(keys)
  table.sort(keys)
  return self:_get(keys)
end

function TableTables:_get(keys)
  if #keys == 1 then
    return self._values[keys[1]]
  elseif #keys > 1 then
    local tbl = self._tables[keys[1]]
    return tbl:_get(sneaky.subtable(keys, 2))
  else
    error("No keys given")
  end
end

function TableTables:get_table(keys)
  local keys = sneaky.copy(keys)
  table.sort(keys)
  return self:_get_table(keys)
end

function TableTables:_get_table(keys)
  if #keys == 1 then
    return self._tables[keys[1]]
  elseif #keys > 1 then
    local tbl = self._tables[keys[1]]
    return tbl:_get_table(sneaky.subtable(keys, 2))
  else
    error("No keys given")
  end
end

function TableTables:to_table()
  local t = {}
  for k, v in pairs(self._values) do
    t[k] = v
  end
  for k, tbl in pairs(self._tables) do
    t[k] = { "table", t[k], tbl:to_table() }
  end
  return t
end

function TableTables.from_table(tbl)
  local tt = TableTables:new()
  for k, v in pairs(tbl) do
    if type(v) == "table" and v[1] == "table" then
      tt._values[k] = v[2]
      tt._tables[k] = TableTables.from_table(v[3])
    else
      tt._values[k] = v
    end
  end
  return tt
end

return TableTables
