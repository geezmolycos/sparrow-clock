
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end

love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. ';lua/?.lua;lua/?/init.lua')

local ffi = require "ffi"
local inspect = require "inspect"
local date = require "date"

if ffi.os ~= "Windows" then
    print("OS is not Windows, not implemented")
    love.window.showMessageBox( "Warning", "OS is not Windows, not implemented", "warning", false )
end

local windows = require "windows"
local windows_time = require "windows_time"
local succeed, user = pcall(require, "user_external")
if not succeed then
    user = require "user"
end

local items = user.config.items

local last_mouse_moved = -1000
local last_mouse_pressed = -1000

function user.grids(n)
    if type(n) == 'table' then
        local new_n = {}
        for i, it in ipairs(n) do
            table.insert(new_n, it * user.config.grid_size)
        end
        return new_n
    end
    return n * user.config.grid_size
end

local function within(pos, region)
    local x, y = unpack(pos)
    local x1, y1, w, h = unpack(region)
    local x2, y2 = x1+w, y1+h
    return x1 <= x and x < x2 and y1 <= y and y < y2
end

love.run = function()
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end

    local dt = 0
    local graphics_counter = 0
    local last_time = date(true)

    -- Main loop time.
    return function()
        -- Process events.
        if love.event then
            love.event.pump()
            for name, a,b,c,d,e,f in love.event.poll() do
                if name == "quit" then
                    if not love.quit or not love.quit() then
                        return a or 0
                    end
                end
                love.handlers[name](a,b,c,d,e,f)
            end
        end

        -- Update dt, as we'll be passing it to update
        if love.timer then dt = love.timer.step() end

        -- Call update and draw
        if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

        if love.graphics and love.graphics.isActive() then
            local new_time = date(true)
            if new_time:getseconds() ~= last_time:getseconds() then
                graphics_counter = 0 -- second update, refresh immediately
            end
            last_time = new_time
            if graphics_counter == 0 then
                graphics_counter = user.graphics_n
                love.graphics.origin()
                love.graphics.clear(love.graphics.getBackgroundColor())

                if love.draw then love.draw() end

                love.graphics.present()
            end
            graphics_counter = graphics_counter - 1
        end

        if love.timer then love.timer.sleep(user.event_delay) end
    end
end

love.load = function(args)
    function user.log(...) return end
    if args[1] == 'debug' then
        user.debug = true
        function user.log(...)
            local date_str = os.date('%Y-%m-%d %H:%M:%S', os.time())
            for i, item in ipairs({...}) do
                if i == 1 then
                    print('[' .. date_str .. '] ')
                else
                    print(string.rep(' ', string.len(date_str) + 3))
                end
                if type(item) == 'string' then
                    print(item)
                else
                    print(inspect(item))
                end
            end
        end
    end
    -- for debugging
    user.time_offset = 0
    user.time_rate = 1

    for name, it in ipairs(items) do
        if not it.region then error(tostring(name) .. " with no region") end
        it.click_region = it.click_region or it.region
        it.region_px = user.grids(it.region)
        it.click_region_px = user.grids(it.click_region)
        it.module = require("modules/" .. it.type)
    end
    
    local function hittest(x, y)
        for name, it in ipairs(items) do
            if within({x, y}, it.click_region_px) then
                return it.windows_hit or it.module.windows_hit or "client"
            end
        end
        return "client"
    end
    
    windows.init(user, hittest)
    
    local font = love.graphics.newFont(user.config.grid_size, "mono")
    love.graphics.setFont(font)
    
    for name, it in ipairs(items) do
        it.module.init(it, name, user)
    end
end

local function debug_draw_grid()
    love.graphics.origin()
    love.graphics.setLineWidth(1)
    for x = 0, user.config.cols-1 do
        if x % 5 == 0 then
            love.graphics.setColor(1, 0, 0, 0.5)
        else
            love.graphics.setColor(1, 1, 1, 0.5)
        end
        love.graphics.line(x * user.config.grid_size, 0, x * user.config.grid_size, user.window_height)
    end
    for y = 0, user.config.rows-1 do
        if y % 5 == 0 then
            love.graphics.setColor(1, 0, 0, 0.5)
        else
            love.graphics.setColor(1, 1, 1, 0.5)
        end
        love.graphics.line(0, y * user.config.grid_size, user.window_width, y * user.config.grid_size)
    end
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.setLineWidth(2)
    -- draw item boundaries
    for name, it in ipairs(items) do
        
        love.graphics.rectangle('line', it.region_px[1], it.region_px[2], it.region_px[3], it.region_px[4])
    end
end

local function debug_draw_mouse()
    local x, y = love.mouse.getPosition()
    local gx = x / user.config.grid_size
    local gy = y / user.config.grid_size
    love.graphics.origin()
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(tostring(math.floor(gx)) .. ', ' .. tostring(math.floor(gy)), x, y)
end

