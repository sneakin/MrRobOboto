local sneaky = require("sneaky/util")
local CallbackList = require("sneaky/callback_list")
local os = require("os")

local Logger = {
  Level = {
    error = 1,
    notice = 2,
    warning = 3,
    info = 4,
    debug = 5
  },
  logs = CallbackList:new(),
  level = 3
}

function Logger.add(func)
  return Logger.logs:add(func)
end

function Logger.remove(id)
  return Logger.logs:remove(id)
end

function Logger.log(level, ...)
  if level <= Logger.level then
    local results = Logger.logs:call(level, ...)
    for id, result in pairs(results) do
      if type(result) == "table" and result[1] == nil then
        local ok, reason = table.unpack(result)
        if not ok then
          io.stderr:write("Failed to write log", id, reason, level, ...)
        end
      end
    end
  end
  
  return Logger
end

for name, level in pairs(sneaky.copy(Logger.Level)) do
  Logger.Level[level] = name

  Logger[name] = function(...)
    return Logger.log(level, ...)
  end
end

function Logger.IO(stream)
  return function(level, mod, ...)
    stream:write(sneaky.join({os.time(), Logger.Level[level], mod, ...}, "\t", tostring), "\n")
  end
end


---

function Logger.stop_default()
  if Logger.stderr_id then
    Logger.remove(Logger.stderr_id)
    Logger.stderr_id = nil
  end
  return Logger
end

function Logger.default()
  if Logger.stderr_id == nil then
    Logger.stderr_id = Logger.add(Logger.IO(io.stderr))
  end
  return Logger
end

return Logger
