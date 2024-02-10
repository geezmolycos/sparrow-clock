local windows = {}

local ffi = require "ffi"

local comctl32 = ffi.load('comctl32.dll')
local win = ffi.load('win.dll')

ffi.cdef[[

typedef void *HWND;
typedef void *HMONITOR;
typedef void *HDC;

typedef int BOOL;
typedef unsigned long COLORREF;
typedef unsigned char BYTE;
typedef unsigned long DWORD;
typedef unsigned int UINT;
typedef long LONG;

typedef intptr_t LONG_PTR;
typedef LONG_PTR LRESULT;
typedef uintptr_t UINT_PTR;
typedef uintptr_t ULONG_PTR;
typedef ULONG_PTR DWORD_PTR;
typedef UINT_PTR WPARAM;
typedef LONG_PTR LPARAM;

typedef LRESULT (*SUBCLASSPROC)(
  HWND hWnd,
  UINT uMsg,
  WPARAM wParam,
  LPARAM lParam,
  UINT_PTR uIdSubclass,
  DWORD_PTR dwRefData
);

typedef struct tagWINDOWPOS {
  HWND hwnd;
  HWND hwndInsertAfter;
  int  x;
  int  y;
  int  cx;
  int  cy;
  UINT flags;
} WINDOWPOS, *LPWINDOWPOS, *PWINDOWPOS;

typedef struct tagPOINT {
  LONG x;
  LONG y;
} POINT, *PPOINT, *NPPOINT, *LPPOINT;

typedef struct tagRECT {
  LONG left;
  LONG top;
  LONG right;
  LONG bottom;
} RECT, *PRECT, *NPRECT, *LPRECT;

typedef struct _BLENDFUNCTION {
  BYTE BlendOp;
  BYTE BlendFlags;
  BYTE SourceConstantAlpha;
  BYTE AlphaFormat;
} BLENDFUNCTION, *PBLENDFUNCTION;

typedef struct tagSIZE {
  LONG cx;
  LONG cy;
} SIZE, *PSIZE, *LPSIZE;

HWND GetActiveWindow(

);

BOOL GetWindowRect(
  HWND   hWnd,
  LPRECT lpRect
);

BOOL SetLayeredWindowAttributes(
  HWND     hwnd,
  COLORREF crKey,
  BYTE     bAlpha,
  DWORD    dwFlags
);

DWORD __stdcall GetLastError(void);

BOOL SetWindowPos(
  HWND hWnd,
  HWND hWndInsertAfter,
  int  X,
  int  Y,
  int  cx,
  int  cy,
  UINT uFlags
);

LONG SetWindowLongA(
  HWND     hWnd,
  int      nIndex,
  LONG dwNewLong
);

LONG GetWindowLongA(
  HWND hWnd,
  int  nIndex
);

BOOL SetWindowSubclass(
  HWND         hWnd,
  SUBCLASSPROC pfnSubclass,
  UINT_PTR     uIdSubclass,
  DWORD_PTR    dwRefData
);

LRESULT DefSubclassProc(
  HWND   hWnd,
  UINT   uMsg,
  WPARAM wParam,
  LPARAM lParam
);

BOOL RemoveWindowSubclass(
  HWND         hWnd,
  SUBCLASSPROC pfnSubclass,
  UINT_PTR     uIdSubclass
);

HMONITOR MonitorFromPoint(
  POINT pt,
  DWORD dwFlags
);

BOOL UpdateLayeredWindow(
  HWND          hWnd,
  HDC           hdcDst,
  POINT         *pptDst,
  SIZE          *psize,
  HDC           hdcSrc,
  POINT         *pptSrc,
  COLORREF      crKey,
  BLENDFUNCTION *pblend,
  DWORD         dwFlags
);

HDC GetDC(
  HWND hWnd
);

void paintdc(HDC dc);

]]

-- possible(harder) alternative methods for creating layered window:
-- https://stackoverflow.com/questions/48448739/window-regions-vs-layered-windows

-- simple color masking is used here
function windows.set_layered(hwnd)
    --local result = ffi.C.SetWindowPos(hwnd, ffi.cast('void*', -1), 0, 0, 0, 0, 3)
    --print("r", result)
    local orig_ex = ffi.C.GetWindowLongA(hwnd, -20)
    print("orig ex:", orig_ex)
    local result = ffi.C.SetWindowLongA(hwnd, -20, bit.bor(orig_ex, 0x00080000)) -- WS_EX_LAYERED
    local colorref = ffi.cast('COLORREF', 0x00ff00ff)
    local alpha = ffi.cast('BYTE', 0)
    local flags = ffi.cast('DWORD', 0x00000001)
    print(hwnd)
    local result = ffi.C.SetLayeredWindowAttributes(
        hwnd,
        colorref,
        alpha,
        flags) -- flags (2: alpha->opacity, 1: colorkey -> transparency color)
    if result == 0 then
        return ffi.C.GetLastError()
    end
    return nil
end

