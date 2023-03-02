-- Disable animations
hs.window.animationDuration = 0

-- Watch configuration to auto-reload
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", hs.reload):start()

-- Listen for application events from hammerspoon://...

hs.urlevent.bind("launchOrFocusApplication", function(event, params)
	hs.application.launchOrFocus(params.name)
end)

hs.urlevent.bind("moveFocusedWindowNextScreen", function(event, params)
	local win = hs.window.focusedWindow()
	local screen = win:screen()
	win:move(win:frame():toUnitRect(screen:frame()), screen:next(), true, 0)
end)

hs.urlevent.bind("setCurrentWindowFrame", function(event, params)
	local x = tonumber(params.x)
	local y = tonumber(params.y)
	local w = tonumber(params.w)
	local h = tonumber(params.h)
	local win = hs.window.focusedWindow()
	local frame = win:screen():frame()
	win:setFrame(
		hs.geometry.rect(frame.w * x + frame.topleft.x, frame.h * y + frame.topleft.y, frame.w * w, frame.h * h)
	)
end)
