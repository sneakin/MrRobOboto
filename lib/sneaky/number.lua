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

return number
