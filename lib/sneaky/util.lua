local table = require("table")
local sneaky = {}

function sneaky.copy(src)
   local dest = {}

   if src then
      for k,v in pairs(src) do
         dest[k] = v
      end
   end
   
   return dest
end

function sneaky.class(klass, initial_state)
   local v = sneaky.copy(initial_state)
   setmetatable(v, klass)
   klass.__index = klass
   return v
end

function sneaky.reverse(tbl)
  local ret = {}
  for k,v in ipairs(tbl) do
    ret[#tbl + 1 -k] = v
  end

  return ret
end

function sneaky.remove(tbl, number)
   local r = {}
   for i = 1, number do
      table.insert(r, table.remove(tbl))
   end

   return r
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
      local it, state, v1 = pairs(iter)
      iter = function()
         v1,value = it(state, v1) -- assign v1
         return v1,value
      end
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
         if k and v and selector(k, v) then
            return k, v
         end
      until not k

      return nil
   end

   return myiter
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

function sneaky.map(iter, func)
   for k, v in iter do
      func(k, v)
   end
end

function sneaky.reduce(iter, acc, func)
   for k, v in iter do
      acc = func(acc, k, v)
   end

   return acc
end

function sneaky.keys(tbl)
   return sneaky.mapIter(tbl, function(k,v) return k end)
end

function sneaky.values(tbl)
   return sneaky.mapIter(tbl, function(k,v) return v end)
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
   for k,v in pairs(b) do
      tbl[k] = v
   end

   return tbl
end

return sneaky