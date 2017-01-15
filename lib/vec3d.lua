local math = require("math")
local string = require("string")
local number = require("sneaky/number")
local sneaky = require("sneaky/util")
local vec3d = {}

function vec3d:__tostring()
   return string.format("<%f, %f, %f, %f>", self.x, self.y, self.z, self.w)
end

function vec3d:__add(other)
   return vec3d:new(self.x + other.x, self.y + other.y, self.z + other.z, self.w + other.w)
end

function vec3d:__sub(other)
   return vec3d:new(self.x - other.x, self.y - other.y, self.z - other.z, self.w - other.w)
end

function vec3d:__unm()
   return self * -1
end

function vec3d:__mul(other)
  if type(self) == "number" then
    return vec3d:new(self * other.x, self * other.y, self * other.z, self * other.w)
  else
    if type(other) == "table" then
      return vec3d:new(self.x * other.x, self.y * other.y, self.z * other.z, self.w * other.w)
    else
      return vec3d:new(self.x * other, self.y * other, self.z * other, self.w * other)
    end
  end
end

function vec3d:__div(other)
  if type(self) == "number" then
    return vec3d:new(self / other.x, self / other.y, self / other.z, self / other.w)
  else
    if type(other) == "table" then
      return vec3d:new(self.x / other.x, self.y / other.y, self.z / other.z, self.w / other.w)
    else
      return vec3d:new(self.x / other, self.y / other, self.z / other, self.w / other)
    end
  end
end

function vec3d:__lt(other)
  return self.x < other.x and self.y < other.y and self.z < other.z
end

function vec3d:new(...)
  local i = sneaky.class(self, {})
  return i:set(...)
end

function vec3d:set(...)
   local args = {...}

   if #args == 1 then
      local v = args[1]
      self.x = v.x or 0
      self.y = v.y or 0
      self.z = v.z or 0
      self.w = v.w or 1
   elseif #args <= 4 then
      self.x = args[1] or 0
      self.y = args[2] or 0
      self.z = args[3] or 0
      self.w = args[4] or 1
   elseif #args > 0 then
      error("argument error", 2)
   else
      self.x = 0
      self.y = 0
      self.z = 0
      self.w = 1
   end

   return self
end

function vec3d:length_squared()
   return self.x * self.x + self.y * self.y + self.z * self.z
end

function vec3d:length()
   return math.sqrt(self:length_squared())
end

function vec3d:signed_length()
  local l = self:length()
  if self.x < 0 or self.y < 0 or self.z < 0 then
    return -l
  else
    return l
  end
end

function vec3d:minmax(other)
  local ax, bx = number.minmax(self.x, other.x)
  local ay, by = number.minmax(self.y, other.y)
  local az, bz = number.minmax(self.z, other.z)
  local aw, bw = number.minmax(self.w, other.w)
  
  return vec3d:new(ax, ay, az, aw), vec3d:new(bx, by, bz, bw)
end

vec3d.origin = vec3d:new()
vec3d.X = vec3d:new(1, 0, 0)
vec3d.Y = vec3d:new(0, 1, 0)
vec3d.Z = vec3d:new(0, 0, 1)
vec3d.W = vec3d:new(0, 0, 0, 1)

return vec3d
