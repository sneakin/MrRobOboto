local math = require("math")
local sneaky = require("sneaky/util")
local serialization = require("serialization")
local sides = require("sides")
local component = require("component")
local robot = component.robot

local CheckPointError = {}

function CheckPointError.__tostring(err)
   local s = (err.command or "unknown") .. ": " .. (err.reason or "unknown")
   if type(err.more) == "table" then
      s = s .. "\n"
      for k,v in pairs(err.more) do
         s = s .. ", " .. k .. " = " .. v
      end
   end

   return s
end      

function CheckPointError:new(command, reason, ...)
   local e = {
      command = command,
      reason = reason,
      more = ...
   }
   setmetatable(e, self)
   self.__index = self
   return e
end

function CheckPointError:raise(command, reason, ...)
   error(self:new(command, reason, ...), 2)
end

local cp = {
   CheckPointError = CheckPointError,
   flippedSides = {
      [ sides.front ] = sides.back,
      [ sides.back ] = sides.front,
      [ sides.up ] = sides.down,
      [ sides.down ] = sides.up
   }
}

function cp:new()
   local c = {
      points = {}
   }
   setmetatable(c, self)
   self.__index = self
   return c
end

function cp:reset()
   self.points = {}
   return self
end

function cp:count()
   return #self.points
end

function cp:push(return_func, ...)
   if return_func then
      table.insert(self.points, {return_func, ...})
   end

   return self
end

function cp:replace(num, return_func, ...)
   if return_func then
      sneaky.remove(self.points, num)
      self:push(return_func, ...)
   end

   return self
end

function cp:replaceFrom(mark, return_func, ...)
   return self:replace(#self.points - mark, return_func, ...)
end

function cp:getMark()
   return #self.points
end

function cp:checkpoint()
   return self:getMark()
end

function cp:rollback(n)
   if n then
      for i = 1, n do
         self:rollback()
      end
   else
      if #self.points > 0 then
         local c = self:pop()
         if #c > 0 then
            local func = table.remove(c, 1)
            local err_roll_back = cp:new()
            -- print("Rolling back with ", func, table.unpack(c))
            local good, err = pcall(func, err_roll_back, table.unpack(c))
            if err then
               print(err)

               if type(err) == "string" then
                  for k,v in pairs(err) do
                     print(k, v)
                  end
               end
            end
            
            if not good then
               err_roll_back:rollback_all()
               self:push(func, table.unpack(c))
               CheckPointError:raise("rollback", "obstacle on return path", err)
            end
         end
      end
   end
   
   return self
end

function cp:rollback_to(mark)
   return self:rollback(#self.points - mark)
end

function cp:rollback_all()
   while #self.points > 0 do
      self:rollback()
   end

   return self
end

function cp:pop(n)
   if not n or n <= 1 then
      return table.remove(self.points)
   else
      for i = 1, math.min(n or 1, #self.points) do
         table.remove(self.points)
      end

      return self
   end
end

function cp:pop_to(mark)
   repeat
      self:pop()
   until #self.points == mark

   return self
end

function cp:pop_all()
   return self:pop(math.huge)
end

function cp:turn(times)
   times = times or 1
   
   for i = 1, math.abs(times) do
      local good, err = robot.turn(times < 0)
      if good then
         self:push(cp.turn, not(times < 0))
      else
         CheckPointError:raise("turn", err, i, times)
      end
   end

   self:replace(math.abs(times), cp.turn, -times)

   return self
end

function cp:turnLeft(times)
   return self:turn(times or 1)
end

function cp:turnRight(times)
   return self:turn(-(times or 1))
end

function cp:move(dir)
   local good, err = robot.move(dir)
   if good then
      self:push(self.move, cp.flippedSides[dir])
      
      return self
   else
      CheckPointError:raise("move", err, dir, 2)
   end
end

function cp:move_by(dir, blocks)
   for i = 1, (blocks or 1) do
      self:move(dir)
   end

   self:replace((blocks or 1), self.move_by, cp.flippedSides[dir], blocks)
   
   return self
end

local dir_procs = {
   forwardBy = "forward",
   backBy = "back",
   upBy = "up",
   downBy = "down"
}
for name, dir in pairs(dir_procs) do
   cp[name] = function(self, n)
      return self:move_by(sides[dir], n or 1)
   end

   cp[dir] = cp[name]
end

return cp
