local sneaky = require("sneaky/util")
local sides = require("sides")
local number = require("sneaky/number")
local vec3d = require("vec3d")
local mat4x4 = require("mat4x4")
local palette = require("sneaky/colors")
local colors = palette.instance32

local Renderer = {}

function Renderer:new(site, width, height)
  local i = sneaky.class(self, {
                           site = site,
                        _zoom = vec3d:new(1, 1, 1),
                        translation = vec3d:new(0, 0, 0),
                        _screen_transform = nil,
                        showing_nodes = true,
                        showing_paths = true,
                        showing_zones = true,
                        _path_colors = {},
                        width = width,
                        height = height,
                        _highlighting = false,
                        _highlighted_paths = {},
                        _highlighted_nodes = {},
                        _highlighted_zones = {}
  })
  i:screen_transform_y()
  return i
end

function Renderer:router()
  return self.site._router
end

function Renderer:zoom(z)
  if z then
    self._zoom = vec3d:new(z.x or self._zoom.x,
                           z.y or self._zoom.y,
                           z.z or self._zoom.z)
    return self:invalidate()
  else
    return self._zoom
  end
end

function Renderer:translate(v)
  if v then
    self.translation = vec3d:new(v.x or self.translation.x,
                                 v.y or self.translation.y,
                                 v.z or self.translation.z)
    return self:invalidate()
  else
    return self.translation
  end
end

function Renderer:zoom_to_fit()
  local min = { x = nil, y = nil, z = nil }
  local max = { x = nil, y = nil, z = nil }
  
  for name, position in pairs(self:router().nodes) do
    for _, e in ipairs({"x", "y", "z"}) do
      if min[e] == nil or position[e] < min[e] then
        min[e] = position[e]
      end
      if max[e] == nil or position[e] > max[e] then
        max[e] = position[e]
      end
    end
  end

  for name, zone in self.site:zones() do
    local pmin = zone:min()
    local pmax = pmin + zone:size()
    
    for _, e in ipairs({"x", "y", "z"}) do
      if min[e] == nil or pmin[e] < min[e] then
        min[e] = pmin[e]
      end
      if max[e] == nil or pmax[e] > max[e] then
        max[e] = pmax[e]
      end
    end
  end

  min = vec3d:new(min.x, min.y, min.z)
  max = vec3d:new(max.x, max.y, max.z)

  local margin = 2
  local screen_vec = vec3d:new(self.width - margin * 2, self.height - margin * 2, 0.0)
  local st_inv = self._screen_transform:as3x3():transpose()
  local rot_screen = st_inv * screen_vec
  local block_size = rot_screen / (max - min)

  local zoom = {}
  local view_trans = {}
  
  for _, e in ipairs({ "x", "y", "z"}) do
    local v = math.abs(rot_screen[e] / (max[e] - min[e]))
    if v > 0.0000001 then
      zoom[e] = v
      if block_size[e] < 0 then
        view_trans[e] = max[e] + margin / v
      else
        view_trans[e] = min[e] - margin / v
      end
    else
      zoom[e] = nil
      view_trans[e] = nil
    end
  end

  if self.debug then
    print(screen_vec, rot_screen, block_size)
    print(min, max, max - min)
    print(zoom.x, zoom.y, zoom.z)
    print(view_trans.x, view_trans.y, view_trans.z)
    print(self._screen_transform:as3x3():transpose())
    print(self._screen_transform)
    io.stdin:read()
  end
  
  return self:translate(view_trans):zoom(zoom):invalidate()
end

function Renderer:transform_point(p)
  return (p - self.translation)
end

function Renderer:project_point(p)
  return self:screen_coordinates(self:transform_point(p) * self._zoom)
end

function Renderer:screen_coordinates(p)
  return self._screen_transform * p
end

function Renderer:screen_transform(m)
  if m then
    assert(m:isA(mat4x4))
    self._screen_transform = m
    return self:invalidate()
  else
    return self._screen_transform
  end
end

function Renderer:screen_transform_x()
  return self:screen_transform(mat4x4.rotateY(math.pi / 2)
                                * mat4x4.scale(1, -1, 0, 0)
                                * mat4x4.translate(0, -self.height, 0))
end

function Renderer:screen_transform_y()
  return self:screen_transform(mat4x4.rotateX(math.pi / 2)
                                 * mat4x4.scale(1, -1, 0, 0)
                                 * mat4x4.translate(0, -self.height, 0))
end

function Renderer:screen_transform_z()
  return self:screen_transform(mat4x4.scale(1, -1, 0, 0)
                                 * mat4x4.translate(0, -self.height, 0))
