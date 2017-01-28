local sneaky = require("sneaky/util")
local CBList = {}

function CBList:new()
  return sneaky.class(self, { _callbacks = {},
                              _next_id = 0
                     })
end

function CBList:next_id()
  self._next_id = self._next_id + 1
  return self._next_id
end

function CBList:add(func)
  local id = self:next_id()
  self._callbacks[id] = func
  return id
end

function CBList:remove(id)
  self._callbacks[id] = nil
end

function CBList:call(...)
  local results = {}
  
  for id, cb in pairs(self._callbacks) do
    results[id] = pcall(cb, ...)
  end

  return results
end

return CBList
