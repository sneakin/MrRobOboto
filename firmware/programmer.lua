local FROM, PORT, SRC_PORT = ...
PORT = PORT or 3

print("Loading programmer")
computer.beep(320, 0.5)

local master = string.match(component.eeprom.getData(), "[^\n ]+")

---

function subtable(tbl, start, stop)
  local r = {}
  for i = start, (stop or #tbl) do
    table.insert(r, tbl[i])
  end
  return r
end

-----

function eeprom()
  for addr, kind in component.list() do
    if kind == "eeprom" then
      return component.proxy(addr)
    end
  end

  error("where's the eeprom?")
end

local next_seq = 0

function reply(kind, to, port, ok, result, ...)
  next_seq = next_seq + 1
  if type(result) == "table" then
    component.modem.send(to, port, next_seq, PORT, kind, ok, table.unpack(result))
  else
    component.modem.send(to, port, next_seq, PORT, kind, ok, result, ...)
  end
end

local to_load = ""

function on_message(from, distance, port, cmd, arg, ...)
  local commands = {
    disco = function()
      return computer.address(), "programmer"
    end,
    load = function()
      if arg then
        to_load = to_load .. arg
      end
      return to_load:len()
    end,
    reset = function()
      to_load = ""
    end,
    set = function()
      eeprom().set(to_load)
      assert(eeprom().get() == to_load, "eeprom set failed")
      to_load = ""
    end,
    set_data = function()
      eeprom().setData(to_load)
      to_load = ""
    end,
    set_label = function()
      eeprom().setLabel(arg)
    end,
    exit = function()
    end
  }

  local ok, result
  
  if commands[cmd] then
    ok, result = bcall(commands[cmd], arg, ...)
  else
    ok, result = false, "unknown command"
  end

  reply(cmd, from, port, ok, result)
  return cmd == "exit"
end

component.modem.send(FROM, PORT, 0, SRC_PORT, "programmer_ready", computer.address())
computer.beep(640, 0.1)
computer.beep(640, 0.1)
print("Programmer ready")

local done = nil
local last_seq, last_from

repeat
  local msg = { pull_event("modem_message") }
  local type, to, from, port, distance, seq_id = table.unpack(msg)

  if to == component.modem.address
    and (port == SRC_PORT and (master == nil or from == master))
    and (from ~= last_from or (seq_id ~= last_seq and from == last_from))
  then
    computer.beep(1000, 0.1)
    last_seq, last_from = seq_id, from
    done = on_message(from, distance, table.unpack(subtable(msg, 7)))
  else
    computer.beep(400, 0.2)
  end
until done

computer.beep(200, 0.1)
computer.beep(100, 0.2)
print("Programmer exit.")
return true
