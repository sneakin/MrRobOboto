local DEFAULTS = {
  gpu = "67345"
  screen = "5a449"
  width = 6 * 4
  height = 3 * 1
  msg = {
    "     Welcome to the",
    "      home of the",
    "      Sneaky Dean!"
  },
  bg = 0,
  fg = 0x00FFFF
}

function start(options)
  options = sneaky.merge(DEFAULTS, options)

  c = require("component")
  g = c.proxy(c.get(options.gpu))
  s = c.proxy(c.get(options.screen))

  g.bind(s.address)
  g.setResolution(options.width, options.height)
  g.setBackground(options.bg)
  g.setForeground(options.fg)
  g.fill(1, 1, options.width, options.height, " ")
  g.set(1, 1, options.msg[1])
  g.set(1, 2, options.msg[2])
  g.set(1, 3, options.msg[3])
end
