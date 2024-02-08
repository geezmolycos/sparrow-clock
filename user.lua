local user = {}

user.config = {
    grid_size = 16,
    cols = 24,
    rows = 8,
    items = {
        {
            type = "top",
            at = {18, 0},
            size = 2,
            span = {2, 2}
        },
        {
            type = "drag",
            at = {20, 0},
            size = 2,
            span = {2, 2}
        },
        {
            type = "close",
            at = {22, 0},
            size = 2,
            span = {2, 2}
        },
        {
            type = "datetime",
            at = {0, 0},
            size = 2,
            span = {24, 2},
            format = "%Y-%m-%d"
        },
        {
            type = "datetime",
            at = {0, 2},
            size = 4,
            span = {24, 4},
            format = "%H:%M:%S"
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
    mouse_pressed_active = 1
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

return user
