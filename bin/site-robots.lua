local sneaky = require("sneaky/util")
local Command = require("sneaky/command")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Prints info about the site's robots.",
    arguments = {
      getaddr = {
      }
    },
    run = function(options, args)
      local sides = require("rob/sides")
      local Site = require("rob/site")

      local time_ranges = {
        { 3600 * 24 * 365.25, "y" },
        { 3600 * 24, "d" },
        { 3600, "h" },
        { 60, "m" },
        { nil, "s" }
      }
      function humanize_time(seconds)
        for _, range in ipairs(time_ranges) do
          if range[1] and seconds >= range[1] then
            return string.format("%4.0f", (seconds / range[1])) .. range[2]
          elseif range[1] == nil then
            return string.format("%4.0f", seconds) .. range[2]
          end
        end
      end

      function vec_string(v)
        if v then
          return string.format("%2.0f, %2.0f, %2.0f", v.x, v.y, v.z)
        else
          return "???"
        end
      end

      if options.getaddr then
        local robot = Site.instance():find_robot_by_name(options.getaddr)
        print(robot.modem_addr)
      else
        print("Flags", "Name", "Facing", "  Position  ", "Energy", "Signal", "Updated", "Address")
        local now = os.time()
        for addr, robot in Site.instance():robots() do
          local flags = ""
          if not robot.authorized or not robot.blessed then
            flags = flags .. "X"
          end
          print(string.format("%s\t%s\t%s\t%s\t%.0f\t%.2f\t%s\t%s",
                              flags,
                              robot.name,
                              sides.tostring(robot.facing) or "???",
                              vec_string(robot:position()),
                              100 * (robot.energy or 0) / (robot.max_energy or 0),
                              robot.signal_strength or 0,
                              humanize_time((now - (robot.last_seen or math.huge)) / 100) or "never",
                              robot.modem_addr))
        end
      end
    end
})
