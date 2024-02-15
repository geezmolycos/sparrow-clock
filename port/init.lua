
local user = require "user"
local status, ffi = pcall(require, "ffi")
if not status then
    user.log("No FFI module available")
    return require "port.dummy"
end

user.log("FFI reported OS: ", ffi.os)
if ffi.os == "Windows" then
    return require "port.windows"
end

print("OS is not Windows, not implemented")
user.log("OS is not Windows, not implemented")
love.window.showMessageBox( "Warning", "OS is not Windows, not implemented", "warning", false )

return require "port.dummy"
