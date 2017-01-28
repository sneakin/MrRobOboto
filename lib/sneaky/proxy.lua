local sneaky = require("sneaky/util")
local Proxy = {}

function Proxy:new(to)
  return sneaky.class(self, { to = to })
end

function Proxy:__index(key)
  return rawget(self, key) or getmetatable(self)[key] or self.to[key]
end

function Proxy:__newindex(key, value)
  self.to[key] = value
end

function Proxy:__pairs()
  if type(self.to) == "table" then
    return pairs(self.to)
  else
    sneaky.one_off_iter(self)
  end
end

function Proxy:__ipairs()
  if type(self.to) == "table" then
    return ipairs(self.to)
  else
    return sneaky.one_off_iter(self)
  end
end

function Proxy:__eq(other)
  return self.to:__eq(other)
end

function Proxy:__le(other)
  return self.to:__le(other)
end

----

function Proxy.test()
  local to = { a = 1, b = "2" }
  local r = Proxy:new(to)
  assert(r["a"] == 1, r["a"])
  assert(r.b == "2", r.b)

  r.c = "more"
  assert(r["c"] == "more", r["c"])

  local result = {}
  
  for k, v in pairs(r) do
    result[k] = v
  end

  assert(result.a == 1, result.a)
  assert(result.b == "2", result.b)
  assert(result.c == "more", result.c)

  r = Proxy:new({ "a", "b", "c"})
  result = {}
  for n, v in ipairs(r) do
    result[n] = v
  end
  assert(result[1] == "a", result[1])
  assert(result[2] == "b", result[1])
  assert(result[3] == "c", result[1])
end

----
return Proxy
