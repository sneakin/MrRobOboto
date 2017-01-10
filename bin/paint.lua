local sneaky = require("sneaky/util")
local Command = require("sneaky/command")
local Palette = require("sneaky/colors")
local colors = require("sneaky/colors")
local keyboard = require("keyboard")
local component = require("component")

Command:define({...}, {
    name = sneaky.basename(debug.getinfo(2, "S").source),
    description = "As basic as paint programs can get: registers touch events and changes the underlying pixel.",
    arguments = {
      screen = {
        description = "[Short] address of the screen to use.",
        default = component.screen.address
      },
      gpu = {
        description = "[Short] address of the GPU to bind to the screen.",
        default = component.gpu.address
      },
      width = Command.Argument.Integer({
        description = "Width of the resolution to use."
      }),
      height = Command.Argument.Integer({
        description = "Height of the resolution to use."
      }),
      bg = {
        description = "Color to clear the screen.",
        default = "black"
      },
      walk = {
        description = "Disable walk events on the screen.",
        default = true,
        boolean = true
      },
      touch = {
        description = "Disable touch events on the screen.",
        default = true,
        boolean = true
      },
      dnd = {
        description = "Disable drag and drop events on the screen.",
        default = true,
        boolean = true
      }
    },
    run = function(options, args)
      local event = require("event")
      local screen = component.proxy(component.get(options.screen))
      local gpu = component.proxy(component.get(options.gpu))

      local gw, gh = gpu.getResolution()

      gpu.bind(screen.address)
      
      if options.width and options.height then
        gpu.setResolution(tonumber(options.width), tonumber(options.height))
      end

      local touch_mode
      if screen.isTouchModeInverted then
        touch_mode = screen.isTouchModeInverted()
        screen.setTouchModeInverted(true)
      end
      local palette = Palette:new(8) --gpu.getDepth())

      local width, height = gpu.getResolution()
      local done = false
      local bg = palette:get(options.bg)
    
      local entity_colors = {}
      function entity_colors:reset(entity)
        self[entity] = nil
      end
      function entity_colors:get(entity)
        if entity then
          if not self[entity] or self[entity].ttl < os.time() then
            self[entity] = {
              color = palette:rand(false),
            }
          end

          self[entity].ttl = os.time() + 60 * 1000

          return self[entity].color
        else
          return palette:get("white")
        end
      end

      function update_display(x, y, fg, bg)
        gpu.setForeground(bg)
        gpu.setBackground(fg)
        
        gpu.set(x, y, " ")
      end

      function fill_area(x, y, w, h, char)
        gpu.fill(x, y, w, h, char or " ")
      end

      function clear_display(fg, bg, char)
        gpu.setForeground(fg)
        gpu.setBackground(bg)
        gpu.fill(1, 1, width, height, char or " ")
      end

      function minmax(x, y)
        if x > y then
          return y, x
        else
          return x, y
        end
      end
      
      function draw_line(x1, y1, x2, y2, char)
        if x1 > x2 then
          x1, x2 = x2, x1
          y1, y2 = y2, y1
        end
        --x1, x2 = minmax(x1, x2)
        --y1, y2 = minmax(y1, y2)

        local dx = x2 - x1
        local dy = y2 - y1
        local len = math.sqrt(dx * dx + dy * dy)
        if len <= 0 then
          return nil
        end
        local mx = dx / len
        local my = dy / len

        char = char or " "

        if my == 0 then -- horizontal line
          for x = x1, x2 do
            gpu.set(x, y1, char)
          end
        elseif mx == 0 then -- vertical line
          y1, y2 = minmax(y1, y2)
          for y = y1, y2 do
            gpu.set(x1, y, char)
          end
        else
          local x = x1
          local y = y1
          repeat do
              gpu.set(x, y, char)
              
              x = x + mx
              y = y + my
          end until x > x2 -- x is guarenteed to be < x2 due to swap
        end
      end

      function draw_box(x1, y1, x2, y2, char)
        x1, x2 = minmax(x1, x2)
        y1, y2 = minmax(y1, y2)
        char = char or " "
        
        for x = x1, x2 do
          gpu.set(x, y1, char)
          gpu.set(x, y2, char)
        end

        for y = y1, y2 do
          gpu.set(x1, y, char)
          gpu.set(x2, y, char)
        end
      end
      
      clear_display(palette:get("white"), bg)

      local aspect_x, aspect_y = screen.getAspectRatio()
      local screen_block_width = width / aspect_x
      local screen_block_height = height / aspect_y

      local touch_x, touch_y, drag_x, drag_y

      -- todo walk|keys to change drawing mode between points, boxes, lines, circles?
      -- like wise for colors
      -- maybe walk forward/back for color, side to side for color
      
      while not done do
        local ev = {event.pull(5)}
        local event_type = ev[1]

        if options.touch and event_type == "touch" then
          local _, screen, x, y, button, player = table.unpack(ev)
          local c

          touch_x = x
          touch_y = y
          
          if button == 0 then
            c = entity_colors:get(player)
          else
            c = bg
          end
          
          update_display(x, y, c, bg)
        elseif options.dnd and event_type == "drag" then
          local _, screen, x, y, button, player = table.unpack(ev)
          drag_x = touch_x
          drag_y = touch_y
        elseif options.dnd and event_type == "drop" then
          local _, screen, x, y, button, player = table.unpack(ev)
          gpu.setForeground(palette:get("black"))
          if drag_x and drag_y then
            --gpu.setBackground(palette:get("magenta")) --entity_colors:get(player))
            --draw_box(drag_x, drag_y, x, y, "*")
            if button == 0 then
              gpu.setBackground(entity_colors:get(player))
              draw_line(drag_x, drag_y, x, y, " ")
            else
              gpu.setBackground(bg)
              drag_x, x = minmax(x, drag_x)
              drag_y, y = minmax(y, drag_y)
              fill_area(drag_x, drag_y, x - drag_x, y - drag_y, " ")
            end
          end
        elseif options.walk and event_type == "walk" then
          local _, screen, x, y, player = table.unpack(ev)
          entity_colors:reset(player)
          -- local c = palette:rand(false) --entity_colors:get(player)
          -- gpu.setForeground(bg)
          -- gpu.setBackground(c)
          -- fill_area((x - 1) * screen_block_width, (y - 1) * screen_block_height, screen_block_width, screen_block_height, " ")
        elseif event_type == "key_down" then
          local _, entity, flags, key, player = table.unpack(ev)
          if key == keyboard.keys.q then
            done = true
          end
        end
      end

      clear_display(palette:get("white"), palette:get("black"))
      gpu.setForeground(palette:get("white"))
      gpu.setBackground(palette:get("black"))
      gpu.setResolution(gw, gh)
      if screen.setTouchModeInverted then
        screen.setTouchModeInverted(touch_mode)
      end
      
      print("Good bye.")
    end
})
