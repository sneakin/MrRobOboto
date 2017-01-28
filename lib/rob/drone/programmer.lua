local sneaky = require("sneaky/util")
local component = require("component")
local sides = require("sides")
local computer = require("computer")

local RemoteProgrammer = require("rob/drone/programmer/remote")
local LocalProgrammer = require("rob/drone/programmer/local")

local ASSEMBLER_OUTPUT_SLOT = { "assembler", 1 }
local ASSEMBLER_EEPROM_SLOT = { "assembler", 20 }
local COMPUTER_EEPROM_SLOT = { "computer", 10 }
local CHEST_COMPUTER_EEPROM_SLOT = { "chest", 1 }
local CHEST_DRONE_SLOT = { "chest", 2 }
local CHEST_DRONE_EEPROM_SLOT = { "chest", 3 }

-- This drives a transposer to repeatedly reprogram drones.
-- The programmer expects a transposer to be directly attached to
-- the computer, an assembler, and a chest. The sides that each of
-- these is on is passed to the constructor along with the path
-- to the firmware to load.
--
-- Presently there is #reprogram_loop that is the actual control loop.
-- It takes an argument as to whether this is creative, in which case
-- it's best to manually start the assembler, and the eeprom's data value.
--
-- While more advanced, it is possible to run this on a computer on the
-- network. Placing the transposer next to a computer running the netlua.lua
-- firmware and passing a Programmer.Remote instance will then use
-- the first netlua.lua node as the eeprom writer.
--
-- todo detect if it's a robot, tablet, or drone: computer case, tablet case, drone case
-- todo go beyond programming and pull pieces from a chest, make requests for inventory
local Programmer = {
  Remote = RemoteProgrammer,
  Local = LocalProgrammer
}

function Programmer:new(firmware, assembler_side, computer_side, chest_side, programmer, trans_component, assembler_component)
  programmer = programmer or LocalProgrammer:new()
  return sneaky.class(self, { _drone_firmware = sneaky.pathjoin(sneaky.root, "..", "firmware", "drone.lua"),
                              _component = trans_component or component.transposer,
                              _assembler = assembler_component or component.assembler,
                              _programmer = programmer,
                              _sides = { assembler = assembler_side,
                                         computer = computer_side,
                                         chest = chest_side }
  })
end

function Programmer:__gc()
  self:close()
end


function Programmer:close()
  self._programmer:stop()
end

function Programmer:drone_firmware()
  return sneaky.read_file(self._drone_firmware)
end

function Programmer:transfer_item(source, sink, count)
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

function Programmer:wait_for_assembler(callback, ...)
  repeat
    if callback then
      callback(...)
    end
    
    self:sleep(self._assembler_wait_time or 10)
  until self._assembler:status() == "idle"

  return self
end

function Programmer:assemble(callback, ...)
  self._assembler.start()
  return self:wait_for_assembler(callback, ...)
end

function Programmer:print_assembler_status()
  print(self._assembler.status())
end

function Programmer:write_eeprom(label, code, data)
  print("Writing " .. code:len() .. " bytes to eeprom")
  self._programmer:set_label(label)
  self._programmer:set(code)
  if data then
    print("Writing " .. data:len() .. " bytes to eeprom-data")
    self._programmer:set_data(data)
  end

  return self
end

function Programmer:sleep(t)
  os.sleep(t)
  return self
end

function Programmer:reprogram_drone(code, data)
  return(self
           :transfer_item(COMPUTER_EEPROM_SLOT, CHEST_COMPUTER_EEPROM_SLOT)
           :transfer_item(ASSEMBLER_EEPROM_SLOT, COMPUTER_EEPROM_SLOT)
           :sleep(3)
           :write_eeprom("drone", code, data)
           :transfer_item(COMPUTER_EEPROM_SLOT, ASSEMBLER_EEPROM_SLOT)
           :transfer_item(CHEST_COMPUTER_EEPROM_SLOT, COMPUTER_EEPROM_SLOT))
end

function Programmer:assemble_drone()
  return(self
           :assemble(self.print_assembler_status, self)
           :transfer_item(ASSEMBLER_OUTPUT_SLOT, CHEST_DRONE_SLOT))
end

function Programmer:stackInSlot(slot)
  return self._component.getStackInSlot(self._sides[slot[1]], slot[2])
end
function Programmer:assembler_has_eeprom()
  local stack = self:stackInSlot(ASSEMBLER_EEPROM_SLOT)
  return stack ~= nil
end

function Programmer:assembler_empty()
  local stack = self:stackInSlot(ASSEMBLER_OUTPUT_SLOT)
  return stack == nil and (not self:assembler_has_eeprom())
end

function Programmer:reprogram_loop(creative, data)
  while true do
    print("Insert a drone")
    computer.beep(500, 0.5)
    
    repeat
      os.sleep(1)
    until self:assembler_has_eeprom()

    print("eeprom detected.")
    self:reprogram_drone(self:drone_firmware(), data)
    if not creative then
      self:assemble_drone()
    else
      print("Assemble your drone.")
      computer.beep(500, 0.5)
    end
    
    repeat
      os.sleep(1)
    until self:assembler_empty()
  end
end

return Programmer
