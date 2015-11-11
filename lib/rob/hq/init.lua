local serialization = require("serialization")
local sides = require("sides")
local clear = require("rob/clear")
local rob = require("rob")
local crafter = require("rob/crafter")
local robinv = require("rob/inventory")
local filler = require("rob/filler")

local hq = {}

function hq:new(rob)
   local s = {
      rob = rob,
      level_height = 6,
      room_height = 3,
      room_size = 6
   }

   setmetatable(s, self)
   self.__index = self

   return s
end

function hq:clearSurface(size)
   robinv.equipFirst("_axe")

   for dir = 1, 4 do
      local mark = self.rob.checkpoint()
      clear.area(size or 8, size or 8)
      self.rob.rollback_to(mark)
      self.rob.turn(-1)
      self.rob.forward()
   end

   return true
end

function hq:digShaft()
   self.rob.turn(-2)
   self.rob.bottomOut()

   local good, err = pcall(clear.volumeDown, 2, 2, 256)
   if err.reason == "solid" then
      return true -- todo determine dig depth
   else
      error(err)
   end
   --self.rob.bottomOut()
   --self.rob.turn(-2)
end

function hq:digLevel(rooms_todo, rooms_done)
   for room = math.min((rooms_done or 1), 4), math.min(rooms_todo, 4) do
      local mark = self.rob.checkpoint()

      self.rob.swing(sides.forward)
      self.rob.forward()
      self.rob.swing(sides.up)

      clear.volumeUp(self.room_size, self.room_size, self.room_height)
      self.rob.rollback_to(mark)

      self.rob.turnRight()
      self.rob.forward()
   end
end

function hq:buildChargingRoom(level, room)
end

function hq:setCharger(level, room, charger)
end

function charge()
end

function hq:equipPick()
   if not robinv.equipFirst("pickaxe") then
      crafter.craft(5, "planks")
      crafter.craft(2, "sticks")
      crafter.craft(1, "wooden_pickaxe")
      robinv.equipFirst("pickaxe")
   end
end

function hq:digTunnel()
   self.rob.turnRight().forward().turnLeft()
   clear.volumeUp(8, 2, 3)
end

function hq:digTunnels()
   local mark = self.rob.checkpoint()
   
   for n = 1,4 do
      self:digTunnel()
      self.rob.down(2).turnRight()
   end
end

function hq:fillTunnels()
   self.rob.turnRight().forward().turnLeft()

   for n = 1, 4 do
      filler.floor(7, 2)
      self.rob.turnAround().forward().turnLeft()
   end
end

function hq:buildFoundation()
   local tries = 1

   local mark = self.rob.checkpoint()
   local z_mark = mark
   
   repeat
      local good, err = pcall(self.digTunnels, self)
      if not good then
         if err.reason == "solid" then
            self.rob.rollback_to(z_mark)
            self.rob.up()
            z_mark = self.rob.checkpoint()
            tries = tries + 1
         else
            error(err)
         end
      end
   until good or tries > 16

   if tries > 16 then error("failed") end

   self.foundation_level = tries

   self.rob.rollback_to(z_mark)

   -- todo fill foundation
   self:fillTunnels()
   
   return self.foundation_level
end

function hq:setup()
   local mark = self.rob.checkpoints:getMark()

   -- determine surface height?
   -- clear the land
   -- local good, err = pcall(self.clearSurface, self)
   -- self.rob.checkpoints:rollback_to(mark)

   -- dig out the shaft
   robinv.equipFirst("pickaxe")
   local good, err = pcall(self.digShaft, self)
   -- local depth = err[2]
   print(good, serialization.serialize(err))

   -- determine bedrock max height
   hq:determineBedrockLevel()
   
   -- dig out the initial level's initial room
   hq:digLevel(1)
   -- place charger and generator
   hq:buildChargingRoom(1, 1)
   -- charge
   -- hq:setCharger(1, 1, 1)
   --hq:charge()

return self
end


-------

return hq
