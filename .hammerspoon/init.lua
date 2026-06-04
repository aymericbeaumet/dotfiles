local h = require("helpers")

-- Disable window move/resize animations for instant snapping
hs.window.animationDuration = 0

-- Caffeine (⌥⇧C)
hs.hotkey.bind({ "alt", "shift" }, "C", h.toggleCaffeine)

-- Auto-reload config when any file in ~/.hammerspoon changes
configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", hs.reload):start()

hs.alert.show("Hammerspoon reloaded")
