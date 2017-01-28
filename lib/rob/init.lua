local math = require("math")
local event = require("event")
local shell = require("shell")
local component = require("component")

function proxy(kind)
  local ok, comp = pcall(function() return component[kind] end)
  if ok then
    return comp
  end
end

local crobot = proxy("robot")
local _, robot = pcall(require, "robot")
local sides = require("sides")
local nav = proxy("navigation")
local checkpoints = require("rob/checkpoints")

local sneaky = require("sneaky/util")
local vec3d = require("vec3d")
local RotatedSides = require("rob/rotated_sides")
local CallbackList = require("sneaky/callback_list")

local Mover = {}
function Mover:new(robot, facing, offset)
  return sneaky.class(self, { robot = robot,
                              _facing = facing,
                              _offset = vec3d:new(offset),
                              _callbacks = CallbackList:new()
  })
end

function Mover:facing(side)
  if side then
    self._facing = side
    return self
  else
    return self._facing
  end
end

function Mover:offset(v)
  if v then
    self._offset = v
    return self
  else
    return self._offset
  end
end

function Mover:turn(cw)
  local ok, reason = self.robot.turn(cw)
  if not ok then
    return ok, reason
  end
  
  if cw then
    cw = 1
  else
    cw = -1
  end
  local old_facing = self._facing
  self._facing = self._facing and RotatedSides.turns_to(self._facing, cw)
  self:call_callbacks("turn", old_facing, nil)
  return self
end

local unit_offset = {
  [ sides.north ] = vec3d:new(0, 1, -1),
  [ sides.south ] = vec3d:new(0, 1, 1),
  [ sides.east ] = vec3d:new(1, 1, 0),
  [ sides.west ] = vec3d:new(-1, 1, 0)
}
local dir_offset = {
  [ sides.front ] = vec3d:new(1, 0, 1),
  [ sides.back ] = vec3d:new(-1, 0, -1),
  [ sides.up ] = vec3d:new(0, 1, 0),
  [ sides.down ] = vec3d:new(0, -1, 0)
}

function Mover:move(dir)
  local ok, reason = self.robot.move(dir)
  if not ok then
    return ok, reason
  end
  
  local dx
  if self._offset and self._facing then
    dx = unit_offset[self._facing] * dir_offset[dir]
    self._offset = self._offset + dx
  end
  self:call_callbacks("move", nil, dx)
  return self
end

function Mover:call_callbacks(kind, old_facing, dx)
  self._callbacks:call(kind,
                       self._facing, self._offset,
                       old_facing or self._facing, dx or vec3d:new())
end

function Mover:add_callback(func)
  return self._callbacks:add(func)
end

function Mover:remove_callback(id)
  return self._callbacks:remove(id)
end

local rob = {}
rob.robot = Mover:new(crobot)
rob.checkpoints = checkpoints:new(rob.robot)

function rob.navigation()
   return nav
end

function rob.hasNavigation()
   return not (nav == nil)
end

function rob.facing(side)
  if rob.hasNavigation() then
    return rob.navigation().getFacing()
  else
    return rob.robot:facing(side)
  end
end

function rob.offset(v)
  if rob.hasNavigation() then
    return vec3d:new(rob.navigation().getPosition())
  else
    return rob.robot:offset(v)
  end
end

function rob.origin(v)
  if v then
    rob._origin = vec3d:new(v)
    return rob
  else
    return rob._origin
  end
end

function rob.position()
  return rob.offset() + rob.origin()
end

function rob.checkpoint()
   return rob.checkpoints:getMark()
end

function rob.replace_from(mark, func)
   rob.checkpoints:replaceFrom(mark, func)
end

function rob.rollback()
   rob.checkpoints:rollback()
   return rob
end

function rob.rollback_to(mark)
   rob.checkpoints:rollback_to(mark)
   return rob
end

function rob.rollback_all()
   rob.checkpoints:rollback_all()
   return rob
end

function rob.pop_to(mark)
   rob.checkpoints:pop_to(mark)
   return rob
end

--
-- Motion procedures
--

function rob.moveBy(dir, blocks)
   rob.checkpoints:move_by(dir, blocks)
   return rob
end

local dir_procs = {
   forwardBy = "forward",
   backBy = "back",
   upBy = "up",
   downBy = "down"
}
for name, dir in pairs(dir_procs) do
   rob[name] = function(n)
      rob.checkpoints:move_by(sides[dir], n)
      return rob
   end

   rob[dir] = rob[name]
end

function rob.bottomOut()
   while not crobot.detect(sides.down) do
      rob.down()
   end
   
   return rob
end

function rob.face(dir)
  if dir == sides.up or dir == sides.down then
    return false
  end

  local face = nav.getFacing()
  repeat
    rob.turn()
    face = nav.getFacing()
    print("Facing", face, dir)
  until tonumber(face) == tonumber(dir)

  return true
end

function rob.turn(times)
   rob.checkpoints:turn(times)
   return rob
end

function rob.turnRight(times)
   return rob.turn(-(times or 1))
end

function rob.turnLeft(times)
   return rob.turn(times or 1)
end

function rob.turnAround()
   return rob.turn(2)
end

function rob.swing(dir)
   return crobot.swing(dir)
end

--
-- Lamp state
--

local blinker = require("rob/blinker")

function rob.blink(delay, color)
   blinker.blink(delay, color)
end

function rob.setLightColor(color)
  blinker.off()
  crobot.setLightColor(color)
end

--
-- Present state indicators
--

function rob.busy()
  rob.setLightColor(0xFF0000)
end

function rob.cool()
  rob.setLightColor(0xFF00)
end

function rob.notcool()
  rob.blink(0.5, 0xffff00)
end

--
-- Actions
--

function rob.place(dir)
   if not crobot.place(dir) then
      error({"place", dir})
   end
   
   return rob
end


--
-- Utility procedures
--

function rob.execCommands(commands)
  for _,c in ipairs(commands) do
     if not shell.execute(c) then
        print("Failed to execute: " .. c)
        return false
     end
  end

  return true
end


-----------

return rob
