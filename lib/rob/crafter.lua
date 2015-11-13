local table = require("table")
local component = require("component")
local ccrafting = component.crafting
local robot = component.robot
local robinv = require("rob/inventory")
local sneaky = require("sneaky/util")
local math = require("math")

local crafter = {}

local recipes = {
   planks = {
      count = 4,
      ingredients = { { "log", 1 } },
      grid = { { 1 } }
   },
   stick = {
      count = 4,
      ingredients = { { "planks", 2 } },
      grid = {
         { 1 },
         { 1 } }
   },
   wooden_axe = {
      ingredients = { { "planks", 3 }, { "stick", 2 } },
      grid = {
         { 1, 1, 0 },
         { 1, 2, 0 },
         { 0, 2, 0 }
      }
   },
   wooden_pickaxe = {
      ingredients = { { "planks", 3 }, { "stick", 2 } },
      grid = {
         { 1, 1, 1 },
         { 0, 2, 0 },
         { 0, 2, 0 }
      }
   },
   stone_axe = {
      ingredients = { { "cobblestone", 3 }, { "stick", 2 } },
      grid = {
         { 1, 1, 0 },
         { 1, 2, 0 },
         { 0, 2, 0 }
      }
   },
   stone_pickaxe = {
      ingredients = { { "cobblestone", 3 }, { "stick", 2 } },
      grid = {
         { 1, 1, 1 },
         { 0, 2, 0 },
         { 0, 2, 0 }
      }
   },
   torch = {
      ingredients = { { "coal", 1 }, { "stick", 1 } },
      grid = {
         { 1 },
         { 2 }
      }
   }
}

function crafter.gatherIngredients(ingredients)
   local ingredient_slots = {}

   -- todo doesn't like split stacks, especially w/ the smaller first
   for i, in_cell in ipairs(ingredients) do
      local ingredient, number = table.unpack(in_cell)
      print("gather", i, ingredient, number)
      local slot, stack = robinv.findFirstInternal(ingredient)
      if not slot then
         if robinv.take(number, ingredient) == 0 then
            return false, "need", ingredient, number
         end

         slot, stack = robinv.findFirstInternal(ingredient)
      end

      print("gather2", slot, stack and stack.name, stack and stack.size)
      if slot and stack then
         if stack.size < number then
            return false, "need", ingredient, number - stack.size
         end
      else
         return false, "need", ingredient, number
      end

      ingredient_slots[ingredient] = slot
   end

   return ingredient_slots
end

function crafter.findRecipe(item_name)
   for name, recipe in sneaky.search(recipes, item_name, function(k, v)
                                  return k
   end) do
      return name, recipe
   end
end

function crafter.clearGrid()
   for y = 1, 3 do
      for x = 1, 3 do
         local crafting_slot = (y-1)*4+x
         if robot.count(crafting_slot) > 0 then
            robot.select(crafting_slot)
            robot.transferTo(robinv.firstEmptyInternalSlot(13), robot.count(crafting_slot))
         end
      end
   end
end

function crafter.layoutGrid(recipe, slots)
   for y = 1,3 do
      local row = recipe.grid[y]
      for x = 1,3 do
         local crafting_slot = (y-1)*4+x
         robot.select(crafting_slot)
         robot.transferTo(13, robot.count(crafting_slot))

         local item = row and row[x]
         print(x, y, item, crafting_slot)
         if item and not (item == 0) then
            local ingredient, count = table.unpack(recipe.ingredients[item])
            local slot = slots[ingredient]
            robot.select(slot)
            robot.transferTo(crafting_slot, 1)
         end
      end
   end
end

function crafter.craftRecipe(recipe)
   crafter.clearGrid();
   robot.select(13)
   
   local ingredient_slots, why, ingredient, number = crafter.gatherIngredients(recipe.ingredients)

   if not ingredient_slots then
      print(why, ingredient, number)
      return false, why, ingredient, number
   end

   crafter.layoutGrid(recipe, ingredient_slots)
   robot.select(13)
   return ccrafting.craft()
end

function crafter.craftSingle(item_name)
   local recipe_name, recipe = crafter.findRecipe(item_name)
   if not recipe then
      return false, "not_found"
   end

   return crafter.craftRecipe(recipe)
end

function crafter.craft(number, item_name)
   if not item_name then
      item_name = number
      number = 1
   end

   local recipe_name, recipe = crafter.findRecipe(item_name)
   if not recipe then
      return false, "not_found"
   end

   print("Crafting " .. number .. " " .. item_name)
   
   local count = recipe.count or 1

   for n = 1, math.ceil(number / count) do
      if not crafter.craftRecipe(recipe) then
         return false, n * count
      end
   end

   return true, number
end


return crafter