end


function Renderer:draw_node(canvas, name, position, color)
  local p = self:project_point(position)
  if p.x > 0 and p.y > 0 and p.x <= self.width and p.y <= self.height then
    if not color then
      if self._highlighting then
        color = colors:rgb(80, 80, 80)
      else
        color = colors:get("white")
      end
    end
    
    canvas
      :set_foreground(color)
      :set_background("black")
      :set(p.x, p.y, "*")
  end
  
  return self
end

function Renderer:draw_paths(canvas)
  canvas
    :set_background("black")
    :set_foreground("white")

  if self.showing_paths then
    local color = colors:rgb(40, 40, 40)
    local saved_paths = {}
    
    for _, path in ipairs(self:router().paths) do
      self:draw_path(path, canvas)
    end
    
    for _, highlight in ipairs(self._highlighted_paths) do
      local path, color = table.unpack(highlight)
      self:draw_path(path, canvas, color, true)
    end
  end

  return self
end

function Renderer:draw_nodes(canvas)
  if self.showing_nodes then
    for name, position in pairs(self:router().nodes) do
      self:draw_node(canvas, name, position)
    end

    for _, highlight in ipairs(self._highlighted_nodes) do
      local name, color = table.unpack(highlight)
      self:draw_node(canvas, name, self:router().nodes[name], color)
    end
  end

  return self
end

function Renderer:draw_zone(canvas, name, zone, fg, bg)
  local p1 = self:project_point(zone:min())
  local p2 = self:project_point(zone:min() + zone:size())
  p1, p2 = p1:minmax(p2)
  local size = p2 - p1

  canvas
    :set_foreground(fg or colors:rgb(64, 64, 64))
    :set_background(bg or colors:rgb(32, 32, 32))
    :fill(math.floor(p1.x), math.floor(p1.y),
          math.ceil(size.x), math.ceil(size.y),
          " ")
    :draw_box(math.floor(p1.x), math.floor(p1.y),
              math.ceil(p2.x), math.ceil(p2.y))
    :set(p1.x + 1, p1.y, string.sub(name, 1, size.x - 2))
end

function Renderer:draw_zones(canvas)
  if self.showing_zones then
    local fg = colors:rgb(64, 64, 64)
    local bg = colors:rgb(32, 32, 32)

    if #self._highlighted_zones > 0 then
      fg = colors:rgb(32, 32, 32)
      bg = colors:rgb(16, 16, 16)
    end
    
    for name, zone in self.site:zones() do
      self:draw_zone(canvas, name, zone, fg, bg)
    end

    for _, name in ipairs(self._highlighted_zones) do
      local zone = self.site:zone(name)
      self:draw_zone(canvas, name, zone, colors:rgb(0, 255, 255), colors:rgb(32, 32, 32))
    end
  end

  return self
end

function Renderer:draw(canvas)
  canvas
    :set_foreground("white")
    :set_background("black")
    :clear()

  return self:draw_zones(canvas):draw_paths(canvas):draw_nodes(canvas):draw_status(canvas)
end

function Renderer:show_nodes(yes)
  self.showing_nodes = (not (not yes))
  return self
end

function Renderer:show_paths(yes)
  self.showing_paths = (not (not yes))
  return self
end

function Renderer:highlight_path(from, to, color)
  local _, path = self:router():find_path(from, to)
  if path then
    self._highlighting = true
    table.insert(self._highlighted_paths, { path, color })
    return self
  else
    error("Invalid path: " .. tostring(from) .. " -> " .. tostring(to))
  end
  
  return self:invalidate()
end

function Renderer:highlight_node(node, color)
  assert(self:router().nodes[node], "node not found")
  self._highlighting = true
  table.insert(self._highlighted_nodes, { node, color or colors:rand() })
  return self:invalidate()
end

function Renderer:highlight_route(from, to, color)
  local r = self:router():route(from, to)
  assert(r, "no route found between " .. tostring(from) .. " and " .. tostring(to))
  if r then
    color = color or colors:rand()
    for x, node in ipairs(r or {}) do
      self
        :highlight_path(node.from, node.to, color)
        :highlight_node(node.from, color)
        :highlight_node(node.to, color)
    end
  end

  return self
end

function Renderer:highlight_zone(name)
  assert(self.site:has_zone(name), "zone not found: " .. tostring(name))
  table.insert(self._highlighted_zones, name)
  return self:invalidate()
end

