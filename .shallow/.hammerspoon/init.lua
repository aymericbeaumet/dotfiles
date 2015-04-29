handlers = {

  showHints = function()
    hs.hints.style = "vimperator"
    hs.hints.windowHints(hs.window.allWindows())
  end,

  launchOrFocusApplication = function(eventName, params)
    hs.application.launchOrFocus(params.name)
  end,

  resizeFocusedApplication = function(eventName, params)
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local max = win:screen():frame()
    if false then
      elseif params.to == 'maximum' then f.x = max.x ; f.y = max.y ; f.w = max.w ; f.h = max.h
      elseif params.to == 'left'    then f.x = max.x ; f.w = max.w / 2
      elseif params.to == 'bottom'  then f.y = max.y + max.h / 2 ; f.h = max.h / 2
      elseif params.to == 'top'     then f.y = max.y ; f.h = max.h / 2
      elseif params.to == 'right'   then f.x = max.x + max.w / 2 ; f.w = max.w / 2
    end
    win:setFrame(f)
  end,

  displayDate = function()
    hs.alert.show(os.date('%A, %B %d, %Y'))
  end,

  displayTime = function()
    hs.alert.show(os.date('%H:%M'))
  end,

  displayWiFiState = function()
    local wifiName = hs.wifi.currentNetwork()
    hs.alert.show(wifiName and 'WiFi ✔ (' .. wifiName .. ')' or 'WiFi ✘')
  end,

  displayBatteryState = function()
    local percentage = hs.battery.percentage()
    local powersource = hs.battery.powerSource()
    local message = 'Battery ' .. percentage .. '%'
    if powersource == 'AC Power' then
      hs.alert.show(message .. ' (' .. powersource .. ')')
    else
      hs.alert.show(message)
    end
  end,

  reloadConfiguration = function()
    hs.reload()
  end,

}

-- Setup handlers listening for Karabiner triggers
for event, handler in pairs(handlers) do
  hs.urlevent.bind(event, handler)
end

-- Setup watchers
hs.wifi.watcher.new(handlers.displayWiFiState):start()
hs.pathwatcher.new(hs.configdir, handlers.reloadConfiguration):start()

-- Notify when the configuration file has been successfully loaded
hs.notify.new({title="Hammerspoon", informativeText="Loaded"}):send():release()
