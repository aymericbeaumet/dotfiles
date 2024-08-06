local wezterm = require("wezterm")
local mux = wezterm.mux

local config = wezterm.config_builder()

config.color_scheme = "nord"
config.default_prog = { "/opt/homebrew/bin/zellij" }
config.enable_scroll_bar = false
config.enable_tab_bar = false
config.font = wezterm.font("FiraCode Nerd Font", { weight = 450, stretch = "Normal", style = "Normal" })
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "NONE"

return config
