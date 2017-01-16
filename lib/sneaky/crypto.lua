local crypto = {}

function xor_strings(key, text)
  local s = ""
  for i = 0, string.len(text) - 1 do
    s = s .. string.char(bit32.bxor(string.byte(key, 1 + i % string.len(key)),
                                    string.byte(text, 1 + i)))
  end
  return s
end

function xor(a, b)
  if type(a) == "number" then
    return bit32.bxor(a, b)
  elseif type(a) == "string" then
    return xor_strings(a, b)
  elseif type(a) == "table" and #a == #b then
    local r = {}
    for i, c in ipairs(a) do
      r[i] = xor(a[i], b[i])
    end
    return r
  else
    error("argument error")
  end
end

crypto._xor = xor

function crypto.string(str)
  local m = string.gmatch(str, ".")
  return function()
    local b = m()
    if b then
      return string.byte(b)
    else
      return nil
    end
  end
end

function crypto.string_loop(str)
  local m = string.gmatch(str, ".")
  return function()
    local b = m()
    if b then
      return string.byte(b)
    else
      m = string.gmatch(str, ".")
      b = m()
      return string.byte(b)
    end
  end
end

function crypto.null()
  return function(text)
    local r = {}
    for i in text do
      table.insert(r, i)
    end
    return r
  end
end

function crypto.xor(key)
  return function(text)
    local r = {}
    for i in text do
      table.insert(r, bit32.bxor(key(), i))
    end
    return r
  end
end

function crypto.table(tbl)
  local i, v = next(tbl)
  return function()
    if i then
      local ov = v
      i, v = next(tbl, i)
      return ov
    else
      return nil
    end
  end
end

function crypto.cbc(cipher, iv)
  local state
  return function(text)
    local m = {}
    if not state then
      state = iv
      m = { iv }
    end
    
    for c in text do
      t = xor(state, cipher(crypto.table({c}))[1])
      table.insert(m, t)
      state = t
    end

    return m
  end
end

function crypto.decbc(decipher)
  local state
  return function(text)
    if not state then
      state = text()
      --print("IV", state)
    end
    
    local m = {}
    for c in text do
      local x = xor(state, c)
      local nc = decipher(crypto.table({x}))[1]
      --print(state, c, x, nc)
      state = c
      table.insert(m, nc)
    end
    return m
  end
end

function crypto.pack(tbl)
  local s = ""
  if type(tbl) ~= "function" then
    tbl = crypto.table(tbl)
  end
  
  for i in tbl do
    s = s .. string.char(i)
  end
  
  return s
end

function crypto.ascii_armor(txt)
  local a = string.byte("A")
  local r = {}
  for c in txt do
    table.insert(r, a + bit32.band(0xF, bit32.rshift(c, 0)))
    table.insert(r, a + bit32.band(0xF, bit32.rshift(c, 4)))
  end
  return r
end

function crypto.ascii_dearmor(txt)
  local r = {}
  local a = string.byte("A")
  for c in txt do
    local nc = txt()
    local fc = (c - a) + bit32.lshift(nc - a, 4)
    print(c, c - a, nc, nc - a, fc)
    table.insert(r, fc)
  end
  return r
end

function crypto.test()
  local sneaky = require("sneaky/util")
  local serialization = require("serialization")
  
  local msg = "Good day to you."
  local msg2 = "Hello world"

  msg = "abc"
  msg2 = "xyz"
  
  local enc = crypto.cbc(crypto.xor(crypto.string_loop("hello")), 32)
  local blob1 = enc(crypto.string(msg))
  assert(msg ~= crypto.pack(blob1))
  local blob2 = enc(crypto.string(msg2))
  assert(msg2 ~= crypto.pack(blob2))

  local dec = crypto.decbc(crypto.xor(crypto.string_loop("hello")))
  local clear1 = crypto.pack(dec(crypto.table(blob1)))
  assert(msg == clear1, serialization.serialize({ msg, clear1 }))
  local clear2 = crypto.pack(dec(crypto.table(blob2)))
  assert(msg2 == clear2, serialization.serialize({ msg2, clear2 }))

  local dec = crypto.decbc(crypto.xor(crypto.string_loop("hello")))
  local clear = crypto.pack(dec(crypto.table(sneaky.append(blob1, blob2))))

  assert((msg .. msg2) == clear, "'" .. (msg .. msg2) .. "' ~= '" .. clear .. "'")

  print(msg, clear1, crypto.pack(blob1), serialization.serialize(blob1))
  print(msg2, clear2, crypto.pack(blob2), serialization.serialize(blob2))
  print((msg .. msg2), clear)
end

return crypto
