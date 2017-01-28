local sneaky = require("sneaky/util")
local Logger = require("sneaky/logger")
local serialization = require("serialization")
local server = require("net/server")
local rpcd = {}

function rpcd:new(modem, port, call_table)
  local i =  sneaky.class(self, {
                        call_table = call_table
  })
  i:init(modem, port)
  return i
end

function rpcd:init(modem, port)
  self.server = server:listen(modem, port, function(client, call)
                                local call = serialization.unserialize(call)
                                local call, args = call[1], sneaky.subtable(call, 2)
                                Logger.debug("Calling " .. tostring(call) .. " for " .. tostring(client.remote) .. " " .. serialization.serialize(args) .. "\n")
                                local handler = self.call_table[call]
                                if handler then
                                  --local args = {...}
                                  local ok, result = pcall(function() return {handler(client, table.unpack(args))} end)
                                  if ok then
                                    Logger.info("Called " .. tostring(call) .. " for " .. tostring(client.remote) .. "\n")
                                    Logger.debug("Result " .. tostring(call) .. " was " .. serialization.serialize(result) .. "\n")
                                    client:send(true, serialization.serialize(result))
                                  else
                                    Logger.error("Failed to call " .. tostring(call) .. " for " .. tostring(client.remote) .. " " .. serialization.serialize(result) .. "\n")
                                    client:send(false, result or "failed to call")
                                  end
                                else
                                  Logger.warning("Bad call from " .. tostring(client.remote) .. ": " .. tostring(call) .. "\n")
                                  client:send(false, "bad call")
                                end
  end)
end

function rpcd:start()
  if self._event_handler then
    self:stop()
  end

  self._event_handler = self.server:background()
end

function rpcd:stop()
  if self._event_handler then
    self.server:stop(self._event_handler)
    self._event_handler = nil
  end
end

return rpcd
