local table = require("table")
local crafter = require("rob/crafter")

local args = {...}
local item = args[1]

if not item then
   print("Usage: recipe item")
   os.exit()
end

local name, recipe = crafter.findRecipe(item)

if name then
   print("Item:", name)

   local slots, why, item, number = crafter.gatherIngredients(recipe.ingredients)
   if not slots then
      print("Needs:")
      print(why, item, number)
   end

   print("Ingredients: ")
   for _, info in pairs(recipe.ingredients) do
      local in_name, in_number = table.unpack(info)
      print(in_name, in_number, slots and slots[in_name])
   end

   print("")
else
   print("Not found.")
end
