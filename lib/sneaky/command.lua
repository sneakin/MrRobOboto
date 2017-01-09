local sneaky = require("sneaky/util")
local sides = require("sides")
local Command = {}

-- fixme `turn -1` thought -1 was an argument
-- todo argument parsing suitable for buildings
-- todo multiple values

local DEFAULT_OPTIONS = {
  name = "unamed",
  usage = "",
  required_values = 0,
  description = "Does something spectacular!",
  long_help = nil,
  allow_unknown = nil,
  arguments = {
    help = {
      description = "Prints this message.",
      default = nil,
      aborts = true,
      abort_message = function(cmd)
        return cmd:print_usage()
      end
    }
  },
  aliases = {
    h = "help"
  },
  run = function(options, args)
    return 0
  end
}

function Command:define(args, options)
  local cmd = self:new(options)
  return cmd:execute(args)
end

function Command:new(options)
  local c = sneaky.class(self, {})
  c.name = options.name or DEFAULT_OPTIONS.name
  c.usage = options.usage or DEFAULT_OPTIONS.usage
  c.required_values = options.required_values or DEFAULT_OPTIONS.required_values
  c.description = options.description or DEFAULT_OPTIONS.description
  c.long_help = options.long_help or DEFAULT_OPTIONS.long_help
  c.allow_unknown = options.allow_unknown or DEFAULT_OPTIONS.allow_unknown
  c.aliases = sneaky.merge(DEFAULT_OPTIONS.aliases, options.aliases)
  c.run = options.run or DEFAULT_OPTIONS.run
  c.arguments = {}
  for name, arg in pairs(DEFAULT_OPTIONS.arguments) do
    c.arguments[name] = arg
  end
  if options.arguments then
    for name, arg in pairs(options.arguments) do
      c.arguments[name] = arg
    end
  end
  return c
end

function Command:aliases_for(name)
  local aliases = {}
  for alias, arg in pairs(self.aliases) do
    if arg == name then
      table.insert(aliases, alias)
    end
  end
  return aliases
end

function Command:execute(args)
  local ok, options, rest = self:parse_args(args)

  if ok then
    local ok, reason = self:check_args(options)
    if ok then
      return self.run(options, rest)
    else
      return self:error_message(reason)
    end
  elseif options then
    return self:error_message(options)
  end
end

function Command:error_message(message)
  print("Error: " .. message)
end

function Command:print_usage()
  print("Usage")
  print("")
  print("  " .. self.name .. " [args...] " .. self.usage)
  print("")
  print("Description")
  print("")
  print("  " .. self.description)
  if self.long_help then
    print("\n  " .. sneaky.join(self.long_help, "\n  "))
  end
  print("")
  print("Arguments")
  print("")
  for name, arg in sneaky.pairsByKeys(self.arguments) do
    print("  " .. name)
    
    local aliases = self:aliases_for(name) 
    if aliases and #aliases > 0 then
      print("  " .. sneaky.join(table.sort(aliases), ", "))
    end

    if arg.description then
      print("    " .. arg.description)
    end
    
    if not arg.boolean and arg.default then
      print("    Default: " .. tostring(arg.default))
    end

    if arg.required then
      print("    Required")
    end

    print("")
  end
end

function Command:defaults()
  local r = {}
  for name, arg in pairs(self.arguments) do
    r[name] = arg.default
  end
  return r
end

function Command:find_argument(name)
  local arg = self.arguments[name]
  if arg then
    return name, arg
  else
    return self:resolve_alias(name)
  end
end

function Command:resolve_alias(name)
  local arg = self.aliases[name]
  if arg then
    return arg, self.arguments[arg]
  end
end

function Command:parse_args(args)
  local options = self:defaults()
  local values = {}
  local n = 1

  while n <= #args do
    local arg = args[n]
    local arg_name = string.match(arg, "^-+(.+)")
    
    if arg_name then
      local name, arg = self:find_argument(arg_name)
      if arg then
        local value = arg.default
        
        if arg.boolean then
          value = not arg.default
        else
          value = args[n + 1]
        end
        
        local valid = true

        if type(arg.validator) == "string" then
          if value then
            valid = string.match(value, arg.validator)
          elseif arg.allow_nil then
            valid = true
          end
        elseif type(arg.validator) == "function" then
          valid = arg.validator(args[n + 1])
        end

        if valid then
          if arg.parse_value then
            value = arg.parse_value(args[n + 1])
          end

          if arg.list then
            if not options[name] then
              options[name] = {}
            end
            table.insert(options[name], value)
          else
            options[name] = value
          end

          if not arg.boolean then
            n = n + 1
          end
        else
          return false, ("Invalid value for " .. arg_name .. ": " .. value), n
        end

        if arg.aborts then
          return false, arg.abort_message(self)
        end
      elseif self.allow_unknown then
        table.insert(values, arg)
      else
        return false, "Unknown argument: " .. arg_name, n
      end
    else
      table.insert(values, args[n])
    end

    n = n + 1
  end

  if #values >= self.required_values then
    return true, options, values
  else
    return false, "Not enough arguments: " .. self.required_values .. " required"
  end
end

function Command:check_args(options)
  for name, arg in pairs(self.arguments) do
    -- todo move validation here?
    if arg.required
      and options[name] == nil
      and (not arg.boolean and arg.default == nil)
    then
      return false, tostring(name) .. " must have a value."
    end
  end

  return true
end


----

Command.Argument = {}

function Command.Argument.Integer(options)
  return sneaky.merge(options, {
                        parse_value = tonumber,
                        validator = "^[-+]?[0-9]+"
  })
end

function Command.Argument.Float(options)
  return sneaky.merge(options, {
                        parse_value = tonumber,
                        validator = tonumber
  })
end

function Command.Argument.Side(options)
  return sneaky.merge(options, {
                        parse_value = function(v) return sides[v] end,
                        validator = function(v) return sides[v] ~= nil end
  })
end

return Command
