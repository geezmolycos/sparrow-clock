local windows = {}

local ffi = require "ffi"

local comctl32 = ffi.load('comctl32.dll')
local dwmapi = ffi.load('dwmapi.dll')

ffi.cdef[[

typedef void *HWND;
typedef void *HMONITOR;
typedef void *HRGN;

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
typedef LONG HRESULT;

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

typedef struct _DWM_BLURBEHIND {
  DWORD dwFlags;
  BOOL  fEnable;
  HRGN  hRgnBlur;
  BOOL  fTransitionOnMaximized;
} DWM_BLURBEHIND, *PDWM_BLURBEHIND;

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

HRGN CreateRectRgn(
  int x1,
  int y1,
  int x2,
  int y2
);

HRESULT DwmEnableBlurBehindWindow(
  HWND                 hWnd,
  const DWM_BLURBEHIND *pBlurBehind
);

BOOL SetProcessDPIAware();

]]

-- use DwmEnableBlurBehindWindow which works on modern windows
function windows.set_transparent(hwnd)
    --local result = ffi.C.SetWindowPos(hwnd, ffi.cast('void*', -1), 0, 0, 0, 0, 3)
    --print("r", result)
    local orig_style = ffi.C.GetWindowLongA(hwnd, -16)
    local orig_exstyle = ffi.C.GetWindowLongA(hwnd, -20)
    orig_style = bit.band(orig_style, bit.bnot(0x00cf0000)) -- WS_OVERLAPPEDWINDOW
    orig_style = bit.bor(orig_style, 0x80000000)
    ffi.C.SetWindowLongA(hwnd, -16, orig_style)
    local bb = ffi.new('DWM_BLURBEHIND[1]')
    local hRgn = ffi.C.CreateRectRgn(0, 0, -1, -1)
    bb[0].dwFlags = 3 -- DWM_BB_ENABLE | DWM_BB_BLURREGION
    bb[0].hRgnBlur = hRgn
    bb[0].fEnable = true
    return dwmapi.DwmEnableBlurBehindWindow(hwnd, bb);
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
    return ffi.C.GetActiveWindow()
end

function windows.init(user, hittest)
    if not ffi.C.SetProcessDPIAware() then
        print("set dpi awareness failed")
    end
    windows.hittest = hittest
    windows.window_snap_x = user.config.window_snap_x
    windows.window_snap_y = user.config.window_snap_y
    windows.window_snap_offset_x = user.window_snap_offset_x
    windows.window_snap_offset_y = user.window_snap_offset_y
    love.window.setMode(
        user.window_width, user.window_height,
        { borderless = true, resizable = false, vsync = 0, msaa = 4,
          display = user.config.window_display, x = user.window_x, y = user.window_y,
          highdpi = true, usedpiscale = false }
    )
    local hwnd = windows.get_hwnd()
    print(hwnd)
    if windows.set_transparent(hwnd) ~= 0 then
        print("error setting transparent", ffi.C.GetLastError())
    end
    if windows.register_subclass_window_proc(hwnd) then
        print("error registering subcalss proc")
    end
    windows.set_top(hwnd)
    if windows.hide_taskbar(hwnd) then
        print("error hiding taskbar")
    end
    love.graphics.setBackgroundColor(0, 0, 0, 0)
end


return windows
