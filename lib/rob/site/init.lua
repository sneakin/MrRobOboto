local sneaky = require("sneaky/util")
local router = sneaky.reload("rob/site/router")

local StoredTable = require("sneaky/stored_table")
local RobotRecord = require("rob/site/robot_record")
local serialization = require("serialization")

local site = {}

site.Zones = sneaky.reload("rob/site/zones")

function site:new(name, dir)
  return sneaky.class(self, {
                        name = name or "Untitled",
                        _dir = dir,
                        _players = {},
                        _nodes = {},
                        _paths = {},
                        _zones = {},
                        _robots = StoredTable:new(sneaky.pathjoin(dir, "robots"), RobotRecord),
                        _router = router:new()
  })
end

function site:add_node(name, position, kind)
  self._nodes[name] = kind or "unknown"
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

function site:find_node(name)
  if self._router.nodes[name] then
    return self._router.nodes[name], self._nodes[name]
  end
end

function site:add_path(from, from_side, to, to_side, path, cost, weight)
  self._router:add_path(from, from_side, to, to_side, path, cost, weight)
  table.insert(self._paths, { nil, from, from_side, to, to_side, path, cost, weight })
  return self
end

function site:add_bipath(from, from_side, to, to_side, path, cost, weight)
  self._router:add_bipath(from, from_side, to, to_side, path, cost, weight)
  table.insert(self._paths, { true, from, from_side, to, to_side, path, cost, weight })
  return self
end

function site:user_paths()
  return sneaky.pairs(self._paths)
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

function site:check_secret(secret)
  return true
end

function site:generate_secret()
  return "nope"
end


function site:find_robot(address)
  return self._robots[address]
end

function site:find_robot_by_name(name)
  for addr, robot in self:robots() do
    if robot.name == name then
      return robot
    end
  end
end

function site:bless_robot(name, modem, computer, robot)
  local seen = self._robots[modem]
  if seen then
    seen.name = name
    seen.modem_addr = modem
    seen.authorized = true
    seen.blessed = true
    seen:save()
    self._robots[modem] = seen
  else
    self._robots[modem] = RobotRecord:new(name, modem, computer, robot, nil, true, true)
  end

  return self
end

function site:track_robot(modem_addr)
  local robot = self._robots[modem_addr]
  if not robot then
    self._robots[modem_addr] = RobotRecord:new(nil, modem_addr)
    robot = self._robots[modem_addr] -- get the proxied version
  end
  
  robot.last_seen = os.time()
  robot:save()
  
  return self
end

function site:robot_update(addr, distance, record)
  local robot = self:find_robot(addr)
  if robot then
    --self._robots[addr] = robot:update_stats(record, distance)
    robot
      :update_stats(record, distance)
      :save()
    return true
  else
    self:track_robot(addr)
    return nil
  end
end

function site:unauthorized_robots()
  return sneaky.search(self._robots:pairs(),
                       function(addr, record)
                         return record.name == nil and record.authorized == nil
  end)
end

function site:robots()
  return self._robots:pairs()
end

function site:add_robot_observer(func)
  return self._robots:observe(func)
end

function site:remove_robot_observer(id)
  return self._robots:unobserve(id)
end


local SiteSerializer = require("rob/site/serializer")

function site:save(path)
  SiteSerializer.save(self, path or self._dir)
  return self
end

function site.load(path)
  local site_file = loadfile(sneaky.pathjoin(path, "init.lua"))
  if site_file then
    local new_site = site:new(nil, path)
    local ok, reason = pcall(site_file, new_site)
    if not ok then
      return ok, reason
    else
      return new_site
    end
  else
    return site:new("Untitled", path)
  end
end

function site.instance()
  if site._instance then
    return site._instance
  end

  error("no site loaded")
  --site._instance = site:new()
  --return site._instance
end

function site.load_instance(path)
  local s = site.load(path)
  if s then
    site._instance = s
    return s
  else
    return nil
  end
end

return site
