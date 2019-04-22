local keyboard = require("keyboard")
local safari = require("safari")
local utils = require("utils")
local windowManager = require("window-manager")

keyboard.registerBindings(
  -- Window manager
  {
    {{"cmd", "alt"}, "c", utils.bind(windowManager.resizeFocusedWindow, 0.25, 0.25, 0.5, 0.5)}, -- center
    {{"cmd", "alt"}, "s", windowManager.moveFocusedWindowToNextScreen}, -- move to next screen
    {{"cmd", "alt"}, "space", utils.bind(windowManager.resizeFocusedWindow, 0, 0, 1, 1)}, -- fullscreen
    {{"cmd", "alt"}, "1", utils.bind(windowManager.resizeFocusedWindow, 0, 0, 0.5, 0.5)}, -- upper left 1/4
    {{"cmd", "alt"}, "2", utils.bind(windowManager.resizeFocusedWindow, 0.5, 0, 0.5, 0.5)}, -- upper right 1/4
    {{"cmd", "alt"}, "3", utils.bind(windowManager.resizeFocusedWindow, 0, 0.5, 0.5, 0.5)}, -- lower left 1/4
    {{"cmd", "alt"}, "4", utils.bind(windowManager.resizeFocusedWindow, 0.5, 0.5, 0.5, 0.5)}, -- lower right 1/4
    {{"cmd", "alt"}, "b", utils.bind(windowManager.resizeFocusedWindow, 0, 0, 0.5, 1)}, -- left 1/2
    {{"cmd", "alt"}, "f", utils.bind(windowManager.resizeFocusedWindow, 0.5, 0, 0.5, 1)}, -- right 1/2
    {{"cmd", "alt"}, "n", utils.bind(windowManager.resizeFocusedWindow, 0, 0.5, 1, 0.5)}, -- lower 1/2
    {{"cmd", "alt"}, "p", utils.bind(windowManager.resizeFocusedWindow, 0, 0, 1, 0.5)} -- upper 1/2
  },
  -- Convenience
  {
    {{"cmd", "alt"}, "v", keyboard.typePasteboard} -- useful to bypass antipaste protections
  },
  -- Safari only
  {
    whitelist = {"Safari"},
    {{"cmd"}, "b", safari.toggleBookmarks},
    {{"cmd", "shift"}, "r", safari.refreshWithoutCache},
    {{"cmd", "alt"}, "t", safari.closeOtherTabs}
  }
)

hs.alert("Hammerspoon ✔")
