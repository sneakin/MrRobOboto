local number = {}

function number.even(n)
   return (n % 2) == 0
end

function number.odd(n)
   return not number.even(n)
end

return number