love.draw = function()
    
    local timer = love.timer.getTime()
    -- time offset is for debugging
    local utc_datetime
    if user.debug then
        utc_datetime = date{sec = windows_time.get_datetime():spanseconds() * user.time_rate + user.time_offset}
    else
        utc_datetime = windows_time.get_datetime()
    end
    
    local state = {
        utc_datetime = utc_datetime,
        local_datetime = date(utc_datetime):tolocal(),
        last_mouse_moved = last_mouse_moved,
        last_mouse_pressed = last_mouse_pressed,
        timer = timer,
        mouse_moved = timer - last_mouse_moved < user.config.mouse_moved_active,
        mouse_pressed = timer - last_mouse_pressed < user.config.mouse_pressed_active,
    }

    for name = #items, 1, -1 do -- render top last
        it = items[name]
        love.graphics.push()
        love.graphics.translate(it.region_px[1], it.region_px[2])
        if it.before_draw then it.before_draw(it, name, user, state) end
        it.module.draw(it, name, user, state)
        if it.after_draw then it.after_draw(it, name, user, state) end
        love.graphics.pop()
    end

    if user.debug then
        debug_draw_grid()
        debug_draw_mouse()
    end
    
end

local function debug_process_keys(key)
    local offset = ({
        e = -60*60*24*((365*4+1)*25-1),
        r = -60*60*24*365,
        t = -60*60*24*30,
        s = -60*60*24,
        d = -60*60,
        f = -60,
        g = -1,
        h = 1,
        j = 60,
        k = 60*60,
        l = 60*60*24,
        y = 60*60*24*30,
        u = 60*60*24*365,
        i = 60*60*24*((365*4+1)*25-1)
    })[key]
    if offset then
        user.time_offset = user.time_offset + offset
    end
    local rate = ({
        v = 1/4,
        b = 1/math.sqrt(2),
        n = math.sqrt(2),
        m = 4,
        [','] = 1,
        ['.'] = 1
    })[key]
    if rate then
        local current_datetime = windows_time.get_datetime()
        local display_datetime = date{sec = current_datetime:spanseconds() * user.time_rate + user.time_offset}
        local new_rate = user.time_rate * rate
        if key == ',' then -- reverse time
            new_rate = -new_rate
        end
        if key == '.' then
            new_rate = 1 -- normal rate
        end
        local new_offset = display_datetime:spanseconds() - current_datetime:spanseconds() * new_rate
        user.time_offset = new_offset
        user.time_rate = new_rate
    end
    if key == ';' then -- reset
        user.time_offset = 0
        user.time_rate = 1
    end
end

local last_key = 'a'
local current_key
local in_repeat = false
local press_time = 0

love.update = function(dt)
    if last_key == current_key then
        press_time = press_time + dt
        if not in_repeat and press_time > 1 then
            in_repeat = true
        end
        if in_repeat and press_time > 0.2 then
            debug_process_keys(current_key)
            press_time = 0
        end
    end
end

love.mousemoved = function(x, y, ...)
    last_mouse_moved = love.timer.getTime()
    for name, it in ipairs(items) do
        if it.module.mouse and within({x, y}, it.click_region_px) then
            local state = {
                x = (x - it.region_px[1]) / user.config.grid_size,
                y = (y - it.region_px[2]) / user.config.grid_size
            }
            it.module.mouse(it, name, user, state)
            break
        end
    end
end

love.mousepressed = function(x, y, button, ...)
    last_mouse_pressed = love.timer.getTime()
    last_mouse_moved = love.timer.getTime()
    for name, it in ipairs(items) do
        if it.module.click and within({x, y}, it.click_region_px) then
            local state = {
                x = (x - it.region_px[1]) / user.config.grid_size,
                y = (y - it.region_px[2]) / user.config.grid_size,
                button = button
            }
            user.log('clicked' .. tostring(name)  .. inspect{x=x, y=y, button=button})
            it.module.click(it, name, user, state)
            break
        end
    end
end

love.mousereleased = function(x, y, button, ...)
    last_mouse_pressed = love.timer.getTime()
    for name, it in ipairs(items) do
        if it.module.release and within({x, y}, it.click_region_px) then
            local state = {
                x = (x - it.region_px[1]) / user.config.grid_size,
                y = (y - it.region_px[2]) / user.config.grid_size,
                button = button
            }
            it.module.release(it, name, user, state)
            break
        end
    end
end

love.wheelmoved = function(x, y)
end

love.keypressed = function(key, ...)
    if user.debug then
        debug_process_keys(key)
    end
    current_key = key
    last_key = key
end

love.keyreleased = function(key, ...)
    current_key = nil
    in_repeat = false
end

love.textinput = function(t)
end

love.quit = function()
end
