local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Prints the ingredient list for a recipe.",
    usage = "item",
    required_values = 1,
    run = function(options, args)
      local table = require("table")
      local crafter = require("rob/crafter")

      local item = args[1]
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
    end
})
