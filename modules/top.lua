local top = {}

local windows = require "windows"

top.windows_hit = 'client'

function top.init(it, name, user)
    it.size = it.size or it.region[3]
    it.size_px = it.size * user.config.grid_size
end

function top.draw(it, name, user, state)
    if state.mouse_moved then
        love.graphics.setLineWidth( 0.1 * it.size_px )
        love.graphics.setColor(.7, .7, .7)
        love.graphics.rectangle('fill', 0, 0, it.size_px, it.size_px)
        love.graphics.setColor(.3, .3, .3)
        love.graphics.rectangle('line', 0.3 * it.size_px, 0.3 * it.size_px, 0.4 * it.size_px, 0.4 * it.size_px)
        if windows.at_bottom then
            love.graphics.rectangle('fill', 0.3 * it.size_px, 0.3 * it.size_px, 0.4 * it.size_px, 0.2 * it.size_px)
        else
            love.graphics.rectangle('fill', 0.3 * it.size_px, 0.5 * it.size_px, 0.4 * it.size_px, 0.2 * it.size_px)
        end
    end
end

function top.click(it, name, user, state)
    if windows.at_bottom then
        -- make top
        windows.set_top(windows.get_hwnd())
    else
        windows.set_bottom(windows.get_hwnd())
    end
end

return top