function windows.subclass_window_proc(hWnd, uMsg, wParam, lParam, uIdSubclass, dwRefData)
    if uMsg == 0x0082 then -- WM_NCDESTROY
        comctl32.RemoveWindowSubclass(hWnd, window.subclass_window_proc_cb, uIdSubclass)
    elseif uMsg == 0x0046 then -- WM_WINDOWPOSCHANGING
        local windowpos = ffi.cast("WINDOWPOS*", lParam)
        if windows.at_bottom then
            -- https://stackoverflow.com/questions/2027536/setting-a-windows-form-to-be-bottommost
            windowpos.flags = bit.bor(windowpos.flags, 0x0004) -- SWP_NOZORDER
        end
        -- snap
        local x = windowpos.x
        x = x - (x - windows.window_snap_offset_x) % windows.window_snap_x
        local y = windowpos.y
        y = y - (y - windows.window_snap_offset_y) % windows.window_snap_y
        windowpos.x = x
        windowpos.y = y
        local cx = windowpos.cx
        local cy = windowpos.cy
        -- prevent out of bound
        if ffi.C.MonitorFromPoint({x = x, y = y}, 0) == nil
        or ffi.C.MonitorFromPoint({x = x + cx - 1, y = y}, 0) == nil
        or ffi.C.MonitorFromPoint({x = x, y = y + cy - 1}, 0) == nil
        or ffi.C.MonitorFromPoint({x = x + cx - 1, y = y + cy - 1}, 0) == nil then
            windowpos.flags = bit.bor(windowpos.flags, 0x0002) -- SWP_NOMOVE
        end
    elseif uMsg == 0x0084 then -- WM_NCHITTEST
        local result = comctl32.DefSubclassProc(hWnd, uMsg, wParam, lParam);
        if result == 1 then -- HTCLIENT
            local x = tonumber(bit.band(lParam, 0xffff))
            if x > 0x8000 then x = x - 0x10000 end
            local y = tonumber(bit.band(bit.rshift(lParam, 16), 0xffff))
            if y > 0x8000 then y = y - 0x10000 end
            local rect = ffi.new('RECT[1]')
            local result = ffi.C.GetWindowRect(hWnd, rect)
            if result == 0 then
                print("error getting window rect")
                return 1
            end
            x = x - rect[0].left
            y = y - rect[0].top
            local hit = windows.hittest(x, y)
            local code = ({
                client = 1,
                caption = 2,
                close = 20
            })[hit] or 1
            return code
        end
        return result
    end
    return comctl32.DefSubclassProc(hWnd, uMsg, wParam, lParam)
end

windows.subclass_window_proc_cb = ffi.cast("SUBCLASSPROC", windows.subclass_window_proc)

function windows.register_subclass_window_proc(hwnd)
    windows.set_bottom(hwnd)
    -- https://stackoverflow.com/questions/63143237/change-wndproc-of-the-window
    local result = comctl32.SetWindowSubclass(hwnd, windows.subclass_window_proc_cb, 1, 0)
    if result == 0 then
        return result
    end
end

function windows.set_bottom(hwnd)
    -- set to HWND_BOTTOM
    local result = ffi.C.SetWindowPos(hwnd, ffi.cast("HWND", 1), 0, 0, 0, 0, 0x0013) -- SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE
    if result == 0 then
        return ffi.C.GetLastError()
    end
    windows.at_bottom = true
end

function windows.set_top(hwnd)
    windows.at_bottom = false
    -- set to HWND_TOPMOST
    local result = ffi.C.SetWindowPos(hwnd, ffi.cast("HWND", -1), 0, 0, 0, 0, 0x0013) -- SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE
    if result == 0 then
        return ffi.C.GetLastError()
    end
end

function windows.hide_taskbar(hwnd)
    local orig_ex = ffi.C.GetWindowLongA(hwnd, -20)
    local result = ffi.C.SetWindowLongA(hwnd, -20, bit.bor(orig_ex, 0x00000080)) -- WS_EX_TOOLWINDOW
    if result == 0 then
        return ffi.C.GetLastError()
    end
end

function windows.get_hwnd()
    return windows.hwnd
end

function windows.init(user, hittest)
    windows.hittest = hittest
    windows.window_snap_x = user.config.window_snap_x
    windows.window_snap_y = user.config.window_snap_y
    windows.window_snap_offset_x = user.window_snap_offset_x
    windows.window_snap_offset_y = user.window_snap_offset_y
    love.window.setMode(
        user.window_width, user.window_height,
        { borderless = true, resizable = false, vsync = 0,
          display = user.config.window_display, x = user.window_x, y = user.window_y,
          highdpi = true, usedpiscale = false }
    )
    windows.hwnd = ffi.C.GetActiveWindow()
    local hwnd = windows.get_hwnd()
    print(hwnd)
    if windows.set_layered(hwnd) then
        print("error setting layered window")
    end
    if windows.register_subclass_window_proc(hwnd) then
        print("error registering subcalss proc")
    end
    windows.set_top(hwnd)
    if windows.hide_taskbar(hwnd) then
        print("error hiding taskbar")
    end
    love.graphics.setBackgroundColor(1, 0, 1, 0)
end

function windows.test_dc()
    local hwnd = windows.get_hwnd()
    local hdc_screen = ffi.C.GetDC(nil)
    local hdc_window = ffi.C.GetDC(hwnd)
    -- local ptpos = ffi.new('POINT[1]')
    -- ptpos[0] = {0, 0}
    -- local size = ffi.new('SIZE[1]')
    -- size[0] = {24*16, 8*16}
    -- local ptsrc = ffi.new('POINT[1]')
    -- ptsrc[0] = {0, 0}
    -- local blend = ffi.new('BLENDFUNCTION[1]')
    -- blend[0] = {0}
    -- print(hwnd, hdc_screen, ptpos, size, hdc_window, ptsrc, 0, blend, 2)
    -- print('ulw:', ffi.C.UpdateLayeredWindow(hwnd, hdc_screen, ptpos, size, hdc_window, ptsrc, 0, blend, 2))
    -- print(ffi.C.GetLastError())
    win.paintdc(hdc_window)
    print('fa')
end

return windows
