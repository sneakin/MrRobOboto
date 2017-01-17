local sneaky = require("sneaky/util")
local Command = require("sneaky/command")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Shows info about or manipulates the Computronics' tape drive.",
    arguments = {
      rewind = {
        description = "Be kind. Use this all the time.",
        boolean = true
      },
      seek = Command.Argument.Integer({
          description = "Moves the tape forward or back the number of bytes."
      }),
      label = {
        description = "Change the tape's label, in the drive!?"
      },
      tape = {
        description = "The label of the tape to manipulate."
      },
      drive = {
        description = "The [short] address of the tape drive component."
      },
      list = {
        description = "List the tapes.",
        boolean = true
      }
    },
    run = function(options, args)
      local component = require("component")
      local drive = component.tape_drive

      if options.list then
        for addr, kind in component.list() do
          if kind == "tape_drive" then
            print(addr, component.invoke(addr, "getLabel"))
          end
        end

        return nil
      end
      
      if options.tape then
        for addr, kind in component.list() do
          if kind == "tape_drive" then
            if component.invoke(addr, "getLabel") == options.tape then
              drive = component.proxy(addr)
              break
            end
          end
        end
      elseif options.drive then
        drive = component.proxy(component.get(options.drive))
        assert(drive, "invalid drive")
      end

      if options.rewind then
        print("Rewound", drive.seek(-drive.getSize()))
      end
      
      if options.seek then
        print("Seeked", drive.seek(options.seek))
      end

      if options.label then
        drive.setLabel(options.label)
      end
      
      print("Label", drive.getLabel())
      print("Size", drive.getSize())
      print("Position", drive.getPosition())
    end
})
