local keyboard = require("keyboard")
local safari = require("safari")
local utils = require("utils")
local windowManager = require("window-manager")

keyboard.registerBindings(
  -- Prevent mistakes
  {
    {{"cmd"}, "m", utils.noop}
  },
  -- Applications
  {
    {{"cmd", "ctrl"}, "a", utils.bind(hs.application.launchOrFocus, "Alacritty")},
    {{"cmd", "ctrl"}, "d", utils.bind(hs.application.launchOrFocus, "Dash")},
    {{"cmd", "ctrl"}, "g", utils.bind(hs.application.launchOrFocus, "Google Chrome")},
    {{"cmd", "ctrl"}, "n", utils.bind(hs.application.launchOrFocus, "Notion")},
    {{"cmd", "ctrl"}, "p", utils.bind(hs.application.launchOrFocus, "Pritunl")},
    {{"cmd", "ctrl"}, "s", utils.bind(hs.application.launchOrFocus, "Safari")},
    {{"cmd", "ctrl"}, "k", utils.bind(hs.application.launchOrFocus, "Slack")},
    {{"cmd", "ctrl"}, "v", utils.bind(hs.application.launchOrFocus, "Visual Studio Code")}
  },
  -- Window manager
  {
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
    {{"cmd", "alt"}, "l", windowManager.lockScreen},
    {{"cmd", "alt"}, "r", hs.reload},
    {{"cmd", "alt"}, "s", windowManager.moveFocusedWindowToNextScreen},
    {{"cmd", "alt"}, "v", keyboard.typePasteboard} -- useful to bypass antipaste protections
  },
  -- Emacs-like
  {
    {{"ctrl"}, "b", utils.bind(hs.eventtap.keyStroke, {}, "left")},
    {{"ctrl"}, "f", utils.bind(hs.eventtap.keyStroke, {}, "right")},
    {{"ctrl"}, "h", utils.bind(hs.eventtap.keyStroke, {}, "delete")},
    {{"ctrl"}, "i", utils.bind(hs.eventtap.keyStroke, {}, "tab")},
    {{"ctrl"}, "m", utils.bind(hs.eventtap.keyStroke, {}, "padenter")},
    {{"ctrl"}, "n", utils.bind(hs.eventtap.keyStroke, {}, "down")},
    {{"ctrl"}, "p", utils.bind(hs.eventtap.keyStroke, {}, "up")}
  },
  -- Emacs-like (except in Alacritty)
  {
    blacklist = {"Alacritty"},
    {{"ctrl"}, "a", utils.bind(hs.eventtap.keyStroke, {"cmd"}, "left")},
    {{"ctrl"}, "d", utils.bind(hs.eventtap.keyStroke, {}, "forwarddelete")},
    {{"ctrl"}, "e", utils.bind(hs.eventtap.keyStroke, {"cmd"}, "right")},
    -- {{"ctrl"}, "k", typeKeyStrokeFunctions({"shift"}, "end", {}, "delete")},
    {{"ctrl"}, "u", utils.bind(hs.eventtap.keyStroke, {"cmd"}, "delete")},
    {{"ctrl"}, "w", utils.bind(hs.eventtap.keyStroke, {"alt"}, "delete")},
    {{"alt"}, "b", utils.bind(hs.eventtap.keyStroke, {"alt"}, "left")},
    {{"alt"}, "d", utils.bind(hs.eventtap.keyStroke, {"alt"}, "forwarddelete")},
    {{"alt"}, "f", utils.bind(hs.eventtap.keyStroke, {"alt"}, "right")}
  },
  -- Safari improvements
  {
    whitelist = {"Safari"},
    {{"cmd"}, "b", safari.toggleBookmarks},
    {{"cmd", "shift"}, "r", safari.refreshWithoutCache},
    {{"cmd", "alt"}, "t", safari.closeOtherTabs}
  }
)

hs.alert("Hammerspoon ✔")
