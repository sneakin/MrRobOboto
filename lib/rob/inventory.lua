--
-- Inventory
--

local table = require("table")
local sides = require("sides")
local sneaky = require("sneaky/util")
local component = require("component")
local _, crobot = pcall(function() return component.robot end)
local _, inv = pcall(function() return component.inventory_controller end)

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
   local stack = inv.getStackInInternalSlot(slot)
   if not stack then return true end
   local total_count = stack.size
   
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

      print("Transfered " .. total_count .. " " .. stack.name .. " from slot " .. slot)
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

function inventory.count(side, item_pattern)
   local n = 0
   for slot, stack in inventory.search(side, item_pattern) do
      n = n + stack.size
   end
   return n
end

function inventory.countInternalSlot(slot)
   return crobot.count(slot)
end

function inventory.countInternal(item_pattern)
   local n = 0
   for slot, stack in inventory.searchInternal(item_pattern) do
      n = n + stack.size
   end
   return n
end

function inventory.currentSlot()
  return crobot.select()
end

function inventory.findFirstInternal(item_pattern)
   local slot = crobot.select()
   local stack = inv.getStackInInternalSlot(slot)

   if stack then
      if string.find(search_value(slot, stack), item_pattern) then
         return slot, stack
      end
   end
   
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

function inventory.findFirstFilledSlot()
   for slot, stack in inventory.internal() do
      if stack then
         return slot
      end
   end

   return nil
end

function inventory.selectFirstFilledSlot()
   local slot = inventory.findFirstFilledSlot()
   crobot.select(slot)
   return slot
end

function inventory.equipFirst(item_pattern)
   local slot, stack = inventory.findFirstInternal(item_pattern)
   if slot then
      crobot.select(slot)
      inventory.equip()
      return slot
   end

   return false
end

function inventory.equip(slot)
   return inv.equip(slot)
end

function inventory.takeFromSlot(slot, number, dir)
   if not dir then dir = sides.front end
   if not number then number = 64 end
   local c = inv.getSlotStackSize(dir, slot)
   if inv.suckFromSlot(dir, slot, number) then
      local new_c = inv.getSlotStackSize(dir, slot)
      return c - new_c
   else
      return 0
   end
end

function inventory.take(number, pattern, dir)
   if not dir then dir = sides.front end

   local taken = 0

   for slot, stack in inventory.search(dir, pattern) do
      local delta = inventory.takeFromSlot(slot, number, dir)
      
      if delta <= 0 then
         number = number - delta
         break
      end
      
      taken = taken + delta
      if taken >= number then
         break
      end
   end

   return taken
end

function inventory.needList(list)
   local need = {}
   
   for item, number in pairs(list) do
      local n = inventory.countInternal(item)
      if n < number then
         need[item] = number - n
      end
   end

   return need
end

function inventory.takeList(list, dir)
   local need = {}
   local good = true
   
   for item, number in pairs(list) do
      print("Taking " .. number .. " " .. item)
      local n = inventory.take(number, item, dir or sides.front)
      if not (n == number) then
         table.insert(need, {item, number - n})
         good = false
      end
   end

   return good, need
end

----------------

return inventory
