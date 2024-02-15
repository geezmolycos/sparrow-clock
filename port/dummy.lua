local dummy = {}

local date = require "date"

function dummy.get_hwnd()
    return 'dummy hwnd'
end

function dummy.set_top(hwnd)
    dummy.at_bottom = false
end

function dummy.set_bottom(hwnd)
    dummy.at_bottom = true
end

function dummy.init(user, hittest)
    love.window.setMode(
        user.window_width, user.window_height,
        { borderless = true, resizable = false, vsync = 0, msaa = 4,
          display = user.config.window_display, x = user.window_x, y = user.window_y,
          highdpi = true, usedpiscale = false }
    )
    if user.config.window_bottom then
        dummy.set_bottom(dummy.get_hwnd())
    else
        dummy.set_top(dummy.get_hwnd())
    end
    love.graphics.setBackgroundColor(0, 0, 0, 0)
end

function dummy.get_datetime()
    return date(true)
end

return dummy
