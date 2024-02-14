local clock = {}

local srgb = require 'srgb'
local date = require 'date'

clock.windows_hit = 'caption'

function clock.init(it, name, user)
    it.size = math.min(it.region[3], it.region[4])
    it.size_px = user.grids(it.size)
    it.base_color = it.base_color or {0, 0, 0, 0.1}
    it.border_color = it.border_color or {0.3, 0.3, 0.3, 1}
    it.border_width = it.border_width or 0.3
    it.tick_spacing = it.tick_spacing or 0.3
    it.large_tick_color = it.large_tick_color or {0, 0, 0, 1}
    it.large_tick_width = it.large_tick_width or 0.15
    it.large_tick_length = it.large_tick_length or 0.3
    it.small_tick_color = it.small_tick_color or {0, 0, 0, 1}
    it.small_tick_width = it.small_tick_width or 0.1
    it.small_tick_length = it.small_tick_length or 0.1
    it.label_spacing = it.label_spacing or 0.8
    it.font_size = it.font_size or 0.5
    it.font_size_px = user.grids(it.font_size)
    it.font_color = it.font_color or {0, 0, 0, 1}
    it.font_family = it.font_family or 'fonts/Lato-Bold.ttf'
    it.font = love.graphics.newFont(it.font_family, it.font_size_px)
    it.pin_color = it.pin_color or {0, 0, 0, 1}
    it.pin_radius = it.pin_radius or 0.5
    it.hands = it.hands or {
        {
            width = 0.5,
            length = 0.5,
            color = {0, 0, 0, 1},
            rate = 2
        },
        {
            width = 0.5,
            length = 0.7,
            color = {0, 0, 0, 1},
            rate = 24
        },
        {
            width = 0.5,
            length = 1,
            color = {1, 0, 0, 1},
            rate = 24 * 60
        }
    }
    it.background = love.graphics.newCanvas(it.size_px, it.size_px, {msaa = 4})
    -- make background
    love.graphics.setCanvas(it.background)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setBlendMode("alpha")
    love.graphics.origin()
    -- draw base
    local cr = it.size_px / 2
    love.graphics.translate(it.size_px / 2, it.size_px / 2)
    love.graphics.setColor(it.border_color)
    love.graphics.circle('fill', 0, 0, cr)
    love.graphics.setBlendMode("replace")
    cr = cr - user.grids(it.border_width)
    love.graphics.setColor(it.base_color)
    love.graphics.circle('fill', 0, 0, cr)
    love.graphics.setBlendMode("alpha")
    cr = cr - user.grids(it.tick_spacing)
    -- draw ticks
    for large = 0, 11 do
        for small = 0, 4 do
            if small == 0 then
                love.graphics.setColor(it.large_tick_color)
                love.graphics.setLineWidth(user.grids(it.large_tick_width))
                love.graphics.line(0, -cr, 0, -cr+user.grids(it.large_tick_length))
            else
                love.graphics.setColor(it.small_tick_color)
                love.graphics.setLineWidth(user.grids(it.small_tick_width))
                love.graphics.line(0, -cr, 0, -cr+user.grids(it.small_tick_length))
            end
            love.graphics.rotate(2*math.pi / 60)
        end
    end
    -- draw labels
    love.graphics.setFont(it.font)
    cr = cr - user.grids(it.label_spacing)
    it.labels = it.labels or {'12', '3', '6', '9'}
    for i, text in ipairs(it.labels) do
        love.graphics.push()
        love.graphics.translate(0, -cr)
        love.graphics.rotate(-(i-1)/#it.labels * 2*math.pi)
        love.graphics.setColor(it.font_color)
        local width = it.font:getWidth(text)
        love.graphics.print(text, -width/2, -it.font:getHeight()/2)
        love.graphics.pop()
        love.graphics.rotate(1/#it.labels * 2*math.pi)
    end

    -- center pin
    love.graphics.setColor(it.pin_color)
    love.graphics.circle('fill', 0, 0, user.grids(it.pin_radius))

    love.graphics.setCanvas()
end

function clock.draw(it, name, user, state)
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(it.background)

    local r = it.size_px / 2

    -- draw hands
    love.graphics.translate(r, r)
    local day_fraction = date(state.local_datetime):spandays() % 1
    for i, hand in ipairs(it.hands) do
        love.graphics.push()
        love.graphics.rotate(day_fraction * hand.rate * 2*math.pi)
        love.graphics.setLineWidth(user.grids(hand.width))
        love.graphics.setColor(hand.color)
        love.graphics.line(0, 0, 0, -hand.length*r)
        love.graphics.pop()
    end

    love.graphics.setBlendMode("alpha")
end

return clock
