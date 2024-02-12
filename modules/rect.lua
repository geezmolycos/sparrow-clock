local rect = {}

rect.windows_hit = 'client'

function rect.init(it, name, user)
    it.size = it.size or {1, 1}
    it.size_px = {it.size[1] * user.config.grid_size, it.size[2] * user.config.grid_size}
    it.color = it.color or {1, 1, 1}
end

function rect.draw(it, name, user, state)
    love.graphics.setColor(it.color)
    love.graphics.rectangle('fill', 0, 0, it.size_px[1], it.size_px[2])
end

function rect.click(it, name, user, state)
end

return rect
