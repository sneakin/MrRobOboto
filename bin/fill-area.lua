local sneaky = require("sneaky/util")
local number = require("sneaky/number")
local filler = require("rob/filler")
local rob = require("rob")
local robinv = require("rob/inventory")

local args = {...}
local item = args[1]
local width = tonumber(args[2])
local length = tonumber(args[3])
local pattern = args[4]
local pattern_args = {}

local pattern_func = function(x, y, w, h, z, h)
   if robinv.countInternalSlot() <= 0 then
      assert(robinv.selectFirst(item), "no item")
   end

   return true
end

if pattern == "checkers" then
   function select_block(x, y)
      if number.even(y) then
         if number.even(x) then
            return item
         else
            return args[5]
         end
      else
         if number.even(x) then
            return args[5]
         else
            return item
         end
      end
   end
   
   pattern_func = function(x, y, w, h, z, h)
      assert(robinv.selectFirst(select_block(x, y)), "no item")
      return true
   end
end

robinv.selectFirst(item)

local good, err = pcall(filler.floor, width, length, pattern_func)
rob.rollback_all()

if good then
   print("Success!")
else
   print("Failed.")
   sneaky.print_error(err, debug.traceback())
end
