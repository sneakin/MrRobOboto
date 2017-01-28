local sneaky = require("sneaky/util")
local Command = require("sneaky/command")

local component = require("component")
local gpu = component.gpu
local srw, srh = gpu.getResolution()
local screen_res = { width = srw, height = srh }

local vec3d = require("vec3d")
local mat4x4 = require("mat4x4")
local palette = require("sneaky/colors")
local colors = palette.instance32
local sm_renderer = require("rob/site/renderer")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "Displays a map of a site.",
    long_help = {
      "The map is displayed until 'q' is pressed.",
      "The arrow keys and shift+arrow can be used to scroll the map.",
      "'+' and '-' zoom the map in and out. '1' will set the zoom to 1 to 1, while 'c' will recenter and set the zoom to fit.",
      "'n' and 'r' can be used to highlight nodes and routes.",
      "'h' clears all existing highlights."
    },
    arguments = {
      site = {
        description = "The site definition to map.",
        --default = sneaky.pathjoin(sneaky.root, "../sites/default.site")
      },
      x = Command.Argument.Integer({
          description = "The map's position on the X (east/west) axis."
      }),
      y = Command.Argument.Integer({
          description = "The map's position on the Y (vertical) axis."
      }),
      z = Command.Argument.Integer({
          description = "The map's position on the Z (north/south) axis."
      }),
      zx = Command.Argument.Float({
          description = "The map's zoom on the X (east/west) axis."
      }),
      zy = Command.Argument.Float({
          description = "The map's zoom on the Y (vertical) axis."
      }),
      zz = Command.Argument.Float({
          description = "The map's zoom on the Z (north/south) axis."
      }),
      xy = {
        description = "Show the view looking north (X, Y).",
        boolean = true
      },
      yz = {
        description = "Show the view looking east (Z, Y).",
        boolean = true
      },
      hide_paths = {
        description = "Hide the site's paths.",
        boolean = true,
        default = nil
      },
      hide_nodes = {
        description = "Hide the site's nodes.",
        boolean = true,
        default = nil
      },
      path = {
        description = "Highlight the path defined by the nodes FROM,TO",
        list = true,
        default = {}
      },
      node = {
        description = "Highlight the named node.",
        list = true,
        default = {}
      },
      route = {
        description = "Compute and highlight a complete between nodes FROM,TO",
        list = true,
        default = {}
      },
      noloop = {
        description = "Render once and exit.",
        boolean = true
      }
    },
    run = function(options, args)
      local event = require("event")
      local keyboard = require("keyboard")
      local Canvas = require("rob/canvas")
      local term = require("term")
      local Site = require("rob/site")

      local site

      if options.site then
        local site_f = loadfile(sneaky.pathjoin(options.site, "init.lua"))
        site = site_f and site_f()
      end

      site = site or Site.instance()
      
      local routes_f = loadfile(sneaky.pathjoin(options.site, "routes.lua"))
      local routes = routes_f and routes_f()
      if routes then
        assert(site:merge_router_routes(routes), "failed to merge routes")
      end

      routes = site._router

      local zoom = { x = options.zx, y = options.zy, z = options.zz }
      local min = { x = options.x, y = options.y, z = options.z }

      local canvas = Canvas:new(gpu, screen)

      function prompt(question, hinter)
        io.stdout:write(question .. " ")
        return term.read({}, nil, hinter)
      end

      function node_hinter(text, pos)
        return sneaky.keys_list(sneaky.find(routes.nodes, function(k, v)
                                              return string.sub(k, 1, pos - 1) == text
        end))
      end

      function message(txt)
        print(txt)
        print("Press enter.")
        io.stdin:read()
      end

      local sm = sm_renderer:new(site, screen_res.width, screen_res.height)

      if options.xy then
        sm:screen_transform_z()
      end
      if options.yz then
        sm:screen_transform_x()
      end

      sm:zoom_to_fit()
        :translate(min)
        :zoom(zoom)
        :show_nodes(not options.hide_nodes)
        :show_paths(not options.hide_paths)


      for _, path in ipairs(options.path) do
        local from, to = string.match(path, "(.*),(.*)")
        assert(from and to, "Invalid path: " .. path)
        sm:highlight_path(from, to, colors:rand())
      end
      
      for _, node in ipairs(options.node) do
        sm:highlight_node(node, colors:rand())
      end

      for _, route in ipairs(options.route) do
        local from, to = string.match(route, "(.*),(.*)")
        assert(from and to, "Invalid route: " .. route)
        sm:highlight_route(from, to, colors:rand())
      end

      sm:draw(canvas)
      
      local done = options.noloop
      local scale = 1
      local handlers = {
        [ "q" ] = function()
          done = true
        end,
        [ keyboard.keys.up ] = function()
          sm:scrollBy(0, 1 * scale)
        end,
        [ keyboard.keys.down ] = function()
          sm:scrollBy(0, -1 * scale)
        end,
        [ keyboard.keys.right ] = function()
          sm:scrollBy(1 * scale, 0)
        end,
        [ keyboard.keys.left ] = function()
          sm:scrollBy(-1 * scale, 0)
        end,
        [ "1" ] = function()
          sm:zoom(vec3d:new(1, 1, 1))
        end,
        [ "+" ] = function()
          local zoom = sm:zoom()
          sm:zoom(zoom * 1.5)
        end,
        [ "-" ] = function()
          local zoom = sm:zoom()
          sm:zoom(zoom / 1.5)
        end,
        [ "c" ] = function()
          sm:zoom_to_fit()
        end,
        [ "x" ] = function()
          sm:screen_transform_x()
        end,
        [ "y" ] = function()
          sm:screen_transform_y()
        end,
        [ "z" ] = function()
          sm:screen_transform_z()
        end,
        [ "r" ] = function()
          local from = prompt("From?", node_hinter)
          local to = prompt("To?", node_hinter)
          local ok, reason = pcall(sm.highlight_route, sm, sneaky.trim(from), sneaky.trim(to))
          if not ok then
            message(reason)
          end
        end,
        [ "n" ] = function()
          local node = prompt("Node?", node_hinter)
          local ok, reason = pcall(sm.highlight_node, sm, sneaky.trim(node))
          if ok then
            sm:translate(routes.nodes[node])
          else
            message(reason)
          end
        end,
        [ "h" ] = function()
          sm:clear_highlights()
        end,
        [ "p" ] = function()
          local p = prompt("Point?")
          local x, y, z = string.match(p, "([^,]+),([^,]+),([^,]+)")
          p = vec3d:new(tonumber(x), tonumber(y), tonumber(z))
          message(tostring(p) .. " " .. tostring(sm:project_point(p)))
        end,
        [ "Z" ] = function()
          local z = prompt("Zone?", node_hinter)
          local ok, reason = pcall(sm.highlight_zone, sm, sneaky.trim(z))
          if not ok then
            message(reason)
          end
        end
      }

      while not done do
        local kind, addr, ascii, key, player = event.pull(1, "key_down")

        if kind == "key_down" then
          ascii = string.char(ascii)
          if keyboard.isShiftDown() then
            scale = 8
            ascii = string.upper(ascii)
          else
            scale = 1
          end
          local hand = handlers[key] or handlers[ascii]
          if hand then
            hand()
          end
        else
        end

        sm:redraw(canvas)
      end
      
      canvas:reset()
    end
})
