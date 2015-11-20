local DEBUG = true

local sides = require("sides")
local vec3d = require("vec3d")
local sneaky = require("sneaky/util")
local table = require("table")
local flipped_sides = require("rob/flipped_sides")
local good, serialization = pcall(require, "serialization")
if not good then
   serialization = nil
end

local router = {}

function router:new()
   return sneaky.class(self, { nodes = {}, paths = {}})
end

function router:add_node(name, location)
   self.nodes[name] = location
   return self
end

function router:add_path(from, from_side, to, to_side, path, cost, weight)
   table.insert(self.paths, {
                   from = from,
                   from_side = from_side,
                   to = to,
                   to_side = to_side,
                   path = path,
                   cost = (cost or 1),
                   weight = (weight or 1)
   })
   return self
end

function router:reverse_path(path)
   local rev = sneaky.reverse(path)

   for i, cmd in ipairs(rev) do
      if cmd[1] == "turn" then
         rev[i] = { "turn", -cmd[2] }
      elseif cmd[1] == "up" then
         rev[i] = { "down", cmd[2] }
      elseif cmd[1] == "down" then
         rev[i] = { "up", cmd[2] }
      end
   end
   
   return rev
end

function router:add_bipath(from, from_side, to, to_side, path, cost, weight)
   return self:
      add_path(from, from_side, to, to_side, path, cost, weight):
      add_path(to, to_side, from, from_side, self:reverse_path(path), cost, weight)
end

function router:find_paths(node)
   return sneaky.ifind(self.paths, function(_, path)
                          return path.from == node or path.to == node
   end)
end

