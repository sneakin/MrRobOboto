local Net = {
  MAX_PORT = 256
}

function Net.random_port(modem)
  local port

  repeat
    port = math.random(Net.MAX_PORT)
  until not modem.isOpen(port)

  return port
end

return Net
