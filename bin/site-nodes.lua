local Command = require("sneaky/command")
local sneaky = require("sneaky/util")
local sides = require("sides")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Prints out the nodes of the site.",
    arguments = {
      site = {
        description = "The site definition to map.",
        default = sneaky.pathjoin(sneaky.root, "../sites/default.site")
      },
      filter = {
        description = "Pattern to filter the nodes with.",
        default = ""
      }
    },
    run = function(options, args)
      local routes_f = loadfile(sneaky.pathjoin(options.site, "routes.lua"))
      assert(routes_f, "Invalid site.")
      local routes = routes_f()

      for name, position in sneaky.search(sneaky.pairsByKeys(routes.nodes), options.filter, function(k, v) return k end) do
        print(name, position)
      end
    end
})