function router:find_path(from, to)
   return sneaky.findFirst(self.paths, function(_, path)
                              return path.from == from and path.to == to
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

function router:distance_between(a, b)
   local f = assert(self.nodes[a], "node not found: " .. a)
   local t = assert(self.nodes[b], "node not found: " .. b)

   return (t - f):length()
end

function diacomment(s, ...)
   if DEBUG then
      if serialization then
         io.stderr:write("// " .. s .. "\t" .. serialization.serialize({...}) .. "\n")
      else
         io.stderr:write("// " .. s .. "\t" .. table.concat({...}, "\t") .. "\n")
      end
   end
end

function router:route(from, to, f_score, g_score)
   diacomment("route", from, to)

   if from == to then
      return nil
   end

   local open = { from }
   local closed = {}
   local came_from = {}

   if not g_score then
      g_score = sneaky.table(math.huge)
      g_score[from] = 0
   end

   if not f_score then
      f_score = sneaky.table(math.huge)
      f_score[from] = self:distance_between(from, to)
   end
   
   while #open > 0 do
      local i, current = sneaky.min(open, function(a, b) return f_score[a] < f_score[b] end)
      if current == to then
         return self:reconstruct_route(came_from, to), f_score, g_score
      end

      diacomment("Trying " .. current)

      table.remove(open, i)
      table.insert(closed, current)

      local edges = self:find_paths_from(current)
      for _, edge in ipairs(edges) do
         if not sneaky.findFirstValue(closed, edge.to) then
            local score = g_score[current] + edge.cost
            if not sneaky.findFirstValue(open, edge.to) then
               diacomment("Queuing " .. edge.to)
               table.insert(open, edge.to)
            end

            if score < g_score[edge.to] then
               came_from[edge.to] = current
               g_score[edge.to] = score
               f_score[edge.to] = g_score[edge.to] + self:distance_between(edge.to, to) * edge.weight
            end
         end
      end
   end
end

function router:reconstruct_route(came_from, current)
   local route = {}

   while came_from[current] do
      local i, path = self:find_path(came_from[current], current)
      current = came_from[current]
      table.insert(route, path)
   end

   return sneaky.reverse(route)
end

function router:turn_amount(from_side, to_side)
   local tbl = {
      [ sides.east ] = {
         [ sides.east ] = 0,
         [ sides.west ] = 2,
         [ sides.north ] = 1,
         [ sides.south ] = -1
      },
      [ sides.west ] = {
         [ sides.west ] = 0,
         [ sides.east ] = 2,
         [ sides.north ] = -1,
         [ sides.south ] = 1
      },
      [ sides.north ] = {
         [ sides.east ] = -1,
         [ sides.west ] = 1,
         [ sides.north ] = 0,
         [ sides.south ] = 2
      },
      [ sides.south ] = {
         [ sides.east ] = 1,
         [ sides.west ] = -1,
         [ sides.north ] = 2,
         [ sides.south ] = 0
      }
   }

   if (from_side == sides.up or from_side == sides.down) or
      (to_side == sides.up or to_side == sides.down)
   then
      return 0
   else
      return tbl[from_side][to_side]
   end
end

function router:to_path(route, facing)
   facing = facing or flipped_sides[route[1].from_side]
   
   local path = { }
   
   for i, edge in ipairs(route) do
      local turn = self:turn_amount(facing, edge.from_side)

      if not (turn == 0) then
         table.insert(path, { "turn", turn })
         facing = edge.from_side
      end
      
      for k, cmd in ipairs(edge.path) do
         table.insert(path, cmd)
      end
      
      if not (edge.to_side == sides.up) and not (edge.to_side == sides.down) then
         facing = flipped_sides[edge.to_side]
      end
   end

   return path, facing
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

   r:add_bipath("charger", sides.north, "hub", sides.south, {{"forward", 16}}, 16)
   r:add_bipath("hub", sides.up, "vault", sides.down, {{"up", 10}}, 10)
   r:add_bipath("vault", sides.up, "machines", sides.down, {{"up", 10}}, 10)
   r:add_bipath("hub", sides.north, "lumber", sides.south,
                { { "forward", 16 }, { "turn" }, { "forward", 32 } },
                48)
   r:add_bipath("hub", sides.north, "mine", sides.south, { { "down", 50 }, { "forward", 16 } }, 66)

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
            r:add_bipath("building-" .. (building - 1), sides.south, prefix, sides.north, {{"forward", 16}}, 16)
         end
         if col > 1 then
            r:add_bipath("building-" .. (col - 2) * rows + (row - 1), sides.east, prefix, sides.west, {{"forward", 16}}, 16)
         end
         
         r:add_bipath(prefix, sides.east, prefix .. ":hub", sides.west, {{"forward", 8}}, 8)
         r:add_bipath(prefix .. ":hub", sides.east, prefix .. ":charger", sides.west, {{"forward", 8}}, 8)
         r:add_bipath(prefix .. ":hub", sides.up, prefix .. ":vault", sides.down, {{"up", 8}}, 8)
         r:add_bipath(prefix .. ":hub", sides.down, prefix .. ":teleporter", sides.up, {{"down", 8}}, 8)
         r:add_bipath(prefix .. ":vault", sides.up, prefix .. ":machines", sides.down, {{"up", 8}}, 8)
      end
   end

   local num_buildings = cols * rows
   r:add_bipath("building-1:teleporter", sides.east, "building-" .. math.floor(num_buildings / 2) .. ":teleporter", sides.west, {{"use"}}, 1, 0.1)
   r:add_bipath("building-" .. math.floor(num_buildings / 4) .. ":teleporter", sides.east, "building-" .. math.floor(3 * num_buildings / 4) .. ":teleporter", sides.west, {{"use"}}, 1, 0.1)
      
   return r
end

function router_test.dump_graph(r, from, to, highlighted_path, f_score, g_score)
   print("digraph router_test {")
   print("  overlap=false;")
   
   for name, position in pairs(r.nodes) do
      local attrs = "label=\"" .. name .. " " .. position:__tostring() .. "\""
      if name == from then
         attrs = attrs .. ",color=\"#ffcccc\",style=filled,rank=1"
      elseif name == to then
         attrs = attrs .. ",color=\"#ccccff\",style=filled,rank=1000"
      elseif sneaky.findFirst(highlighted_path, function(k,v) return v.to == name or v.from == name end) then
         attrs = attrs .. ",color=\"#ccffcc\",style=filled"
      end
      print("  \"" .. name .. "\"[" .. attrs .. "];")
   end

   for i, path in ipairs(r.paths) do
      --local attrs = "label=\"" .. path.cost .. "\n" .. math.floor(r:distance_between(path.to, to)) .. "\""
      local attrs = "label=\"" .. math.floor(f_score[path.to]) .. "\n" .. math.floor(g_score[path.to]) .. "\""
      if highlighted_path and sneaky.findFirst(highlighted_path, function(_, p)
                                                  return (p.from == path.from and p.to == path.to)
                                              end)
      then
         attrs = attrs .. ",color=\"red\",style=bold"
      end
      print("  \"" .. path.from .. "\" -> \"" .. path.to .. "\"[" .. attrs .. "];")
   end

   print("}")
end

function router_test.print_route(path)
   if #path > 0 then
      diacomment("Route:")
      for i, edge in ipairs(path) do
         local cmd = sneaky.reduce(sneaky.spairs(edge.path), {}, function(acc, k, cmd)
                                      table.insert(acc, table.concat(cmd, ", "))
                                      return acc
         end)
         
         diacomment(i, edge.from, edge.from_side, edge.to, edge.to_side, "{ " .. table.concat(cmd, ", ") .. " }")
      end
   else
      diacomment("No route found.")
   end
end

function router_test.print_path(path)
   if #path > 0 then
      diacomment("Path:", #path)
      for i, cmd_list in ipairs(path) do
         diacomment(i, "{ " .. table.concat(cmd_list, ", ") .. " }")
      end
   else
      diacomment("No path.")
   end
end

function router_test.run(r, from, to)
   local route, f_score, g_score = r:route(from, to)
   router_test.dump_graph(r, from, to, route, f_score, g_score)
   router_test.print_route(route)
   router_test.print_path(r:to_path(route))
   router_test.print_path(r:reverse_path(r:to_path(route)))
end

function router_test.run1()
   local r = router_test.populate()
   router_test.run(r, "charger", "machines")
end

function router_test.run2()
   local r = router_test.populate()
   router_test.run(r, "charger", "mine")
end

function router_test.run3(x, y, building)
   x = x or 4
   y = y or 4
   building = building or (y / 2) * x + (x / 2)
   local r = router_test.big_populate(x, y)
   router_test.run(r, "building-1:charger", "building-" .. building .. ":machines")
end

router.test = router_test

-------

return router
