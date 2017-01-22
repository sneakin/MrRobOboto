local PORT = 3
local MAX_LOG = 1024 * 16

---

for addr, kind in component.list() do
  if not _G.component[kind] then
    _G.component[kind] = component.proxy(addr)
  end
end

---
local log = ""

function _G.print(...)
  local s = table.concat({...}, "\t")
  if (log:len() + s:len()) > MAX_LOG then
    log = log:sub(s:len())
  end
  log = log .. s .. "\n"
end

function _G.status(...)
  print("Status:", ...)
end

status("Booting...")
computer.beep(320, 0.5)

local master = string.match(component.eeprom.getData(), "[^\n ]+")

---
function _G.pull_event(timeout, kind)
  if not kind then
    timeout, kind = nil, kind
  end

  local when = computer.uptime() + (timeout or 0)
  repeat
    local e = { computer.pullSignal(timeout) }
    if kind == nil or e[1] == kind then
      return table.unpack(e)
    end
  until timeout and computer.uptime() >= when
end

function now()
  return computer.uptime()
end

function subtable(tbl, start, stop)
  local r = {}
  for i = start, (stop or #tbl) do
    table.insert(r, tbl[i])
  end
  return r
end

function bcall(f, ...)
  local args = { ... }
  return pcall(function() return {f(table.unpack(args))} end)
end

-----

function reply(kind, to, ok, result, ...)
  if type(result) == "table" then
    component.modem.send(to, PORT, kind, ok, table.unpack(result))
  else
    component.modem.send(to, PORT, kind, ok, result, ...)
  end
end

local to_load = ""

function on_message(from, distance, cmd, arg, ...)
  status(cmd, from)

  local commands = {
    load = function()
      to_load = to_load .. (arg or "")
      return true, string.len(to_load)
    end,
    cancel = function()
      to_load = ""
      return true
    end,
    loading = function()
      return true, to_load
    end,
    eval = function()
      if not arg then
        arg, to_load = to_load, ""
      end
      return bcall(load(arg, "eval", "bt", _G))
    end,
    logread = function()
      local old_log = log
      log = ""
      return true, old_log
    end,
    disco = function()
      return true, computer.address()
    end,
    shutdown = function(reboot)
      status("Goodbye.", "I love you.")
      return true
    end
  }

  local ok, result
  
  if commands[cmd] then
    ok, result = commands[cmd](arg, ...)
  elseif type(_G[cmd]) == "table" then
    ok, result = bcall(_G[cmd][arg], ...)
  end

  reply(cmd, from, ok, result)
  return cmd == "shutdown", arg ~= nil
end

local mo = component.modem
if mo.isWireless() then
  mo.setStrength(400)
end
mo.open(PORT)
mo.broadcast(PORT, "ready", computer.address())
computer.beep(640, 0.2)
computer.beep(320, 0.5)
status("Ready " .. PORT, mo.address)

local done, reboot

repeat
  local msg = { pull_event("modem_message") }
  local type, to, from, port, distance = table.unpack(msg)
  if port == PORT and (master == nil or from == master)
  then
    done, reboot = on_message(from, distance, table.unpack(subtable(msg, 6)))
  end
until done

computer.shutdown(reboot)
