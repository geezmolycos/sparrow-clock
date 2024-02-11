
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end
-- Make sure the shared library can be found through package.cpath before loading the module.
-- For example, if you put it in the LÖVE save directory, you could do something like this:
local lua_path = love.filesystem.getSource() .. "/lua"
local lib_path = love.filesystem.getSource() .. "/lib"
local extension = jit.os == "Windows" and "dll" or jit.os == "Linux" and "so" or jit.os == "OSX" and "dylib"

package.path = string.format("%s;%s/?/init.lua", package.path, lua_path)
package.path = string.format("%s;%s/?.%s", package.path, lua_path, "lua")
package.cpath = string.format("%s;%s/?.%s", package.cpath, lib_path, extension)

local ffi = require "ffi"
local inspect = require "inspect"
local imgui = require "cimgui"
local date = require "date"

if ffi.os ~= "Windows" then
    print("OS is not Windows, not implemented")
    love.window.showMessageBox( "Warning", "OS is not Windows, not implemented", "warning", false )
end

local windows = require "windows"
local windows_time = require "windows_time"
local user = require "user"

local items = user.config.items

local last_mouse_moved = -1000
local last_mouse_pressed = -1000

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
    if args[1] == 'debug' then
        user.debug = true
    end
    -- for debugging
    user.time_offset = 0
    user.time_rate = 1

    for name, it in ipairs(items) do
        it.at = it.at or {0, 0}
        it.pos = {
            it.at[1] * user.config.grid_size,
            it.at[2] * user.config.grid_size
        }
        it.dim = {
            it.span[1] * user.config.grid_size,
            it.span[2] * user.config.grid_size
        }
        it.scale = it.scale or {1, 1}
        it.module = require("modules/" .. it.type)
    end
    
    local function hittest(x, y)
        for name, it in ipairs(items) do
            if  it.pos[1] <= x and x < it.pos[1] + it.dim[1]
            and it.pos[2] <= y and y < it.pos[2] + it.dim[2] then
                return it.windows_hit or it.module.windows_hit
            end
        end
        return "client"
    end
    
    windows.init(user, hittest)
    imgui.love.Init() -- or imgui.love.Init("RGBA32") or imgui.love.Init("Alpha8")
    
    local font = love.graphics.newFont(user.config.grid_size, "mono")
    love.graphics.setFont(font)
    
    for name, it in ipairs(items) do
        it.module.init(it, name, user)
    end
end

local function debug_draw_grid()
    love.graphics.origin()
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setLineWidth(1)
    for x = 0, user.config.cols-1 do
        love.graphics.line(x * user.config.grid_size, 0, x * user.config.grid_size, user.window_height)
    end
    for y = 0, user.config.rows-1 do
        love.graphics.line(0, y * user.config.grid_size, user.window_width, y * user.config.grid_size)
    end
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.setLineWidth(2)
    -- draw item boundaries
    for name, it in ipairs(items) do
        love.graphics.rectangle('line', it.pos[1], it.pos[2], it.dim[1], it.dim[2])
    end
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
        local_datetime = utc_datetime:tolocal(),
        last_mouse_moved = last_mouse_moved,
        last_mouse_pressed = last_mouse_pressed,
        timer = timer,
        mouse_moved = timer - last_mouse_moved < user.config.mouse_moved_active,
        mouse_pressed = timer - last_mouse_pressed < user.config.mouse_pressed_active,
    }

    for name = #items, 1, -1 do -- render top last
        it = items[name]
        love.graphics.push()
        love.graphics.translate(it.pos[1], it.pos[2])
        love.graphics.scale(it.scale[1], it.scale[2])
        it.module.draw(it, name, user, state)
        love.graphics.pop()
    end

    if user.debug then
        debug_draw_grid()
    end
    -- code to render imgui
    love.graphics.setColor(1, 1, 1)
    imgui.Render()
    imgui.love.RenderDrawLists()
    
end

love.update = function(dt)
    imgui.love.Update(dt)
    imgui.NewFrame()
end

love.mousemoved = function(x, y, ...)
    imgui.love.MouseMoved(x, y)
    if not imgui.love.GetWantCaptureMouse() then
        -- your code here
        last_mouse_moved = love.timer.getTime()
    end
end

love.mousepressed = function(x, y, button, ...)
    imgui.love.MousePressed(button)
    if not imgui.love.GetWantCaptureMouse() then
        -- your code here
        last_mouse_pressed = love.timer.getTime()
        last_mouse_moved = love.timer.getTime()
        for name, it in ipairs(items) do
            if  it.pos[1] <= x and x < it.pos[1] + it.dim[1]
            and it.pos[2] <= y and y < it.pos[2] + it.dim[2] then
                local state = {
                    x = (x - it.pos[1]) / user.config.grid_size,
                    y = (y - it.pos[2]) / user.config.grid_size,
                    button = button
                }
                print(name, inspect(state))
                it.module.click(it, name, user, state)
                break
            end
        end
    end
end

love.mousereleased = function(x, y, button, ...)
    imgui.love.MouseReleased(button)
    if not imgui.love.GetWantCaptureMouse() then
        -- your code here 
    end
end

love.wheelmoved = function(x, y)
    imgui.love.WheelMoved(x, y)
    if not imgui.love.GetWantCaptureMouse() then
        -- your code here 
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

love.keypressed = function(key, ...)
    imgui.love.KeyPressed(key)
    if not imgui.love.GetWantCaptureKeyboard() then
        if user.debug then
            debug_process_keys(key)
        end
    end
end

love.keyreleased = function(key, ...)
    imgui.love.KeyReleased(key)
    if not imgui.love.GetWantCaptureKeyboard() then
        -- your code here 
    end
end

love.textinput = function(t)
    imgui.love.TextInput(t)
    if imgui.love.GetWantCaptureKeyboard() then
        -- your code here 
    end
end

love.quit = function()
    return imgui.love.Shutdown()
end

-- for gamepad support also add the following:

love.joystickadded = function(joystick)
    imgui.love.JoystickAdded(joystick)
    -- your code here 
end

love.joystickremoved = function(joystick)
    imgui.love.JoystickRemoved()
    -- your code here 
end

love.gamepadpressed = function(joystick, button)
    imgui.love.GamepadPressed(button)
    -- your code here 
end

love.gamepadreleased = function(joystick, button)
    imgui.love.GamepadReleased(button)
    -- your code here 
end

-- choose threshold for considering analog controllers active, defaults to 0 if unspecified
local threshold = 0.2 

love.gamepadaxis = function(joystick, axis, value)
    imgui.love.GamepadAxis(axis, value, threshold)
    -- your code here 
end