local sides = require("sides")
local cp = require("rob/checkpoints")

local MoveThenPlacer = {
}

function MoveThenPlacer:new(rob, mover, inventory_controller, item)
   local s = {
      rob = rob,
      mover = mover,
      inv = inventory_controller,
      item = item,
      _on = true
   }
   setmetatable(s, self)
   self.__index = self
   return s
end

for _, dir in ipairs({ "back", "up", "down" }) do
   MoveThenPlacer[dir] = function(self, times, ...)
      for n = 1, (times or 1) do
         self.mover[dir](self.mover)
         pcall(self.place, self, cp.flippedSides[sides[dir]], n, (times or 1), ...)
      end
      return self
   end
end

function MoveThenPlacer:turn(...)
   self.mover:turn(...)
   return self
end

function MoveThenPlacer:forward(...)
   self.mover:forward(...)
   return self
end

function MoveThenPlacer:checkpoint(...)
   return self.mover:checkpoint(...)
end

function MoveThenPlacer:pop_to(...)
   self.mover:pop_to(...)
   return self
end

function MoveThenPlacer:replace_from(...)
   self.mover:replaceFrom(...)
   return self
end

function MoveThenPlacer:ready()
   self:select_next_slot()
end

function MoveThenPlacer:select_next_slot()
   assert(self.inv.selectFirst(self.item), "no item " .. self.item)
end

function MoveThenPlacer:on()
   self._on = true
   return self
end

function MoveThenPlacer:off()
   self._on = false
   return self
end

function MoveThenPlacer:select_item(...)
   if self.inv.count() <= 0 then
      self:select_next_slot()
   end
end

function MoveThenPlacer:place(dir, step, num_steps, ...)
   if not self._on then return end

   self:select_item(dir, step, num_steps, ...)

   self.rob.place(dir)
   
   return self
end

return MoveThenPlacer
