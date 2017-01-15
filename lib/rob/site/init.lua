local sneaky = require("sneaky/util")
local router = sneaky.reload("rob/site/router")

local site = {}

site.Zones = sneaky.reload("rob/site/zones")

function site:new(name)
  return sneaky.class(self, {
                        name = name or "Untitled",
                        _nodes = {},
                        _paths = {},
                        _zones = {},
                        _router = router:new()
  })
end

function site:add_node(name, position, kind)
  self._nodes[name] = kind
  self._router:add_node(name, position)
  return self
end

function site:nodes()
  local it = sneaky.pairs(self._nodes)
  return function()
    name, kind = it()
    if name then
      return name, self._router.nodes[name], kind
    else
      return nil, nil, nil
    end
  end
end

function site:add_path(from, from_side, to, to_side, path, cost, weight)
  self._router:add_path(from, from_side, to, to_side, path, cost, weight)
  return self
end

function site:add_bipath(from, from_side, to, to_side, path, cost, weight)
  self._router:add_bipath(from, from_side, to, to_side, path, cost, weight)
  return self
end

function site:paths()
  return sneaky.pairs(self._router.paths)
end

function site:merge_router_routes(router)
  self._router:copy(router)
  return self
end

function site:add_zone(name, kind, ...)
  assert(self._zones[name] == nil, "zone exists")
  assert(kind and kind.new, "invalid kind of zone")
  local inst = kind:new(name, ...)
  inst:routes(self._router)
  self._zones[name] = inst
  return self
end

function site:zones()
  return sneaky.pairs(self._zones)
end

function site:zone(name)
  return self._zones[name]
end

function site:has_zone(name)
  return self._zones[name] ~= nil
end

return site
