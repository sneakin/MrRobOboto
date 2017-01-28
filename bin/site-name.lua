local sneaky = require("sneaky/util")
local Command = require("sneaky/command")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Prints or changes the site's name.",
    run = function(options, args)
      local Site = require("rob/site")
      local site = Site.instance()

      if args[1] then
        site.name = sneaky.join(args, " ")
        site:save()
      end
      
      print(site.name)
    end
})
