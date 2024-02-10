local datetime = {}

datetime.windows_hit = 'client'

function datetime.init(it, name, user)
    it.format = it.format or '%c'
    it.color = it.color or {1, 1, 1, 1}
    it.size = it.size or 1
    it.size_px = it.size * user.config.grid_size
    it.font_family = it.font_family or "mono"
    it.font = love.graphics.newFont(it.size_px, it.font_family)
    it.right = it.right or false
end

function datetime.draw(it, name, user, state)
    love.graphics.setColor(unpack(it.color))
    love.graphics.setFont(it.font)
    local str = os.date(it.format, state.time)
    if it.right then
        love.graphics.print(str, it.dim[1] - it.font:getWidth(str), 0)
    else
        love.graphics.print(str, 0, 0)
    end
end

function datetime.click(it, name, user, state)
end

return datetime
