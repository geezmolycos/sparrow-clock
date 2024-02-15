
local ffi = require "ffi"
local user = require "user"

user.log("FFI reported OS: ", ffi.os)
if ffi.os == "Windows" then
    return require "port.windows"
end

print("OS is not Windows, not implemented")
user.log("OS is not Windows, not implemented")
love.window.showMessageBox( "Warning", "OS is not Windows, not implemented", "warning", false )

return require "port.dummy"
