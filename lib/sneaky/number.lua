local number = {}

function number.even(n)
   return (n % 2) == 0
end

function number.odd(n)
   return not number.even(n)
end

function number.minmax(x, y)
  if x > y then
    return y, x
  else
    return x, y
  end
end

number.NaN = (0/0)
number.Infinity = math.huge

function number.isnan(n)
  return n == number.NaN or n == -number.NaN
end

function number.isinf(n)
  return n == math.huge
end

return number
