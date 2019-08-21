-- Disable animations
hs.window.animationDuration = 0

-- TODO: Watch battery level to notify

-- Watch configuration to auto-reload
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", hs.reload):start()

-- Watch Wi-Fi networks to notify
hs.wifi.watcher.new(function(watcher, message, interface)
  if message == "SSIDChange" then
    local network = hs.wifi.currentNetwork(interface)
    if network == nil then
      hs.alert.show("[Wi-Fi] KO")
    else
      hs.alert.show("[Wi-Fi] " .. network)
    end
  end
end):watchingFor({ "SSIDChange" }):start()

-- Wrapper to launch or focus an application
hs.urlevent.bind('launchOrFocus', function(event, params)
  hs.application.launchOrFocus(params.name)
end)

-- Wrapper to set the active window frame
hs.urlevent.bind('setActiveWindowFrame', function(event, params)
  setActiveWindowFrame(
    tonumber(params.x),
    tonumber(params.y),
    tonumber(params.w),
    tonumber(params.h)
  )
end)
function setActiveWindowFrame(x, y, w, h)
  local currentWindow = hs.window.focusedWindow()
  local fullFrame = currentWindow:screen():fullFrame()
  local newFrame = hs.geometry.rect(
    fullFrame.w * x + fullFrame.topleft.x,
    fullFrame.h * y + fullFrame.topleft.y,
    fullFrame.w * w,
    fullFrame.h * h
  )
  currentWindow:setFrame(newFrame)
end