function Renderer:clear_highlights()
  self._highlighting = false
  self._highlighted_paths = {}
  self._highlighted_nodes = {}
  self._highlighted_zones = {}
  return self:invalidate()
end

Renderer._char_for_dirs = {
  [ sides.north ] = "^",
  [ sides.east ] = ">",
  [ sides.south ] = "v",
  [ sides.west ] = "<",
  [ sides.up ] = "U",
  [ sides.down ] = "d"
}

local TURN_MAPPING = {
  [ sides.north ] = 0,
  [ sides.west ] = 1,
  [ sides.south ] = 2,
  [ sides.east ] = 3
}

local REVERSE_TURN_MAPPING = sneaky.inverse(TURN_MAPPING)

function Renderer:turns_from(dir, amount)
  return REVERSE_TURN_MAPPING[(TURN_MAPPING[dir] + amount) % 4]
end

function Renderer:color_for_path(path)
  if not self._path_colors[path] then
    self._path_colors[path] = colors:rand()
  end
  
  return self._path_colors[path]
end

local flipped_sides = require("rob/flipped_sides")

function Renderer:draw_path(path, canvas, color, highlighted)
  local path_start = assert(self:router().nodes[path.from], "no from from which to draw: " .. tostring(path.from) .. "->" .. tostring(path.to))
  local path_end = assert(self:router().nodes[path.to], "no to to draw towards")

  local proj_start = self:project_point(path_start)
  local proj_end = self:project_point(path_end)
  
  if (proj_start >= vec3d.origin and proj_start.x <= self.width and proj_start.y <= self.height)
    or (proj_end >= vec3d.origin and proj_end.x <= self.width and proj_end.y <= self.height)
  then
    local p = path_start
    local dir = path.from_side

    if not color then
      if self._highlighting then
        color = colors:rgb(40, 40, 40)
      else
        color = self:color_for_path(path)
      end
    end
    
    canvas:set_background(color)
    
    for i, cmd in ipairs(path.path) do
      local cmd, arg = table.unpack(cmd)
      local to = vec3d:new()
      local char = self._char_for_dirs[dir]
      
      if cmd == "forward" then
        arg = arg or 1
        
        if dir == sides.north then
          to.z = to.z - arg
        elseif dir == sides.south then
          to.z = to.z + arg
        elseif dir == sides.east then
          to.x = to.x + arg
        elseif dir == sides.west then
          to.x = to.x - arg
        end
      elseif cmd == "back" then
        arg = arg or 1
        
        if dir == sides.north then
          to.z = to.z + arg
        elseif dir == sides.south then
          to.z = to.z - arg
        elseif dir == sides.east then
          to.x = to.x - arg
        elseif dir == sides.west then
          to.x = to.x + arg
        end
      elseif cmd == "up" then
        to.y = arg or 1
      elseif cmd == "down" then
        to.y = -arg or -1
      elseif cmd == "turn" then
        dir = self:turns_from(dir, arg or 1)
        if arg < 0 then
          char = "\\"
        else
          char = "/"
        end
      end

      if self._highlighting and not highlighted then
        char = " "
      end

      local from = self:project_point(p)
      local np = p + to
      local to_p = self:project_point(np)
      canvas:draw_line(math.floor(from.x), math.floor(from.y), math.floor(to_p.x), math.floor(to_p.y), char)
      p = np
    end
  end

  return self
end

function Renderer:draw_status(canvas)
  local lmsg = self.site.name
  local rmsg = string.format("%.0f,%.0f,%.0f @ %0.2f,%0.2f,%0.2f,%0.2f",
                            self.translation.x, self.translation.y, self.translation.z,
                            self._zoom.x, self._zoom.y, self._zoom.z, self._zoom.w)
  
  canvas
    :set_background("blue")
    :set_foreground("white")
    :fill(1, self.height, self.width, 1, " ")
    :set(1, self.height, lmsg)
    :set(1 + self.width - string.len(rmsg), self.height, rmsg)

  return self
end

function Renderer:scrollBy(x, y)
  local trans = vec3d:new(x, -y)
  local m = self._screen_transform:as3x3():transpose()
  local world_trans = m * trans / self._zoom
  for _, e in ipairs({"x", "y", "z"}) do
    if number.isnan(world_trans[e]) then
      world_trans[e] = 0
    end
  end
  return self:translate(self.translation + world_trans)
end

function Renderer:invalidate()
  self._invalidated = true
  return self
end

function Renderer:redraw(canvas)
  if self._invalidated then
    self:draw(canvas)
    self._inlavidated = false
  end

  return self
end

return Renderer
