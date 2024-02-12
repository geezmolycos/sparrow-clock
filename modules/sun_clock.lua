local sun_clock = {}

local date = require "date"
local srgb = require "srgb"

sun_clock.windows_hit = 'client'

function sun_clock.init(it, name, user)
    it.size = {it.region[3], it.region[4]}
    it.size_px = {it.size[1] * user.config.grid_size, it.size[2] * user.config.grid_size}
    it.hour_offset = it.hour_offset or 0
    it.day_color = it.day_color or {srgb.to_float_range(135, 206, 250)}
    it.night_color = it.night_color or {srgb.to_float_range(25, 25, 112)}
    it.sun_color = it.sun_color
    it.moon_color = it.moon_color
    it.day_length = it.day_length or 0.3
    it.gradient_length = it.gradient_length or 0.3
    it.gradient_steps = it.gradient_steps or 16
    local range = {}
    for i = 1, it.gradient_steps do
        table.insert(range, i / (it.gradient_steps + 1))
    end
    it.gradient = srgb.interpolate(range, it.day_color, it.night_color)
    it.bar = love.graphics.newCanvas(it.size_px[1], it.size_px[2] * 2)

    love.graphics.setCanvas(it.bar)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setBlendMode("alpha")
    love.graphics.origin()

    local day_no_gradient_width = (it.day_length - it.gradient_length) * it.size_px[1] * 2
    local night_no_gradient_width = (1 - it.day_length - it.gradient_length) * it.size_px[1] * 2
    local gradient_width = it.gradient_length * it.size_px[1] * 2
    local gradient_step_width = gradient_width / it.gradient_steps
    local cx = 0
    local function colorize(width, color)
        love.graphics.setColor(color)
        love.graphics.rectangle('fill', cx, 0, cx+width, it.size_px[2])
        cx = cx + width
    end
    -- midnight to before dawn
    colorize(night_no_gradient_width/2, it.night_color)
    -- dawn
    for i = 1, it.gradient_steps do
        colorize(gradient_step_width, it.gradient[i])
    end
    -- day
    colorize(day_no_gradient_width, it.day_color)
    -- dusk
    for i = 0, it.gradient_steps-1 do
        colorize(gradient_step_width, it.gradient[it.gradient_steps - i])
    end
    -- after dusk to midnight
    colorize(night_no_gradient_width/2, it.night_color)
    love.graphics.setCanvas()
end

function sun_clock.draw(it, name, user, state)
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(it.bar, 0,0)
    love.graphics.setBlendMode("alpha")
end

function sun_clock.click(it, name, user, state)
end

return sun_clock
