local table = require("table")
local sneaky = {
}

local PATH_SEPARATOR = "/"
local PATH_PATTERN = PATH_SEPARATOR .. "?(.*" .. PATH_SEPARATOR .. ")" .. "(.*[^" .. PATH_SEPARATOR .. "])"
local EXT_PATTERN = "[.](.*)$"

function sneaky.basename(path)
  if path then
    local dir, base = string.gmatch(path, PATH_PATTERN)()
    if not dir then
      return path
    else
      return base
    end
  end
end

function sneaky.dirname(path)
  if path then
    local dir, base = string.gmatch(path, PATH_PATTERN)()
    if dir then
      dir = dir:sub(1, dir:len() - 1)
      if path:sub(1, 1) == PATH_SEPARATOR then
        return PATH_SEPARATOR .. dir
      else
        return dir
      end
    end
  end
end

function sneaky.extname(path)
  if path then
    local ext = string.gmatch(path, EXT_PATTERN)()
    return ext
  end
end

function sneaky.pathjoin(...)
  return sneaky.join({...}, PATH_SEPARATOR)
end

function sneaky.read_file(path)
  local f, reason = io.open(path, "r")
  assert(f, reason)
  
  local d = f:read("*a")
  f:close()
  return d
end

function sneaky.chars(str)
  return function(str, index)
    if index < str:len() then
      index = index + 1
      return index, str:sub(index, index)
    end
  end, str, 0
end

function sneaky.print_error(err, trace)
   print("Error:", err)
   if type(err) == "table" then
      for k,v in pairs(err) do
         print(k, v)
      end
   end
   if trace then
      print(trace)
   end
end

