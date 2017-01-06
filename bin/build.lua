local Command = require("sneaky/command")
local sneaky = require("sneaky/util")

-- fixme needs to abort and rollback when there is no item to place
-- todo check inventory for requirements before building
-- todo clear the area ahead if it blocks

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    usage = "width length level_height levels",
    description = "Builds using a preprogrammed floorplan.",
    long_help = "Returns to the starting position on success or fail.",
    required_values = 4,
    arguments = {
      type = {
        description = "Floorplan to use",
        default = "simple"
      },
      style = {
        description = "Name of the table defining the type of blocks to use.",
        default = "default"
      },
      initial = Command.Argument.Integer({
          description = "Floor to start work building.",
          default = 0
      })
    },
    aliases = {
      t = "type",
      s = "style"
    },
    run = function(options, args)
      local rob = require("rob")

      local building_name = options.type
      local width = tonumber(args[1])
      local length = tonumber(args[2])
      local level_height = tonumber(args[3])
      local levels = tonumber(args[4])
      local style = options.style
      local initial_floor = options.initial

      local building = require("rob/buildings/" .. building_name)
      local styles = require("rob/buildings/styles")

      local blocks = styles[style]
      if not blocks then
        print("Style " .. style .. " was not found.")
        print("Try one of:")
        for k, v in pairs(styles) do
          print("\t" .. k)
        end

        return -2
      end

      print("Building a " .. building_name .. " building that is " .. width .. "x" .. length .. " with " .. levels .. " levels each " .. level_height .. " blocks tall starting at floor " .. initial_floor .. ".")

      local good, err = pcall(building.build, width, length, level_height, levels, blocks, initial_floor)
      rob.rollback_all()

      if good then
        print("Success!")
        return 0
      else
        print("Failed.")
        return -3
      end
    end
})
