local PORT = 2
local MAX_LOG = 1024 * 16

---

for addr, kind in component.list() do
  if not _G[kind] then
    _G[kind] = component.proxy(addr)
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
  drone.setStatusText(table.concat({...}, "\n"))
  print("Status:", ...)
end

status("Booting...")
computer.beep(400, 1)

---

function _G.master_address()
  return string.match(eeprom.getData(), "[^\n ]+")
end

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
    modem.send(to, PORT, kind, ok, table.unpack(result))
  else
    modem.send(to, PORT, kind, ok, result, ...)
  end
end

local MAX_FLY_TIME = 5
local STATUS_TIME = 1

function fly(recipient, x, y, z, accel, fly_time)
  fly_time = fly_time or MAX_FLY_TIME
  accel = accel or drone.getMaxVelocity()
  
  drone.move(x, y, z)
  drone.setAcceleration(accel)

  local status_at, check_at, last_offset = now() + STATUS_TIME, now() + fly_time, drone.getOffset()

  reply("fly", recipient, true, "begin-flight", offset)

  repeat
    local offset, n = drone.getOffset(), now()
    if check_at < n then
      local dx = last_offset - offset
      last_offset = offset
      if dx < 1 then
        stuck = true
      else
        check_at = n + fly_time
      end
    end

    if status_at < n then
      reply("fly", recipient, not stuck, "in-flight", offset)
      status_at = n + STATUS_TIME
    end

    status(offset, drone.getVelocity())
  until offset < 1 or stuck

  drone.setAcceleration(0)

  local offset = drone.getOffset()
  
  status(offset, ((offset < 1 and "Made It") or (stuck and  "Stuck") or "timed out"))
  return offset < 1, "end-flight", offset
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
      return true, drone.name()
    end,
    fly = function(x, y, z, a, t)
      return fly(from, x, y, z, (a or drone.getMaxVelocity()), (t or MAX_FLY_TIME))
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

modem.open(PORT)
modem.setStrength(400)
modem.broadcast(PORT, "ready", drone.name())
computer.beep(400, 1)
status("Ready " .. PORT, modem.address)

local done, reboot

repeat
  local msg = { pull_event("modem_message") }
  local type, to, from, port, distance = table.unpack(msg)
  if port == PORT and (master_address == nil or from == master_address())
  then
    done, reboot = on_message(from, distance, table.unpack(subtable(msg, 6)))
  end
until done

computer.shutdown(reboot)
