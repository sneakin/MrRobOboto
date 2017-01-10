local math = require("math")
local string = require("string")
local vec3d = {}

function vec3d:__tostring()
   return string.format("<%f, %f, %f>", self.x, self.y, self.z)
end

function vec3d:__add(other)
   return vec3d:new(self.x + other.x, self.y + other.y, self.z + other.z)
end

function vec3d:__sub(other)
   return vec3d:new(self.x - other.x, self.y - other.y, self.z - other.z)
end

function vec3d:__unm()
   return self * -1
end

function vec3d:__mul(other)
   if type(other) == "table" then
      return vec3d:new(self.x * other.x, self.y * other.y, self.z * other.z)
   else
      return vec3d:new(self.x * other, self.y * other, self.z * other)
   end
end

function vec3d:__div(other)
   if type(other) == "table" then
      return vec3d:new(self.x / other.x, self.y / other.y, self.z / other.z)
   else
      return vec3d:new(self.x / other, self.y / other, self.z / other)
   end
end

function vec3d:__lt(other)
  return self.x < other.x and self.y < other.y and self.z < other.z
end

function vec3d:new(...)
   local v = {}
   setmetatable(v, self)
   self.__index = self
   
   return v:set(...)
end

function vec3d:set(...)
   local args = {...}

   if #args == 1 then
      local v = args[1]
      self.x = v.x
      self.y = v.y
      self.z = v.z
   elseif #args == 3 then
      self.x = args[1]
      self.y = args[2]
      self.z = args[3]
   elseif #args > 0 then
      error("argument error", 2)
   else
      self.x = 0
      self.y = 0
      self.z = 0
   end

   return self
end

function vec3d:length_squared()
   return self.x * self.x + self.y * self.y + self.z * self.z
end

function vec3d:length()
   return math.sqrt(self:length_squared())
end

vec3d.origin = vec3d:new()
vec3d.X = vec3d:new(1, 0, 0)
vec3d.Y = vec3d:new(0, 1, 0)
vec3d.Z = vec3d:new(0, 0, 1)

return vec3d