function sneaky.subtable(tbl, i, n)
   n = n or (#tbl - i + 1)
   
   if #tbl > n then
      local r = {}
      for x = 1, n do
         r[x] = tbl[(i-1) + x]
      end
      return r
   else
      return tbl
   end
end

function sneaky.copy(src)
   local dest = {}
   setmetatable(dest, getmetatable(src))

   if src then
      for k,v in pairs(src) do
         dest[k] = v
      end
   end
   
   return dest
end

function sneaky.append(tbl, more)
  local new_tbl = sneaky.copy(tbl)
  for _, e in ipairs(more) do
    table.insert(new_tbl, e)
  end
  return new_tbl
end

function sneaky.join(t, joiner, convertor)
  if type(t) ~= "table" then
    t = {t}
  end
  
  joiner = joiner or " "
  convertor = convertor or function(s) return s end

  local s = ""

  for n, v in ipairs(t) do
    if n ~= 1 then
      s = s .. joiner
    end
    s = s .. convertor(v)
  end

  return s  
end

function table.kind_of(klass)
  return type(klass) == "table" or klass == "table"
end

function string.kind_of(klass)
  return type(klass) == "string" or klass == "string"
end

function sneaky.class(klass, initial_state)
  local v = sneaky.copy(initial_state)
  if not klass.kind_of then
    klass.isA = function(this, k) return k == getmetatable(this) end
    klass.kind_of = klass.isA
  end
  --v.isA = klass.isA
  if not klass.__index then
    klass.__index = klass
  end
  setmetatable(v, klass)
  return v
end

function sneaky.table(default)
   local default_func

   if type(default) == "function" then
      default_func = default
   else
      default_func = function() return default end
   end
   
   local t = {}
   setmetatable(t, { __index = default_func })
   return t
end

function sneaky.reverse(tbl)
  local ret = {}
  for k,v in ipairs(tbl) do
    ret[#tbl + 1 -k] = v
  end

  return ret
end

function sneaky.updated_values(a, b)
  if type(a) == "table" and type(b) == "table" then
    local changes = {}
    
    for ak, av in pairs(a) do
      changes[ak] = sneaky.updated_values(av, b[ak])
    end

    return changes
  elseif type(a) == type(b) then
    if a == b then
      return nil
    else
      return b
    end
  else
    return b
  end
end

function sneaky.remove(tbl, number)
   local r = {}
   for i = 1, number do
      table.insert(r, table.remove(tbl))
   end

   return r
end

function sneaky.pairs(tbl)
  local it, state, v1 = pairs(tbl)
  return function()
    v1,value = it(state, v1) -- assign v1
    return v1,value
  end
end

function sneaky.spairs(tbl)
   local k, v = next(tbl)
   
   function iter()
      if k then
         local ok, ov = k, v
         k, v = next(tbl, k)
         return ok, ov
      else
         return nil
      end
   end
   
   return iter
end

function sneaky.pairsByKeys(t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0
  local iter = function()
    i = i + 1
    if a[i] == nil then return nil
     else return a[i], t[a[i]]
    end
  end
  return iter
end

function sneaky.pairsByValues(t, f)
  local a = {}
  for k,v in pairs(t) do table.insert(a, {k,v}) end
  table.sort(a, function(a, b)
    if f then return f(a[2], b[2])
    else return(a[2] < b[2])
    end
  end)
  local i = 0
  local iter = function()
    i = i + 1
    if a[i] == nil then return nil
    else return a[i][1], a[i][2]
    end
  end
  return iter
end

function sneaky.search(iter, item_pattern, value_function)
   if not value_function then
      value_function = function(k, v) return v end
   end

   -- Lua can't pass pairs as arguments AFAIK
   if type(iter) == "table" then
     iter = sneaky.pairs(iter)
   end

   local selector = item_pattern
   
   if type(item_pattern) == "string" then
      item_pattern = {item_pattern}
   end
   if type(item_pattern) == "function" then
      selector = item_pattern
   else
      selector = function(k, v)
         for _, pattern in ipairs(item_pattern) do
            if string.find(value_function(k, v), pattern) then
               return pattern
            end
         end

         return false
      end
   end
   
   local myiter = function()
      repeat
         local k, v = iter()
         if k and selector(k, v) then
            return k, v
         end
      until not k

      return nil
   end

   return myiter
end

function cast_comparison_func(func)
  if type(func) ~= "function" then
    return function(k, v) return v == func end
  else
    return func
  end
end

function sneaky.find(tbl, func)
  func = cast_comparison_func(func)
  
   local ret = {}
   for k, v in pairs(tbl) do
      if func(k,v) then
         ret[k] = v
      end
   end
   return ret
end

function sneaky.ifind(tbl, func)
  func = cast_comparison_func(func)
  
   local ret = {}
   for i, v in ipairs(tbl) do
      if func(k,v) then
         table.insert(ret, v)
      end
   end
   return ret
end

function sneaky.findFirst(tbl, func)
  func = cast_comparison_func(func)

  for k, v in pairs(tbl) do
      if func(k, v) then
         return k, v
      end
   end

   return nil
end

function sneaky.findFirstValue(tbl, value)
   return sneaky.findFirst(tbl, function(k, v) return v == value end)
end

function sneaky.count(iter)
  local counter = 0
  for _, _ in iter do
    counter = counter + 1
  end
  return counter
end

function sneaky.one_off_iter(v)
  local ran = false
  return function()
    if ran then
      return nil
    else
      ran = true
      return 1, v
    end
  end
end

function sneaky.min(tbl, func)
   if #tbl > 0 then
      local mv = tbl[1]
      local mi = 1
      
      for i, v in pairs(tbl) do
         if func(v, mv) then
            mv = v
            mi = i
         end
      end
      return mi, mv
   else
      return nil
   end
end

function sneaky.mapIter(tbl, func)
   local k, v = next(tbl)
   
   function iter()
      if k then
         local ok, ov = k, v
         k, v = next(tbl, k)
         return func(ok, ov)
      else
         return nil
      end
   end
   
   return iter
end

function sneaky.iter_map(iter, func)
   local k, v = iter()
   
   function r_iter()
      if k then
         local ok, ov = k, v
         k, v = iter()
         return func(ok, ov)
      else
         return nil
      end
   end
   
   return r_iter
end

function sneaky.map(iter, func)
  local result = {}
  
  for k, v in iter do
    result[k] = func(k, v)
  end

  return result
end

function sneaky.reduce(iter, acc, func)
  if type(iter) == "table" then
    iter = sneaky.pairs(iter)
  end
  
   for k, v in iter do
      acc = func(acc, k, v)
   end

   return acc
end

function sneaky.keys(tbl)
   return sneaky.mapIter(tbl, function(k,v) return k end)
end

function sneaky.keys_list(tbl)
  return sneaky.reduce(sneaky.keys(tbl), {}, function(a, k, v)
                         table.insert(a, k)
                         return a
  end)
end

function sneaky.values(tbl)
   return sneaky.mapIter(tbl, function(k,v) return v end)
end

function sneaky.values_list(tbl)
  return sneaky.reduce(sneaky.values(tbl), {}, function(a, k, v)
                         table.insert(a, k)
                         return a
  end)
end

function sneaky.inverse(tbl)
  if type(tbl) == "table" then
    tbl = sneaky.pairsByKeys(tbl)
  end
  
  return sneaky.reduce(tbl, {}, function(acc, k, v)
                  acc[v] = k
                  return acc
  end)
end

function sneaky.unload(pkg)
   package.loaded[pkg] = nil
end

function sneaky.reload(pkg)
   sneaky.unload(pkg)
   return require(pkg)
end

function sneaky.merge(a, b)
   local tbl = sneaky.copy(a)

   if b then
      for k,v in pairs(b) do
         tbl[k] = v
      end
   end
   
   return tbl
end

function sneaky.deep_merge(a, b)
  local tbl = sneaky.copy(a)

  if b then
    for k,v in pairs(b) do
      if type(v) == "table" then
        tbl[k] = sneaky.deep_merge(tbl[k], v)
      else
        tbl[k] = v
      end
    end
  end
  
  return tbl
end

function sneaky.trim(str)
  local r = string.gsub(string.gsub(str, "^[ \t\n]*", ""), "[ \t\n]*$", "")
  return r
end

function sneaky.range(min, max, step)
  step = step or 1
  max = max or min

  local r = {}
  for i = min, max, step do
    table.insert(r, i)
  end
  
  return r
end

function sneaky.permute(...)
  local states = nil
  local values = {}
  local tables = {...}

  return function()
    if states == nil then
      states = {}
      for i, t in ipairs(tables) do
        states[i], values[i] = next(t)
      end
    elseif states[1] == nil then
      return nil
    else
      local n = #tables
      states[n], values[n] = next(tables[n], states[n])
      if states[n] == nil and n > 1 then
        states[n], values[n] = next(tables[n])
        for b = n - 1, 1, -1 do
          states[b], values[b] = next(tables[b], states[b])
          if states[b] then
            break
          elseif b == 1 then
            return nil
          else
            states[b], values[b] = next(tables[b])
          end
        end
      end
    end

    return table.unpack(values)
  end
end

sneaky.root = sneaky.dirname(sneaky.dirname(debug.getinfo(2, "S").source:sub(2)))

return sneaky
