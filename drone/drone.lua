local DRONE_PORT = 2

for addr, kind in component.list() do
  if not _G[kind] then
    _G[kind] = component.proxy(addr)
  end
end

drone.setStatusText("Booting...")
computer.beep(400, 1)

-----
function _G.master_address()
  return string.match(eeprom.getData(), "[^\n ]+")
end

function _G.set_master_address(addr)
  eeprom.setData(addr)
end

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

function status(...)
  drone.setStatusText(...)
end

function reply(kind, to, ok, result, ...)
  if type(result) == "table" then
    modem.send(to, DRONE_PORT, kind, ok, table.unpack(result))
  else
    modem.send(to, DRONE_PORT, kind, ok, result, ...)
  end
end

function now()
  return computer.uptime()
end

local MAX_FLY_TIME = 5
local STATUS_TIME = 1

function fly(recipient, x, y, z, accel, fly_time)
  fly_time = fly_time or MAX_FLY_TIME
  accel = accel or drone.getMaxVelocity()
  
  drone.move(x, y, z)
  drone.setAcceleration(accel)

  local status_at, check_at, last_offset = now() + STATUS_TIME, now() + fly_time, drone.getOffset()

  repeat
    local offset = drone.getOffset()
    local n = now()
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

    status(offset .. "\n" .. drone.getVelocity())
  until offset < 1 or stuck

  drone.setAcceleration(0)

  local offset = drone.getOffset()
  local msg = "timed out"
  if offset < 1 then
    msg = "Made it"
  elseif stuck then
    msg = "Stuck"
  end
  
  status(offset .. "\n" .. msg)
  reply("fly", recipient, offset < 1, "made-it", offset)
end

function on_message(from, distance, cmd, arg, ...)
  status(cmd .. "\n" .. from)

  local commands = {
    eval = function()
      local f = load(arg, "eval", "bt", _G)
      local ok, result = bcall(f)
      reply("eval", from, ok, result)
    end,
    disco = function()
      reply("disco", from, true, drone.name())
    end,
    fly = function(x, y, z, a, t)
      reply("fly", from, true, "in-flight", drone.getOffset())
      fly(from, tonumber(x), tonumber(y), tonumber(z), tonumber(a or drone.getMaxVelocity()), tonumber(t or MAX_FLY_TIME))
    end,
    msg = function()
      if arg then
        status(arg)
      end
      reply("msg", from, true, drone.getStatusText())
    end,
    pair = function()
      local ok, reason = pcall(set_master_address, arg)
      reply("pair", from, ok, reason)
      status("Paired w/\n" .. arg)
    end,
    master = function()
      reply("master", from, true, master_address())
    end,
    shutdown = function(reboot)
      reply("shutdown", from, true)
      status("Goodbye.\nI love you.")
      computer.shutdown(reboot ~= nil)
    end
  }

  if commands[cmd] then
    return commands[cmd](arg, ...)
  elseif type(_G[cmd]) == "table" then
    local ok, result = bcall(_G[cmd][arg], ...)
    reply(cmd, from, ok, result)
  else
    reply(cmd, from, false, arg)
  end
end

modem.open(DRONE_PORT)
status("Ready " .. DRONE_PORT .. "\n" .. modem.address)
modem.setStrength(400)
computer.beep(400, 1)

local done = false

repeat
  local msg = { pull_event("modem_message") }
  local type, to, from, port, distance = table.unpack(msg)
  if port == DRONE_PORT
    and (master_address == nil or from == master_address())
  then
    done = on_message(from, distance, table.unpack(subtable(msg, 6)))
  end
until done
