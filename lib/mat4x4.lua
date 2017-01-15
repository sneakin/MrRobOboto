local vec3d = require("vec3d")
local sneaky = require("sneaky/util")
local mat4x4 = {}

function mat4x4:new(other)
  if other and other.isA and other:isA(mat4x4) then
    return sneaky.class(self, { e = sneaky.copy(other.e)})
  elseif other and type(other) == "table" then
    local e = {}
    for i = 1, 16 do
      e[i] = other[i]
    end

    return sneaky.class(self, { e = e })
  else
    return sneaky.class(self, {
                          e ={
                            0, 0, 0, 0,
                            0, 0, 0, 0,
                            0, 0, 0, 0,
                            0, 0, 0, 0
                          }
    })
  end
end

function mat4x4:get(x, y)
  return self.e[(y - 1) * 4 + x]
end

function mat4x4:set(x, y, n)
  self.e[(y - 1) * 4 + x] = n
end

function mat4x4:__tostring()
  return string.format("[[%f, %f, %f, %f],[%f, %f, %f, %f],[%f, %f, %f, %f],[%f, %f, %f, %f]]", table.unpack(self.e))
end

function mat4x4:__add(other)
  local r = mat4x4:new()
  for i = 1, 16 do
    r.e[i] = self.e[i] + other[i]
  end
  return r
end

function mat4x4:__sub(other)
  local r = mat4x4:new()
  for i = 1, 16 do
    r.e[i] = self.e[i] - other[i]
  end
  return r
end

function mat4x4:as3x3()
  local m = self:minorM(4,4)
  m:set(4,4,1)
  return m
end

function mat4x4:transpose()
  local m = mat4x4:new()
  for i = 1, 4 do
    for j = 1, 4 do
      m:set(i, j, self:get(j, i))
    end
  end
  return m
end

function mat4x4:sign(x, y)
  return (-1)^(x + y)
end

function mat4x4:determinant()
  local d = 0.0
  for i = 1, 4 do
    d = d + self:get(i, 1) * self:cofactor(i, 1)
  end
  return d
end

function mat4x4:determinant2x2()
  return self:get(1,1) * self:get(2,2) - self:get(2, 1) * self:get(1, 2)
end

function mat4x4:determinant3x3()
  local d = 0.0
  for i = 1, 3 do
    d = d + self:get(i, 1) * self:cofactor2x2(i, 1)
  end
  return d
end

function mat4x4:minorM(col, row)
  local r = mat4x4:new()
  local x = 0
  for i = 1, 3 do
    x = x + 1
    if x == col then
      x = x + 1
    end

    local y = 0
    for j = 1, 3 do
      y = y + 1
      if y == row then
        y = y + 1
      end
      if x <= 4 and y <= 4 then
        r:set(i, j, self:get(x, y))
      end
    end
  end
  
  return r
end

function mat4x4:cofactor(x, y)
  return self:sign(x, y) * self:minorM(x, y):determinant3x3()
end

function mat4x4:cofactor2x2(x, y)
  return self:sign(x, y) * self:minorM(x, y):determinant2x2()
end

function mat4x4:cofactorMatrix()
  local r = mat4x4:new()
  for i = 1, 4 do
    for j = 1, 4 do
      r:set(i, j, self:cofactor(i, j))
    end
  end
  return r
end

function mat4x4:adjoint()
  return self:cofactorMatrix():transpose()
end

function mat4x4:invert()
  return self:adjoint() * (1.0 / self:determinant())
end

function mat4x4:__unm()
  return self:transpose()
end

function mat4x4:__mul(other)
  if type(other) == "table" and other.isA and other:isA(mat4x4) then
    local r = mat4x4:new()
    for i = 1, 4 do
      for j = 1, 4 do
        for k = 1, 4 do
          r:set(i, j, r:get(i, j) + self:get(i, k) * other:get(k, j))
        end
      end
    end
    return r
  elseif type(other) == "number" then
    local r = mat4x4:new(self)
    for i = 1, 16 do
      r.e[i] = r.e[i] * other
    end
    return r
  else
    return vec3d:new(self:get(1, 1) * other.x + self:get(2, 1) * other.y + self:get(3, 1) * other.z + self:get(4, 1) * other.w,
                     self:get(1, 2) * other.x + self:get(2, 2) * other.y + self:get(3, 2) * other.z + self:get(4, 2) * other.w,
                     self:get(1, 3) * other.x + self:get(2, 3) * other.y + self:get(3, 3) * other.z + self:get(4, 3) * other.w,
                     self:get(1, 4) * other.x + self:get(2, 4) * other.y + self:get(3, 4) * other.z + self:get(4, 4) * other.w)
  end
end

-----

function mat4x4.translate(x, y, z)
  if type(x) == "number" then
    x = vec3d:new(x, y, z)
  end
  
  return mat4x4:new({1, 0, 0, x.x,
                     0, 1, 0, x.y,
                     0, 0, 1, x.z,
                     0, 0, 0, 1})
end

function mat4x4.scale(x, y, z, w)
  if type(x) == "number" then
    if type(y) == "number" then
      x = vec3d:new(x, y, z, w)
    else
      x = vec3d:new(x, x, x, x)
    end
  end
  
  return mat4x4:new({x.x, 0, 0, 0,
                     0, x.y, 0, 0,
                     0, 0, x.z, 0,
                     0, 0, 0, x.w})
end

function mat4x4.rotateX(rad)
  local s = math.sin(rad)
  local c = math.cos(rad)

  return mat4x4:new({1, 0, 0, 0,
                     0, c, -s, 0,
                     0, s, c, 0,
                     0, 0, 0, 1})
end

function mat4x4.rotateY(rad)
  local s = math.sin(rad)
  local c = math.cos(rad)

  return mat4x4:new({c, 0, s, 0,
                     0, 1, 0, 0,
                    -s, 0, c, 0,
                     0, 0, 0, 1})
end

function mat4x4.rotateZ(rad)
  local s = math.sin(rad)
  local c = math.cos(rad)

  return mat4x4:new({c, -s, 0, 0,
                     s, c, 0, 0,
                     0, 0, 1, 0,
                     0, 0, 0, 1})
end

-----
mat4x4.identity = mat4x4:new({
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
})

return mat4x4
