local sneaky = require("sneaky/util")
local serialization = require("serialization")
local TableTables = require("sneaky/table_tables")

local EffectsMap = {}

function EffectsMap:new()
  return sneaky.class(self, { _inputs = TableTables:new(),
                              _effects = TableTables:new(),
                              seen_effects = {}
                     })
end

function EffectsMap:add(inputs, effects, stats)
  table.sort(effects)
  table.sort(inputs)
  
  self._inputs:set(inputs, { effects, stats })
  self._effects:set(effects, inputs)
  self.seen_effects[effects] = true
end

function EffectsMap:inputs_for(effect, ...)
  return self._effects:get({ effect, ... })
end

function EffectsMap:inputs_table(effect, ...)
  return self._effects:get_table({ effect, ... })
end

function EffectsMap:effects_for(input, ...)
  return self._inputs:get({ input, ... })
end

function EffectsMap:save(stream)
  stream:write(self:to_string())
end

function EffectsMap:to_string()
  return serialization.serialize({
      effects = self._effects:to_table(),
      inputs = self._inputs:to_table(),
      seen_effects = self.seen_effects
  })
end

function EffectsMap:load(stream)
  return self:load_from_string(stream:read())
end

function EffectsMap:load_from_string(str)
  local data = serialization.unserialize(str)

  self._effects = TableTables.from_table(data.effects)
  self._inputs = TableTables.from_table(data.inputs)
  self.seen_effects = data.seen_effects
  
  return self
end


return EffectsMap
