local sun_clock = {}

local date = require "date"
local srgb = require "srgb"
local inspect = require "inspect"

sun_clock.windows_hit = 'client'

function sun_clock.init(it, name, user)
    it.size = {it.region[3], it.region[4]}
    it.size_px = {it.size[1] * user.config.grid_size, it.size[2] * user.config.grid_size}
    it.hour_offset = it.hour_offset or 0
    it.day_color = it.day_color or {srgb.to_float_range(135, 206, 250)}
    it.night_color = it.night_color or {srgb.to_float_range(25, 25, 112)}
    it.sun_color = it.sun_color or {srgb.to_float_range(255, 255, 255)}
    it.sun_border_color = it.sun_border_color or {srgb.to_float_range(255, 255, 255)}
    it.moon_color = it.moon_color or {srgb.to_float_range(192, 192, 192)}
    it.show_length = it.show_length or 0.5
    it.day_length = it.day_length or 0.5
    it.gradient_length = it.gradient_length or 0.1
    it.gradient_steps = it.gradient_steps or 32
    local range = {}
    for i = 1, it.gradient_steps do
        table.insert(range, i / (it.gradient_steps + 1))
    end
    it.gradient = srgb.interpolate_in_linear(range, it.day_color, it.night_color)
    it.bar = love.graphics.newCanvas(it.size_px[1] / it.show_length, it.size_px[2])

    love.graphics.setCanvas({it.bar, stencil=true})
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setBlendMode("alpha")
    love.graphics.origin()

    local day_no_gradient_width = (it.day_length - it.gradient_length) * it.size_px[1] / it.show_length
    local night_no_gradient_width = (1 - it.day_length - it.gradient_length) * it.size_px[1] / it.show_length
    local gradient_width = it.gradient_length * it.size_px[1] / it.show_length
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

    -- sun
    local sun_center = 0.5 * it.size_px[1] / it.show_length
    local sun_radius = 0.7 * 0.5 * it.size_px[2]
    love.graphics.setColor(it.sun_color)
    love.graphics.circle('fill', sun_center, 0.5 * it.size_px[2], sun_radius)
    love.graphics.setColor(it.sun_border_color)
    love.graphics.setLineWidth(0.05 * it.size_px[2])
    love.graphics.circle('line', sun_center, 0.5 * it.size_px[2], sun_radius)
    -- stars
    -- local star_radius = 0.15 * 0.5 * it.size_px[2]
    -- local function draw_star(x, y, dx)
    --     if not dx then dx = 0 end
    --     love.graphics.circle('fill', x * it.size_px[1] / it.show_length + dx * it.size_px[2], y * it.size_px[2], star_radius)
    -- end
    
    -- draw_star(0, 0.3); draw_star(0, 0.7); draw_star(1, 0.3); draw_star(1, 0.7)
    -- draw_star(1, 0.5, -0.2); draw_star(0, 0.5, 0.2);

    -- moon
    love.graphics.setColor(it.moon_color)
    for _, x in ipairs{0, 1} do
        love.graphics.stencil(function()
            love.graphics.circle('fill', -0.35 * it.size_px[2], 0.5 * it.size_px[2], 0.35 * math.sqrt(2) * it.size_px[2])
        end, "replace", 1)
        love.graphics.setStencilTest("equal", 0)
        love.graphics.circle('fill', 0, 0.5 * it.size_px[2], 0.7 * 0.5 * it.size_px[2])
        love.graphics.setStencilTest()
    end

    love.graphics.setCanvas()
end

function sun_clock.draw(it, name, user, state)
    local day_fraction = date(state.utc_datetime):addhours(it.hour_offset):spandays() % 1
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.stencil(function()
        love.graphics.rectangle('fill', 0, 0, it.size_px[1], it.size_px[2])
    end, "replace", 1)
    love.graphics.setStencilTest("equal", 1)
    love.graphics.draw(it.bar, (day_fraction) / it.show_length * it.size_px[1] + it.size_px[1] / 2, 0)
    love.graphics.draw(it.bar, (day_fraction-1) / it.show_length * it.size_px[1] + it.size_px[1] / 2, 0)
    love.graphics.draw(it.bar, (day_fraction-2) / it.show_length * it.size_px[1] + it.size_px[1] / 2, 0)
    love.graphics.setStencilTest()
    love.graphics.setBlendMode("alpha")
end

function sun_clock.click(it, name, user, state)
end

return sun_clock
