local sneaky = {}

function sneaky.reverse(tbl)
  local ret = {}
  for k,v in ipairs(tbl) do
    ret[#tbl + 1 -k] = v
  end

  return ret
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

   local myiter = function()
      repeat
         local k, v = iter()
         if k and v and string.find(value_function(k, v), item_pattern) then
            return k, v
         end
      until not k

      return nil
   end

   return myiter
end

return sneaky
