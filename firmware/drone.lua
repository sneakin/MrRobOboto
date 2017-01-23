local PORT = 2
local MAX_LOG = 1024 * 7

---

for a, k in component.list() do
	if not _G[k] then
		_G[k] = component.proxy(a)
	end
end

---
local log = ""

function _G.print(...)
	local s = table.concat({...}, "\t")
	if s:len() > MAX_LOG then
		log = s:sub(s:len() - MAX_LOG)
	else
		local tl = log:len() + s:len()
		if tl > MAX_LOG then
			log = log:sub(tl - MAX_LOG - 1)
		end
		
		log = log .. s .. "\n"
	end
end

function _G.status(...)
	drone.setStatusText(table.concat({...}, "\n"))
	print("Status:", ...)
end

local b = computer.beep
local unp = table.unpack

status("Booting...")
b(640, 0.1)

---

_G.master = string.match(eeprom.getData(), "[^\n ]+")

---
function now()
	return computer.uptime()
end

function _G.pull_event(ttl, kind)
	if not kind then
		ttl, kind = nil, ttl
	end

	local when = now() + (ttl or 0)
	repeat
		local e = { computer.pullSignal(ttl) }
		if kind == nil or e[1] == kind then
			return unp(e)
		end
	until ttl and now() >= when
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
	return pcall(function() return {f(unp(args))} end)
end

-----

local seq = 0

function reply(kind, to, p, ok, r, ...)
	seq = seq + 1
	if type(r) == "table" then
		modem.send(to, p, seq, PORT, kind, ok, unp(r))
	else
		modem.send(to, p, seq, PORT, kind, ok, r, ...)
	end
end

local MAX_FLY_T = 5
local STATUS_T = 1

function fly(recipient, port, x, y, z, accel, fly_time)
	fly_time = fly_time or MAX_FLY_T
	accel = accel or drone.getMaxVelocity()
	
	drone.move(x, y, z)
	drone.setAcceleration(accel)

	local status_at, check_at, last_offset = now() + STATUS_T, now() + fly_time, drone.getOffset()

	reply("fly", recipient, port, true, "fly", offset)

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
			reply("fly", recipient, port, not stuck, "fly", offset)
			status_at = n + STATUS_T
		end

		status(offset, drone.getVelocity())
	until offset < 1 or stuck

	drone.setAcceleration(0)

	local offset = drone.getOffset()
	
	status(offset, ((offset < 1 and "Made It") or (stuck and	"Stuck") or "timed out"))
	return offset < 1, "end-fly", offset
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
			local f, r = load(arg, "eval", "bt", _G)
			if f then
				return f(from, port, PORT)
			else
				error(r)
			end
		end,
		logread = function()
			local old_log = log
			log = ""
			return old_log
		end,
		disco = function()
			return drone.name(), "drone"
		end,
    pair = function()
      eeprom.setData(arg or from)
    end,
		fly = function(x, y, z, a, t)
			return fly(from, port, x, y, z, a, t)
		end,
		shutdown = function(reboot)
			status("Goodbye.", "I love you.")
		end
	}

	local ok, result
	
	if commands[cmd] then
		ok, result = bcall(commands[cmd], arg, ...)
	elseif type(_G[cmd]) == "table" then
		ok, result = bcall(_G[cmd][arg], ...)
	end

	reply(cmd, from, port, ok, result)
	return cmd == "shutdown", arg ~= nil
end

local m = modem
m.open(PORT)
m.setStrength(400)
m.broadcast(PORT, "ready", drone.name())
b(640, 0.1)
status("Ready " .. PORT, m.address)

local done, reboot

repeat
	local msg = { pull_event("modem_message") }
	local type, to, from, port, dist, seq = unp(msg)

	if to == m.address and port == PORT and (master == nil or from == master)
    and (from ~= lf or (seq ~= ls and from == lf))
	then
    b(800, 0.1)
		done, reboot = on_message(from, dist, unp(subtable(msg, 7)))
	end
until done

computer.shutdown(reboot)
