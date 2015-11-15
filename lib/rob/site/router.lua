local DEBUG = true

local vec3d = require("vec3d")
local sneaky = require("sneaky/util")
local table = require("table")

local pqueue = {}

function pqueue:new()
   return sneaky.class(self, {})
end

function pqueue:push(item, priority)
end

function pqueue:pop()
end

local router = {}

function router:new()
   return sneaky.class(self, { nodes = {}, paths = {}})
end

function router:add_node(name, location)
   self.nodes[name] = location
   return self
end

function router:add_path(from, to, path, cost, weight)
   table.insert(self.paths, {
                   from = from,
                   to = to,
                   path = path,
                   cost = (cost or 1),
                   weight = (weight or 1)
   })
   return self
end

function router:reverse_path(path)
   return path -- TODO
end

function router:add_bipath(from, to, path, cost, weight)
   return self:add_path(from, to, path, cost, weight):add_path(to, from, self:reverse_path(path), cost, weight)
end

function router:find_paths(node)
   return sneaky.ifind(self.paths, function(_, path)
                          return path.from == node or path.to == node
   end)
end

function router:find_paths_from(node)
   return sneaky.ifind(self.paths, function(_, path)
                          return path.from == node
   end)
end

function router:weight(path, to)
   local f = assert(self.nodes[path.to], "node not found: " .. path.to)
   local t = assert(self.nodes[to], "node not found: " .. to)

   return path.weight * (t - f):length()
end

function router:weighted_paths(from, to)
   local paths = self:find_paths_from(from)

   table.sort(paths, function(a, b)
                 return (a.cost + self:weight(a, to)) < (b.cost + self:weight(b, to))
   end)

   -- for i, v in ipairs(paths) do
   --    print(from, to, i, v.from, self:weight(v, to), self:weight(v, to))
   -- end

   return sneaky.subtable(paths, 1, 5)
end

function router:seen(node, accum)
   return sneaky.findFirst(accum, function(_, p)
                              return node == p.to or node == p.from
   end)
end

function router:cost(route)
   local c = 0
   for i, p in ipairs(route) do
      c = c + p.cost
   end
   return c
end

function diacomment(s, ...)
   if DEBUG then
      io.stderr:write("// " .. s .. table.concat({...}, "\t") .. "\n")
   end
end

function router:route(from, to, accum, tried_paths)
   if not accum then
      accum = {}
   end

   if not tried_paths then
      tried_paths = {}
   end

   diacomment("route", from, to)
   diacomment("  accum")
   for i, p in ipairs(accum) do
      diacomment("     ", i, p.from, p.to)
   end
   
   local paths = self:weighted_paths(from, to)
   local routes = {}
   
   diacomment("  paths")
   for i, path in ipairs(paths) do
      diacomment("    path", i, path.from .. "->" .. path.to, self:weight(path, to))
      if path.to == to then
         print("//      BINGO")
         table.insert(routes, sneaky.append(accum, path))
         --break
      elseif not self:seen(path.to, accum) --and
      --not sneaky.findFirst(tried_paths, function(_, p) return p.to == path.to and p.from == path.from end)
      then
         local r
         r = self:route(path.to, to, sneaky.append(accum, path), tried_paths)
         if r then
            table.insert(routes, r)
            --break
         end
      end

      table.insert(tried_paths, path)
   end
   
   if #routes == 0 then
      return nil
   else
      return sneaky.min(routes, function(a, b)
                           return self:cost(a) < self:cost(b)
      end)
   end
end

-----

local router_test = {}

function router_test.populate(r)
   if not r then
      r = router:new()
   end
   r:add_node("hub", vec3d:new(16, 65, 0))
   r:add_node("charger", vec3d:new(0, 65, 0))
   r:add_node("lumber", vec3d:new(32, 65, 32))
   r:add_node("mine", vec3d:new(32, 15, 0))
   r:add_node("vault", vec3d:new(16, 75, 0))
   r:add_node("machines", vec3d:new(16, 85, 0))

   r:add_bipath("charger", "hub", {{forward, 16}}, 16)
   r:add_bipath("hub", "vault", {{up, 10}}, 10)
   r:add_bipath("vault", "machines", {{up, 10}}, 10)
   r:add_bipath("hub", "lumber",
                { { forward, 16 }, { turn }, { forward, 32 } },
                48)
   r:add_bipath("hub", "mine", { { down, 50 }, { forward, 16 } }, 66)

   return r
