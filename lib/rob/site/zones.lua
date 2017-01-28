local sneaky = require("sneaky/util")
local vec3d = require("vec3d")
local zones = {}

zones.box = {}
function zones.box:new(name, min, size)
  return sneaky.class(self, {
                        _name = name,
                        _min = min,
                        _size = size
  })
end

function zones.box:routes(router)
  router:add_node(self._name .. ":cornerstone", self:min())
  return self
end

function zones.box:totable()
  return {
    min = self._min:totable(),
    size = self._size:totable()
  }
end

function zones.box:min()
  return self._min
end

function zones.box:size()
  return self._size
end

zones.mine = {}
function zones.mine:new(name, min, size)
  return sneaky.class(self, {
                        _name = name,
                        _min = min,
                        _size = size
  })
end

function zones.mine:totable()
  return {
    min = self._min:totable(),
    size = self._size:totable()
  }
end

function zones.mine:routes(router)
  router:add_node(self._name .. ":cornerstone", self:min())
  return self
end

function zones.mine:min()
  return self._min
end

function zones.mine:size()
  return self._size
end

----

local sides = require("sides")
local glass = require("rob/buildings/glass")

zones.glass_building = {}

function zones.glass_building:new(name, corner_stone, width, length, level_height, levels, build_dir)
  return sneaky.class(self, {
                        name = name,
                        corner_stone = corner_stone,
                        width = width,
                        length = length,
                        level_height = level_height,
                        levels = levels,
                        build_dir = build_dir
  })
end

function zones.glass_building:totable()
  return {
    corner_stone = self.corner_stone:totable(),
    width = self.width,
    length = self.length,
    level_height = self.level_height,
    levels = self.levels,
    build_dir = self.build_dir
  }
end

function zones.glass_building:min()
  if self.build_dir == sides.north then
    return self.corner_stone + self:size() * vec3d:new(-1, 0, -1)
  elseif self.build_dir == sides.east then
    return self.corner_stone + self:size() * vec3d:new(0, 0, -1)
  elseif self.build_dir == sides.south then
    return self.corner_stone
  elseif self.build_dir == sides.west then
    return self.corner_stone + self:size() * vec3d:new(-1, 0, 0)
  else
    error("invalid building direction " .. tostring(self.build_dir))
  end
end

function zones.glass_building:size()
  return vec3d:new(self.width, self.level_height * self.levels, self.length)
end

function zones.glass_building:routes(router)
  glass.routes(router,
               self.name,
               self.corner_stone,
               self.build_dir,
               self.width,
               self.length,
               self.level_height,
               self.levels)
  return self
end

return zones

