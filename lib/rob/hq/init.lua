local sides = require("sides")
local clear = require("rob/clear")
local rob = require("rob")
local crafter = require("rob/crafter")
local robinv = require("rob/inventory")

local hq = {}

function hq.new(rob)
   local self = {
      rob = rob,
      level_height = 6,
      room_height = 3,
      room_size = 6
   }

   function self.clearSurface()
      robinv.equipFirst("axe")

      for dir = 1, 4 do
         local good, retdata = clear.volumeUp(8, 8, 20)
         rob.turn(-1)
         rob.forward()
      end

      return true
   end

   function self.digShaft(levels)
      rob.turn(-2)

      local good, depth = clear.volumeDown(2, 2, self.level_height * levels)
      if good then
         rob.bottomOut()
         rob.turn(-2)
         return true, depth
      else
         return false, depth
      end
   end

   function self.digLevel(rooms_todo, rooms_done)
      for room = math.min((rooms_done or 1), 4), math.min(rooms_todo, 4) do
         rob.swing(sides.forward)
         rob.forward()
         rob.swing(sides.up)
         
         if clear.volumeUp(self.room_size, self.room_size, self.room_height) then
            rob.back()
            rob.turn(-1)
            rob.forward()
         else
            rob.forward()
            return false
         end
      end

      return true
   end

   function self.buildChargingRoom(level, room)
   end

   function self.setCharger(level, room, charger)
   end

   function charge()
   end
   
   function self.setup2()
      -- clear the land
      local good = self.clearSurface()

      if good then
         -- dig out a level of the shaft
         if not robinv.equipFirst("pickaxe") then
            crafter.craft(5, "planks")
            crafter.craft(2, "sticks")
            crafter.craft(1, "wooden_pickaxe")
            robinv.equipFirst("pickaxe")
         end
         
         local good, depth = self.digShaft(1)
         if good then
            -- dig out the initial level's initial room
            local good = self.digLevel(1)
            if good then
               -- place charger and generator
               local good = self.buildChargingRoom(1, 1)
               if good then
                  -- charge
                  self.setCharger(1, 1, 1)
                  return self.charge()
               end
            end
         else
            rob.up(depth)
         end
      end

      return false
   end

   function self.equipPick()
      if not robinv.equipFirst("pickaxe") then
         crafter.craft(5, "planks")
         crafter.craft(2, "sticks")
         crafter.craft(1, "wooden_pickaxe")
         robinv.equipFirst("pickaxe")
      end
   end

   function self.setup()
      -- clear the land
      self.clearSurface()

      -- dig out a level of the shaft
      self.equipPick()
      self.digShaft(1)
      -- dig out the initial level's initial room
      self.digLevel(1)
      -- place charger and generator
      self.buildChargingRoom(1, 1)
      -- charge
      self.setCharger(1, 1, 1)
      self.charge()
   end

   return self
end


-------

return hq
