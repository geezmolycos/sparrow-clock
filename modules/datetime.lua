local datetime = {}

datetime.windows_hit = 'client'

function datetime.init(it, name, user)
    it.format = it.format or '%c'
    it.color = it.color or {1, 1, 1, 1}
    it.size = it.size or 1
    it.size_px = it.size * user.config.grid_size
    it.font_family = it.font_family or "mono"
    it.font = love.graphics.newFont(it.size_px, it.font_family)
    it.font:setFilter("nearest")
end

function datetime.draw(it, name, user, state)
    love.graphics.setColor(unpack(it.color))
    love.graphics.setFont(it.font)
    love.graphics.print(os.date(it.format, state.time), 0, 0)
end

function datetime.click(it, name, user, state)
end

return datetime
