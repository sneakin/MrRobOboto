local sides = require("sides")
local robinv = require("rob/inventory")
local component = require("component")
local inv = component.inventory_controller

local args = {...}

if not args[1] then
   print("Usage: inv-take [number] item-name")
   os.exit()
end

local number = 1
local item_name = nil

if string.find(args[1], "[0-9]+") then
   number = tonumber(args[1])
   item_name = args[2]
else
   item_name = args[1]
end

robinv.take(number, item_name)
