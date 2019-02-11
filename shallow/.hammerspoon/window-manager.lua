local module = {}

function module.lockScreen()
  hs.osascript.applescript(
    [[
      tell application "System Events"
        tell process "Finder"
          click menu item "Lock Screen" of menu "Apple" of menu bar 1
        end tell
      end tell
    ]]
  )
end

-- (takes care of resizing the window if it doesn't fit in the target screen)
function module.moveFocusedWindowToNextScreen()
  local currentWindow = hs.window.focusedWindow()
  local currentScreen = currentWindow:screen()
  local currentScreenFrame = currentScreen:fullFrame()
  local nextScreenFrame = currentScreen:next():fullFrame()
  local frame = currentWindow:frame()
  local relativeX = frame.x - currentScreenFrame.topleft.x
  local relativeY = frame.y - currentScreenFrame.topleft.y
  frame.w = math.min(frame.w, nextScreenFrame.w - relativeX)
  frame.h = math.min(frame.h, nextScreenFrame.h - relativeY)
  frame.x = relativeX + nextScreenFrame.topleft.x
  frame.y = relativeY + nextScreenFrame.topleft.y
  currentWindow:setFrame(frame, 0)
end

function module.resizeFocusedWindow(x, y, w, h)
  local currentWindow = hs.window.focusedWindow()
  local currentScreen = currentWindow:screen()
  local maxFrame = currentScreen:fullFrame()
  local frame = currentWindow:frame()
  frame.x = maxFrame.w * x + maxFrame.topleft.x
  frame.y = maxFrame.h * y + maxFrame.topleft.y
  frame.w = maxFrame.w * w
  frame.h = maxFrame.h * h
  currentWindow:setFrame(frame, 0)
end

return module