end

function router_test.big_populate(rows, cols)
   local r = router:new()

   for col = 1, cols do
      for row = 1, rows do
         local building = (col - 1) * rows + (row - 1)
         local prefix = "building-" .. building
         local street_pos = vec3d:new(row * 16, 65, col * 16)

         r:add_node(prefix, street_pos)
         r:add_node(prefix .. ":hub", street_pos + vec3d:new(0, 0, 8))
         r:add_node(prefix .. ":charger", street_pos + vec3d:new(0, 0, 16))
         r:add_node(prefix .. ":vault", street_pos + vec3d:new(0, 8, 8))
         r:add_node(prefix .. ":machines", street_pos + vec3d:new(0, 16, 8))
         r:add_node(prefix .. ":teleporter", street_pos + vec3d:new(0, -8, 8))

         if row > 1 then
            r:add_bipath("building-" .. (building - 1), prefix, {{forward, 16}}, 16)
         end
         if col > 1 then
            r:add_bipath("building-" .. (col - 2) * rows + (row - 1), prefix, {{forward, 16}}, 16)
         end
         
         r:add_bipath(prefix, prefix .. ":hub", {{forward, 8}}, 8)
         r:add_bipath(prefix .. ":hub", prefix .. ":charger", {{forward, 8}}, 8)
         r:add_bipath(prefix .. ":hub", prefix .. ":vault", {{up, 8}}, 8)
         r:add_bipath(prefix .. ":hub", prefix .. ":teleporter", {{down, 8}}, 8)
         r:add_bipath(prefix .. ":vault", prefix .. ":machines", {{up, 8}}, 8)
      end
   end

   local num_buildings = cols * rows
   r:add_bipath("building-1:teleporter", "building-" .. math.floor(num_buildings / 2) .. ":teleporter", {{use}}, 1, 0.1)
   r:add_bipath("building-" .. math.floor(num_buildings / 4) .. ":teleporter", "building-" .. math.floor(3 * num_buildings / 4) .. ":teleporter", {{use}}, 1, 0.1)
      
   return r
end

function router_test.dump_graph(r, from, to, highlighted_path)
   print("digraph router_test {")
   
   for name, position in pairs(r.nodes) do
      local attrs = "label=\"" .. name .. " " .. position:__tostring() .. "\""
      if name == from then
         attrs = attrs .. ",color=\"#ffcccc\",style=filled,rank=1"
      elseif name == to then
         attrs = attrs .. ",color=\"#ccccff\",style=filled,rank=1000"
      end
      print("  \"" .. name .. "\"[" .. attrs .. "];")
   end

   for i, path in ipairs(r.paths) do
      local attrs = "label=\"" .. path.cost .. "\n" .. math.floor(r:weight(path, to)) .. "\""
      if highlighted_path and sneaky.findFirst(highlighted_path, function(_, p)
                                                  return (p.from == path.from and p.to == path.to)
                                              end)
      then
         attrs = attrs .. ",color=\"red\""
      end
      print("  \"" .. path.from .. "\" -> \"" .. path.to .. "\"[" .. attrs .. "];")
   end

   print("}")
end

function router_test.run(r, from, to)
   local path = r:route(from, to)
   router_test.dump_graph(r, from, to, path)
end

function router_test.run1()
   diacomment("routing charger to machines")
   local r = router_test.populate()
   local path = r:route("charger", "machines")
   if path then
      diacomment("Route:")
      for i, n in ipairs(path) do
         diacomment("", i, n.from, n.to)
      end
   else
      diacomment("no path")
   end
   router_test.dump_graph(r, "charger", "machines", path)
end

function router_test.run2()
   local r = router_test.populate()
   router_test.run(r, "charger", "mine")
end

function router_test.run3(x, y)
   local r = router_test.big_populate(x or 4, y or 4)
   router_test.run(r, "building-1:charger", "building-9:machines")
end

function router_test.run4()
   local r = router_test.big_populate(11,1)
   router_test.run(r, "building-1:charger", "building-10:machines")
end

function router_test.run5()
   local r = router_test.big_populate(6,4)
   router_test.run(r, "building-1:charger", "building-20:machines")
end

router.test = router_test

-------

return router
