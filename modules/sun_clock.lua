local sun_clock = {}

local date = require "date"

sun_clock.windows_hit = 'client'

function sun_clock.init(it, name, user)
    it.hour_offset = it.hour_offset or 0
end

function sun_clock.draw(it, name, user, state)
    local day_fraction = date(state.utc_datetime):addhours(it.hour_offset):spandays() % 1
    local split = (day_fraction * 2) % 1
    local is_pm = day_fraction * 2 >= 1
    if is_pm then
        love.graphics.setColor(0, 0, 0.5)
    else
        love.graphics.setColor(0.5, 0, 0)
    end
    love.graphics.rectangle('fill', 0, 0, it.dim[1] * split, it.dim[2])
    if is_pm then
        love.graphics.setColor(0.5, 0, 0)
    else
        love.graphics.setColor(0, 0, 0.5)
    end
    love.graphics.rectangle('fill', it.dim[1] * split, 0, it.dim[1], it.dim[2])
end

function sun_clock.click(it, name, user, state)
end

return sun_clock
