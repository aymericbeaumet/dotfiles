-- Auto-reload config
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", hs.reload):start()

-- Disable animations
hs.window.animationDuration = 0

-- High-level wrapper to set the active window frame (+ urlevent binding)
function setWindowFrame(x, y, w, h)
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
hs.urlevent.bind('setWindowFrame', function(event, params)
  setWindowFrame(
    tonumber(params.x),
    tonumber(params.y),
    tonumber(params.w),
    tonumber(params.h)
  )
end)
