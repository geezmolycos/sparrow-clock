local user = {}

user.config = {
    grid_size = 16,
    cols = 24,
    rows = 16,
    items = {
        {
            type = "top",
            region = {18, 0, 2, 2}
        },
        {
            type = "drag",
            region = {20, 0, 2, 2}
        },
        {
            type = "close",
            region = {22, 0, 2, 2}
        },
        {
            type = "datetime",
            region = {0, 0, 24, 2},
            right = false,
            format = "%Y-%m-%d",
            before_draw = function (it, name, user, state)
                love.graphics.setColor(0, 0, 0, 0.3)
                love.graphics.rectangle('fill', 0, 0, user.grids(24), user.grids(2))
            end
        },
        {
            type = "datetime",
            region = {0, 2, 24, 4},
            right = false,
            format = "%H:%M:%S",
            before_draw = function (it, name, user, state)
                love.graphics.setColor(0, 0, 0, 0.3)
                love.graphics.rectangle('fill', 0, 0, user.grids(24), user.grids(4))
            end
        },
        {
            type = "sun_clock",
            region = {6, 6, 6, 2}
        },
        {
            type = "clock",
            region = {12, 6, 8, 8}
        }
    },
    window_display = 2,
    window_pos_x = 2560,
    window_pos_y = 0,
    window_snap_x = 16,
    window_snap_y = 16,
    window_anchor_x = 'right',
    window_anchor_y = 'top',
    mouse_moved_active = 1,
    mouse_pressed_active = 1,
    event_update_rate = 30,
    graphics_update_rate = 6
}

user.window_width = user.config.cols * user.config.grid_size
user.window_height = user.config.rows * user.config.grid_size
if user.config.window_anchor_x == 'middle' then
    user.window_x = user.config.window_pos_x - math.floor(user.window_width / 2)
elseif user.config.window_anchor_x == 'right' then
    user.window_x = user.config.window_pos_x - user.window_width
else
    user.window_x = user.config.window_pos_x
end
if user.config.window_anchor_y == 'middle' then
    user.window_y = user.config.window_pos_y - math.floor(user.window_height / 2)
elseif user.config.window_anchor_y == 'bottom' then
    user.window_y = user.config.window_pos_y - user.window_height
else
    user.window_y = user.config.window_pos_y
end

user.window_snap_offset_x = user.window_x % user.config.window_snap_x
user.window_snap_offset_y = user.window_y % user.config.window_snap_y

user.event_delay = 1 / user.config.event_update_rate
user.graphics_n = math.floor(user.config.event_update_rate / user.config.graphics_update_rate)

return user
