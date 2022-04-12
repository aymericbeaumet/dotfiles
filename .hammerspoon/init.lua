-- Disable animations
hs.window.animationDuration = 0

-- Watch configuration to auto-reload
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", hs.reload):start()

-- Listen for application events from hammerspoon://...

hs.urlevent.bind('launchOrFocusApplication', function(event, params)
  hs.application.launchOrFocus(params.name)
end)

hs.urlevent.bind('moveFocusedWindowNextScreen', function(event, params)
  local currentWindow = hs.window.focusedWindow()
  local currentScreen = currentWindow:screen()
  currentWindow:move(
    currentWindow:frame():toUnitRect(currentScreen:frame()),
    currentScreen:next(),
    true,
    0
  )
end)

hs.urlevent.bind('setCurrentWindowFrame', function(event, params)
  local x = tonumber(params.x)
  local y = tonumber(params.y)
  local w = tonumber(params.w)
  local h = tonumber(params.h)
  local currentWindow = hs.window.focusedWindow()
  local fullFrame = currentWindow:screen():fullFrame()
  currentWindow:setFrame(hs.geometry.rect(
    fullFrame.w * x + fullFrame.topleft.x,
    fullFrame.h * y + fullFrame.topleft.y,
    fullFrame.w * w,
    fullFrame.h * h
  ))
end)
