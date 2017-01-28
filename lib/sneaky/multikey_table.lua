local sneaky = require("sneaky/util")
local MultikeyTable = {}

function MultikeyTable:new()
  return sneaky.class(self, { _tables = {}, _values = {}  })
end

function MultikeyTable:set(keys, value)
  local keys = sneaky.copy(keys)
  return self:_set(keys, value)
end

function MultikeyTable:_set(keys, value)
  if #keys == 1 then
    self._values[keys[1]] = value
  elseif #keys > 1 then
    local tbl = self._tables[keys[1]]
    if not tbl then
      tbl = MultikeyTable:new()
      self._tables[keys[1]] = tbl
    end

    tbl:set(sneaky.subtable(keys, 2), value)
  else
    error("No keys given")
  end
end

function MultikeyTable:get(keys)
  local keys = sneaky.copy(keys)
  return self:_get(keys)
end

function MultikeyTable:_get(keys)
  if #keys == 1 then
    return self._values[keys[1]]
  elseif #keys > 1 then
    local tbl = self._tables[keys[1]]
    if tbl then
      return tbl:_get(sneaky.subtable(keys, 2))
    end
  else
    error("No keys given")
  end
end

function MultikeyTable:get_table(keys)
  local keys = sneaky.copy(keys)
  return self:_get_table(keys)
end

function MultikeyTable:_get_table(keys)
  if #keys == 1 then
    return self._tables[keys[1]]
  elseif #keys > 1 then
    local tbl = self._tables[keys[1]]
    return tbl:_get_table(sneaky.subtable(keys, 2))
  else
    error("No keys given")
  end
end

function MultikeyTable:to_table()
  local t = {}
  for k, v in pairs(self._values) do
    t[k] = v
  end
  for k, tbl in pairs(self._tables) do
    t[k] = { "table", t[k], tbl:to_table() }
  end
  return t
end

function MultikeyTable.from_table(tbl)
  local tt = MultikeyTable:new()
  for k, v in pairs(tbl) do
    if type(v) == "table" and v[1] == "table" then
      tt._values[k] = v[2]
      tt._tables[k] = MultikeyTable.from_table(v[3])
    else
      tt._values[k] = v
    end
  end
  return tt
end

function MultikeyTable:pair_state(starting_state, key)
  local state = {}
  state.value_f, state.value_tbl, state.value_i = pairs(self._values)
  state.tbl_f, state.tbl_tbl, state.tbl_i = pairs(self._tables)
  state.parent = starting_state
  if starting_state and #starting_state.keys > 0 then
    state.keys = sneaky.append(starting_state.keys, { key })
  else
    state.keys = { key }
  end
  return state
end

function MultikeyTable:pairs(starting_state)
  local state = self:pair_state()
  
  return function()
    local r
    
    repeat
      if state.value_f then
        state.value_i, r = state.value_f(state.value_tbl, state.value_i)
        if r then
          return sneaky.append(state.keys, { state.value_i }), r
        else
          state.value_f = nil
        end
      end
      
      state.tbl_i, r = state.tbl_f(state.tbl_tbl, state.tbl_i)
      if r then
        state = r:pair_state(state, state.tbl_i)
      else
        state = state.parent
      end
    until not state
    
    return nil
  end
end

return MultikeyTable
