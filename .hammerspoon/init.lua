local h = require("helpers")

-- Disable window move/resize animations for instant snapping
hs.window.animationDuration = 0

-- Caffeine (⌥⇧C)
hs.hotkey.bind({"alt", "shift"}, "C", h.toggleCaffeine)

-- Halves (⌥ + hjkl)
hs.hotkey.bind({"alt"}, "H", h.moveWin({x=0,   y=0},   {w=0.5, h=1},    0))
hs.hotkey.bind({"alt"}, "L", h.moveWin({x=0.5, y=0},   {w=0.5, h=1},    0))
hs.hotkey.bind({"alt"}, "K", h.moveWin({x=0,   y=0},   {w=1,   h=0.5},  0))
hs.hotkey.bind({"alt"}, "J", h.moveWin({x=0,   y=0.5}, {w=1,   h=0.5},  0))

hs.hotkey.bind({"alt"}, "M", h.moveWin({x=0,    y=0},    {w=1,    h=1},    0))
hs.hotkey.bind({"alt", "shift"}, "M", h.moveWin(nil, {w=0.70, h=0.80}, 0))

-- Multi-monitor (⌥N, ⌥P)
hs.hotkey.bind({"alt"}, "N", h.moveWin({x=0, y=0}, {w=1, h=1},  1))
hs.hotkey.bind({"alt"}, "P", h.moveWin({x=0, y=0}, {w=1, h=1}, -1))

-- Auto-reload config when any file in ~/.hammerspoon changes
configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", hs.reload):start()

hs.alert.show("Hammerspoon reloaded")
