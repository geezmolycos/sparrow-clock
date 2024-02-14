local user = {}

local function draw_frame(user, x, y, w, h)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
    love.graphics.rectangle('fill', user.grids(x), user.grids(y), user.grids(w), user.grids(h))
    local border_width = user.grids(0.25)
    love.graphics.setLineWidth(border_width)
    love.graphics.setColor(37/255, 41/255, 49/255)
    love.graphics.rectangle('line',
        user.grids(x)+border_width/2, user.grids(y)+border_width/2,
        user.grids(w)-border_width, user.grids(h)-border_width
    )
    love.graphics.pop()
end

user.config = {
    grid_size = 64,
    cols = 25,
    rows = 7.5,
    items = {
        {
            type = "close",
            region = {23, 0, 2, 2}
        },
        {
            type = "drag",
            region = {21, 0, 2, 2}
        },
        {
            type = "top",
            region = {19, 0, 2, 2}
        },
        {
            type = "datetime",
            region = {0.5, 0.25, 11, 2},
            right = false,
            format = "%Y-%m-%d",
            before_draw = function (it, name, user, state)
                draw_frame(user, 0, 0, 12, 2.75)
            end
        },
        {
            type = "datetime",
            region = {0.5, 2.5, 16.5, 4},
            right = false,
            format = "%H:%M:%S",
            before_draw = function (it, name, user, state)
                draw_frame(user, 0, 2.5, 17.5, 5)
            end
        },
        {
            type = "sun_clock",
            region = {12.5, 0.75, 4, 1.25},
            show_length = 0.4,
            hour_offset = 8,
            before_draw = function (it, name, user, state)
                draw_frame(user, 11.75, 0, 5.75, 2.75)
            end,
            after_draw = function (it, name, user, state)
                local line_width = user.grids(1/8)
                -- brackets
                love.graphics.setColor(1, 1, 1)
                love.graphics.push()
                love.graphics.setLineWidth(line_width)
                local function corner() love.graphics.line(2*line_width,-line_width/2, -line_width/2,-line_width/2, -line_width/2,2*line_width) end
                corner()
                love.graphics.translate(0, user.grids(1.25))
                love.graphics.scale(1, -1)
                corner()
                love.graphics.translate(user.grids(4), 0)
                love.graphics.scale(-1, 1)
                corner()
                love.graphics.translate(0, user.grids(1.25))
                love.graphics.scale(1, -1)
                corner()
                love.graphics.pop()

                -- pointer
                love.graphics.push()
                love.graphics.translate(user.grids(2), 0)
                -- love.graphics.polygon('fill', -2*line_width,-line_width, 0,2*line_width, 2*line_width,-line_width)
                love.graphics.translate(0, user.grids(1.25))
                love.graphics.scale(1, -1)
                love.graphics.polygon('fill', -2*line_width,-line_width, 0,2*line_width, 2*line_width,-line_width)
                love.graphics.pop()
            end
        },
        {
            type = "clock",
            region = {17.25, 0, 7.5, 7.5},
            base_color = {0.1, 0.1, 0.1, 0.7},
            border_color = {37/255, 41/255, 49/255},
            border_width = 0.25,
            tick_spacing = 0.3,
            large_tick_color = {1, 1, 1, 1},
            large_tick_width = 0.2,
            large_tick_length = 0.6,
            small_tick_color = {0, 0, 0, 0},
            label_spacing = 1.2,
            font_color = {1, 1, 1, 1},
            pin_color = {1, 1, 1, 1},
            pin_radius = 0.2,
            hands = {
                {
                    width = 0.15,
                    length = 0.4,
                    color = {1, 1, 1, 1},
                    rate = 2
                },
                {
                    width = 0.1,
                    length = 0.6,
                    color = {1, 1, 1, 1},
                    rate = 24
                },
                {
                    width = 0.08,
                    length = 0.8,
                    color = {62/255, 133/255, 226/255, 1},
                    rate = 24 * 60
                }
            },
            before_draw = function (it, name, user, state)
                draw_frame(user, 17.25, 0, 7.5, 7.5)
            end,
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
