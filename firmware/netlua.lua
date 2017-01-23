-- This firmware provides a network usable Lua environment.
-- Basically a stripped down drone with more safe code.

local PORT = 3
local MAX_LOG = 1024 * 7

---

for addr, kind in component.list() do
  if not _G.component[kind] then
    _G.component[kind] = component.proxy(addr)
  end
end

---
local log = ""

function imap(tbl, f)
  local r = {}
  for k, v in ipairs(tbl) do
    r[k] = f(v)
  end
  return r
end

function _G.print(...)
  local s = table.concat(imap({...}, tostring), "\t")
  local tl = log:len() + s:len()
  if s:len() > MAX_LOG then
    log = s:sub(s:len() - MAX_LOG)
  else
    if tl > MAX_LOG then
      log = log:sub(tl - MAX_LOG - 1)
    end
    
    log = log .. s .. "\n"
  end
end

function _G.status(...)
  print("Status:", ...)
end

status("Booting...")
computer.beep(320, 0.1)

local master = string.match(component.eeprom.getData(), "[^\n ]+")

---
function now()
  return computer.uptime()
end

function _G.pull_event(timeout, kind)
  if type(timeout) ~= "number" and not kind then
    timeout, kind = nil, timeout
  end

  local when = now() + (timeout or 0)
  repeat
    local e = { computer.pullSignal(timeout) }
    if kind == nil or e[1] == kind then
      return table.unpack(e)
    end
  until timeout and now() >= when
end

function subtable(tbl, start, stop)
  local r = {}
  for i = start, (stop or #tbl) do
    table.insert(r, tbl[i])
  end
  return r
end

function copy(tbl)
  local r = {}
  for k, v in pairs(tbl) do
    r[k] = v
  end
  setmetatable(r, getmetatable(tbl))
  return r
end

function bcall(f, ...)
  local args = { ... }
  return pcall(function() return {f(table.unpack(args))} end)
end

-----

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
  status(cmd, from)

  local commands = {
    load = function()
      to_load = to_load .. (arg or "")
      return string.len(to_load)
    end,
    cancel = function()
      to_load = ""
    end,
    loading = function()
      return to_load
    end,
    eval = function()
      if not arg then
        arg, to_load = to_load, ""
      end
      local e = copy(_G)
      e._G = e
      local f, reason = load(arg, "eval", "bt", e)
      if f then
        return f(from, port, PORT)
      else
        error(reason)
      end
    end,
    logread = function()
      local old_log = log
      log = ""
      return old_log
    end,
    logclear = function()
      log = ""
      return true
    end,
    disco = function()
      return computer.address(), "netlua"
    end,
    shutdown = function(reboot)
      status("Goodbye.", "I love you.")
      return "shutdown", reboot ~= nil
    end
  }

  local ok, result
  
  if commands[cmd] then
    ok, result = bcall(commands[cmd], arg, ...)
  elseif type(_G[cmd]) == "table" then
    ok, result = bcall(_G[cmd][arg], ...)
  end

  reply(cmd, from, port, ok, result)
  return (ok == "shutdown"), result
end

local mo = component.modem
if mo.isWireless() then
  mo.setStrength(400)
end
mo.open(PORT)
mo.broadcast(PORT, 0, PORT, "ready", computer.address())
computer.beep(640, 0.1)
status("Ready " .. PORT, mo.address)

local done, reboot
local last_seq, last_from

repeat
  local msg = { pull_event("modem_message") }
  local type, to, from, port, distance, seq_id = table.unpack(msg)

  if to == component.modem.address
    and port == PORT
    and (master == nil or from == master)
    and (from ~= last_from or (seq_id ~= last_seq and from == last_from))
  then
    computer.beep(800, 0.1)
    last_seq, last_from = seq_id, from
    done, reboot = on_message(from, distance, table.unpack(subtable(msg, 7)))
  else
    computer.beep(200, 0.1)
  end
until done

computer.shutdown(reboot)
