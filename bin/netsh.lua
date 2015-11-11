local computer = require("computer")
local keyboard = require("keyboard")
local event = require("event")
local term = require("term")
local string = require("string")
local serialization = require("serialization")
local table = require("table")
local component = require("component")
local net = component.internet

local MOTD = "Welcome to netsh @ %s\n\nTo add a remote shell enter: service.tcp(host, port)\n"

local line_buffer = {
   keys = {},
   lines = {}
}

function line_buffer.init()
   term.setCursorBlink(true)
end

function line_buffer.onKey(char, code)
   if code == keyboard.keys.back then
      if #line_buffer.keys > 0 then
         table.remove(line_buffer.keys)
         local x, y = term.getCursor()
         term.setCursor(x - 1, y)
      end
   elseif code == keyboard.keys.enter then
      table.insert(line_buffer.keys, string.char(char))
      table.insert(line_buffer.lines, table.concat(line_buffer.keys))
      line_buffer.keys = {}
      io.write("\n")
   elseif char > 0 then
      io.write(string.char(char))
      table.insert(line_buffer.keys, string.char(char))
   end
end

function line_buffer.update()
   local name, addr, char, code, player = event.pull(0, "key_down")
   if name then
      line_buffer.onKey(char, code)
   end
end

function line_buffer.read()
   if #line_buffer.lines > 0 then
      return table.remove(line_buffer.lines, 1)
   else
      return ""
   end
end

local sh = {
   global_io = {
      print = _G.print,
      read = _G.io.read,
      write = _G.io.write,
      close = _G.io.close,
      exit = _G.os.exit
   }
}

function new_shell(local_io, service)
   local s = {
      env = {
         io = {
            write = local_io.write,
            read = local_io.read,
            close = local_io.close
         },
         print = local_io.print,
         os = {
            exit = local_io.exit
         },
         service = service
      },
      global = _G,
      input_buffer = ""
   }

   setmetatable(s.env, { __index = _G })
   setmetatable(s.env.io, { __index = io })
   setmetatable(s.env.os, { __index = os })

   function s.welcome()
      local_io.write(string.format(MOTD, computer.address()))
      s.writePrompt()
   end

   function s.writePrompt(prompt)
      local_io.write(prompt or "> ")
   end

   function s.execute(cmd)
      return pcall(load(cmd, cmd, "t", s.env))
   end
      
   function s.update()
      local data = local_io.read()
      if not data then
         return false
      elseif string.len(data) == 0 then
         return true
      end

      s.input_buffer = s.input_buffer .. data

      repeat
         local a, b = string.find(s.input_buffer, "[\n\r]")
         --local_io.print("'" .. s.input_buffer .. "'", a, b)
         if not a then
            break
         end
         
         local line = string.sub(s.input_buffer, 1, a - 1)
         s.input_buffer = string.sub(s.input_buffer, a + 1)

         if string.sub(line, 1, 1) == "=" then
            line = "return(" .. string.sub(line, 2) .. ")"
         end

         local status, err = s.execute(line, io)

         if status then
            local_io.write("=> " .. tostring(err) .. "\n")
         elseif err.reason == "terminated" then
            return false
         else
            local_io.write("Error: " .. serialization.serialize(line) .. "\n" .. serialization.serialize(err) .. "\n")
            if debug and debug.traceback() then
               local_io.write(debug.traceback())
               local_io.write("\n")
            end
         end
      until a == nil

      if s.input_buffer == "" then
         s.writePrompt()
      end

      return true
   end

   function s.close()
      local_io.print("Goodbye\n")
      return local_io.close()
   end

   return s
end

function local_io()
   return {
      print = sh.global_io.print,
      read = line_buffer.read,
      write = sh.global_io.write,
      close = sh.global_io.close,
      exit = sh.global_io.exit,
   }
end

function tcp_io(host, port)
   local self = {}

   local connection

   function open()
      connection = assert(net.connect(host, port))

      if not connection.finishConnect() then
         assert(connection.finishConnect(), "Failed to connect to " .. host .. ":" .. port)
      end

      print("Connected to " .. host .. ":" .. port)
      return true
   end

   con_write = function(...)
      local args = {...}
      for k, v in pairs(args) do
         args[k] = tostring(v)
      end
      return connection.write(table.concat(args, "\t"))
   end

   function con_print(...)
      local r = con_write(...)
      con_write("\n")
   end

   local done = nil

   function con_read()
      if done then
         return nil
      else
         return connection.read()
      end
   end

   function con_exit(...)
      done = {...}
   end

   open()
   
   return {
      read = con_read,
      write = con_write,
      close = connection.close,
      exit = con_exit,
      print = con_print,
   }
end

service = {
   shells = {}
}

function service.addShell(io)
   local s = new_shell(io, service)
   table.insert(service.shells, s)
   s.welcome()
end

function service.tcp(host, port)
   return service.addShell(tcp_io(host, port))
end

function service.run()
   local done = false

   line_buffer.init()
   
   repeat
      local ev
      
      repeat
         line_buffer.update()
      until name == nil

      done = true
      for i, shell in pairs(service.shells) do
         done = false
         if not shell.update() then
            shell.close()
            table.remove(service.shells, i)
         end
      end
   until done == true

   return done
end

local args = {...}

if args[1] and args[2] then
   local host = args[1]
   local port = tonumber(args[2] or 25678)
   service.tcp(host, port)
end

service.addShell(local_io())

os.exit(service.run())
