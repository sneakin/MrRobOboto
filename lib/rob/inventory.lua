--
-- Inventory
--

local sides = require("sides")
local sneaky = require("sneaky/util")
local component = require("component")
local crobot = component.robot
local inv = component.inventory_controller

local inventory = {}

function emptySlot(slot)
   crobot.select(slot)
   
  for islot = 1, inv.getInventorySize(sides.front) do
    if inv.dropIntoSlot(sides.front, islot) then
      return true
    end
  end

  return false
end

function inventory.emptySlot(slot)
   local total_count = crobot.count(slot)
   
   if emptySlot(slot) then
      local new_c = crobot.count(slot)
      if new_c > 0 then
         if emptySlot(slot) then
            total_count = total_count + new_c
         else
            print("Chest full?")
            return false, total_count
         end
      end

      print("Transfered " .. total_count .. " items from slot " .. slot)
      return true, total_count
   end
end

function inventory.emptyAll()
  for slot = 1, crobot.inventorySize() do
    local c = crobot.count(slot)
    if c > 0 then
      if not inventory.emptySlot(slot) then
        print("Chest full?")
        return false
      end
    end
  end

  return true
end

function inventory.iter(side)
   local slot = 0

   local iter = function()
      slot = slot + 1

      local size = inv.getInventorySize(side)
      if size and slot <= size then
         return slot, inv.getStackInSlot(side, slot)
      else
         return nil
      end
   end

   return iter
end

function inventory.internal(skip)
   local slot = skip or 0

   local iter = function()
      slot = slot + 1

      if slot <= crobot.inventorySize() then
         return slot, inv.getStackInInternalSlot(slot)
      else
         return nil
      end
   end

   return iter
end

function search_value(k, v)
   if v and v.name then
      return string.lower(v.name)
   else
      return nil
   end
end

function inventory.search(side, item_pattern)
   return sneaky.search(inventory.iter(side), item_pattern, search_value)
end

function inventory.searchInternal(item_pattern)
   return sneaky.search(inventory.internal(), item_pattern, search_value)
end

function inventory.findFirstInternal(item_pattern)
   for slot, stack in inventory.searchInternal(item_pattern) do
      return slot, stack
   end
end

function inventory.firstEmptyInternalSlot(skip)
   for slot, stack in inventory.internal(skip) do
      if not stack then
         return slot
      end
   end

   return false
end

function inventory.selectFirst(item_pattern)
   local slot, stack = inventory.findFirstInternal(item_pattern)
   if slot and crobot.select(slot) then
      return slot
   end

   return false
end

function inventory.equipFirst(item_pattern)
   local slot, stack = inventory.findFirstInternal(item_pattern)
   if slot and inventory.equip(slot) then
      return slot
   end

   return false
end

function inventory.equip(slot)
   return inv.equip(slot)
end


function inventory.take(number, pattern, dir)
   if not dir then dir = sides.front end

   local taken = 0

   for slot, stack in inventory.search(dir, pattern) do
      local c = stack.size
      if inv.suckFromSlot(dir, slot, number) then
         local new_c = inv.getSlotStackSize(dir, slot)
         local delta = c - new_c
         number = number - delta

         if number <= 0 then
            break
         end
      end
   end

   return taken == number
end

----------------

return inventory
