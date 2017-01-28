local Logger = require("sneaky/logger")
local RPCServer = require("net/rpc/server")
local component = require("component")
local serialization = require("serialization")
local Site = require("rob/site")

local coordinator = {
  DEFAULT_PORT = 59,
  rpc_calls = {}
}

function coordinator.rpc_calls.disco(client, site_secret)
  -- todo auth the robot
  Site.instance():track_robot(client:remote_address())
  return {
    name = coordinator.node_name,
    address = client:src_address(),
    position = coordinator.node
  }
end

function coordinator.rpc_calls.whoami(client, site_secret, computer_addr, robot_addr)
  local authed = Site.instance():check_secret(site_secret)

  Site.instance():track_robot(client:remote_address())
  Logger.notice("coordinatord", "whoami", client:remote_address())

  if not authed then
    return false, "invalid site secret"
  end
  
  local bot = Site.instance():find_robot(client:remote_address())
  if bot then
    if not bot.authorized then
      Logger.notice("coordinatord", "unauthorized robot", client:remote_address(), bot.position())
    end
    
    return true, {
             name = bot.name,
             facing = bot.facing,
             offset = bot.offset,
             origin = bot.origin,
             from = client:src_address(),
             secret = Site.instance():generate_secret()
                 }
  else
    Logger.warning("coordinatord", "unknown robot", client:remote_address(), client:getLastDistance())
    return false, "unknown robot"
  end
end

function coordinator.rpc_calls.robot_update(client, record)
  return Site.instance():robot_update(client:remote_address(), client:getLastDistance(), record)
end

function coordinator.set_node(node_name)
  assert(node_name, "coordinator's node on the site not given")
  local site = Site.instance()
  local node = site:find_node(node_name)
  assert(node, "coordinator's node not found")
  coordinator.node_name = node_name
  coordinator.node = node
end

local component = require("component")

function coordinator.start(node)
  coordinator.set_node(node)
  
  if coordinator.instance then
    coordinator.stop()
  end

  print("coordinatord starting for site " .. Site.instance().name .. " on port " .. tostring(coordinator.DEFAULT_PORT))
  coordinator.instance = RPCServer:new(component.modem, coordinator.DEFAULT_PORT, coordinator.rpc_calls)
  coordinator.instance:start()
end

function coordinator.stop()
  if not coordinator.instance then
    return
  end

  print("Stopping coordinatord")
  coordinator.instance:stop()
end

return coordinator
