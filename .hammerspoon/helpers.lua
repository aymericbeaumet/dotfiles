local M = {}

-- Caffeine — toggle display sleep prevention
function M.toggleCaffeine()
    hs.caffeinate.toggle("displayIdle")
    local on = hs.caffeinate.get("displayIdle")
    hs.alert.show(on and "Caffeine ON" or "Caffeine OFF")
end

-- Returns a function that moves the focused window on screen.
-- position {x, y} is the top-left corner (0–1 fraction of screen).
-- size {w, h} is the window size (0–1 fraction of screen).
-- screenOffset shifts to an adjacent monitor (-1, 0, +1, …).
function M.moveWin(position, size, screenOffset)
    return function()
        local win = hs.window.focusedWindow()
        if not win then return end

        local screen = win:screen()
        for _ = 1, math.abs(screenOffset) do
            screen = (screenOffset > 0) and screen:next() or screen:previous()
        end

        local f = screen:frame()
        local pos = position or {x = (1 - size.w) / 2, y = (1 - size.h) / 2}
        win:setFrame({
            x = f.x + f.w * pos.x,
            y = f.y + f.h * pos.y,
            w = f.w * size.w,
            h = f.h * size.h,
        })
    end
end

return M
