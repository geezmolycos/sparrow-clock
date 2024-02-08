
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
local mgl = require "MGL"

local windows = require "windows"
local user = require "user"

local items = user.config.items

local last_mouse_moved = -1000
local last_mouse_pressed = -1000

love.load = function()
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
    
    love.graphics.setDefaultFilter('nearest', 'nearest', 0)
    local font = love.graphics.newFont(user.config.grid_size, "mono")
    font:setFilter("nearest")
    love.graphics.setFont(font)
    
    for name, it in ipairs(items) do
        it.module.init(it, name, user)
    end
end

love.draw = function()
    -- code to render imgui
    imgui.Render()
    imgui.love.RenderDrawLists()
    -- love.graphics.setColor(1, 0, 0)
    -- love.graphics.circle('fill', 0, 0, 100)
    
    local timer = love.timer.getTime()
    
    local state = {
        time = os.time(),
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

love.keypressed = function(key, ...)
    imgui.love.KeyPressed(key)
    if not imgui.love.GetWantCaptureKeyboard() then
        -- your code here 
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