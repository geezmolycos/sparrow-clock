local clock = {}

clock.windows_hit = 'caption'

function clock.init(it, name, user)
    it.size = it.size or it.region[3]
    it.size_px = it.size * user.config.grid_size
end

function clock.draw(it, name, user, state)
    if state.mouse_moved then
        love.graphics.setLineWidth( 0.2 * it.size_px )
        love.graphics.setColor(.7, .7, .7)
        love.graphics.rectangle('fill', 0, 0, it.size_px, it.size_px)
        love.graphics.setColor(.3, .3, .3)
        love.graphics.circle('fill', 0.5 * it.size_px, 0.5 * it.size_px, 0.2 * it.size_px)
    end
end

return clock
