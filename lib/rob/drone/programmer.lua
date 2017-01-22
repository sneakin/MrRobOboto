local sneaky = require("sneaky/util")
local component = require("component")
local sides = require("sides")

local ASSEMBLER_OUTPUT_SLOT = { "assembler", 1 }
local ASSEMBLER_EEPROM_SLOT = { "assembler", 20 }
local COMPUTER_EEPROM_SLOT = { "computer", 10 }
local CHEST_COMPUTER_EEPROM_SLOT = { "chest", 1 }
local CHEST_DRONE_SLOT = { "chest", 2 }
local CHEST_DRONE_EEPROM_SLOT = { "chest", 3 }

local Poser = {}
function Poser:new(assembler_side, computer_side, chest_side, trans_component, assembler_component)
  return sneaky.class(self, { _component = trans_component or component.transposer,
                              _assembler = assembler_component or component.assembler,
                              _sides = { assembler = assembler_side,
                                         computer = computer_side,
                                         chest = chest_side }
                     })
end

function Poser:transfer_item(source, sink, count)
  local src_side, src_slot = table.unpack(source)
  src_side = self._sides[src_side]
  local sink_side, sink_slot = table.unpack(sink)
  sink_side = self._sides[sink_side]
  self._component.transferItem(src_side,
                               sink_side,
                               count or 1,
                               src_slot,
                               sink_slot)
  return self
end

function Poser:wait_for_assembler(callback, ...)
  repeat
    if callback then
      callback(...)
    end
    
    self:sleep(self._assembler_wait_time or 10)
  until self._assembler:status() == "idle"

  return self
end

function Poser:assemble(callback, ...)
  self._assembler.start()
  return self:wait_for_assembler(callback, ...)
end

function Poser:print_assembler_status()
  print(self._assembler.status())
end

function Poser:write_eeprom(code, data)
  print("Writing " .. code:len() .. " bytes to eeprom")
  component.eeprom.set(code)
  if data then
    print("Writing " .. code:len() .. " bytes to eeprom data")
    component.eeprom.setData(data)
  end
  return self
end

function Poser:sleep(t)
  os.sleep(t)
  return self
end

function Poser:reprogram_drone(code, data)
  return(self
           :transfer_item(COMPUTER_EEPROM_SLOT, CHEST_COMPUTER_EEPROM_SLOT)
           :transfer_item(ASSEMBLER_EEPROM_SLOT, COMPUTER_EEPROM_SLOT)
           :sleep(1)
           :write_eeprom(code, data)
           :transfer_item(COMPUTER_EEPROM_SLOT, ASSEMBLER_EEPROM_SLOT)
           :assemble(self.print_assembler_status, self)
           :transfer_item(ASSEMBLER_OUTPUT_SLOT, CHEST_DRONE_SLOT)
           :transfer_item(CHEST_COMPUTER_EEPROM_SLOT, COMPUTER_EEPROM_SLOT))
end

return Poser
 
-- todo wait for drone in assembler, then kick off reprograming
-- todo a creative computer needs to start the assembler for instant results, but transposers can't manipulate a creative case.
