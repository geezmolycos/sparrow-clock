
function love.conf(t)
    if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
        t.console = false
    else
        t.console = true
    end
    t.modules.audio = false
    t.modules.data = false
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.sound = false
    t.modules.thread = false
    t.modules.touch = false
    t.modules.video = false
    t.window = nil -- hide window initially
end
