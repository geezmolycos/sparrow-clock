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

typedef struct tagMONITORINFO {
  DWORD cbSize;
  RECT  rcMonitor;
  RECT  rcWork;
  DWORD dwFlags;
} MONITORINFO, *LPMONITORINFO;

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

BOOL GetMonitorInfoA(
  HMONITOR      hMonitor,
  LPMONITORINFO lpmi
);

]]

-- use DwmEnableBlurBehindWindow which works on modern windows
function windows.set_transparent(hwnd)
    local orig_style = ffi.C.GetWindowLongA(hwnd, -16)
    local orig_exstyle = ffi.C.GetWindowLongA(hwnd, -20)
    orig_style = bit.band(orig_style, bit.bnot(0x00cf0000)) -- WS_OVERLAPPEDWINDOW
    orig_style = bit.bor(orig_style, 0x80000000)
    ffi.C.SetWindowLongA(hwnd, -16, orig_style)
    local bb = ffi.new('DWM_BLURBEHIND[1]')
    local hRgn = ffi.C.CreateRectRgn(0, 0, -1, -1) -- create an invisible region
    bb[0].dwFlags = 3 -- DWM_BB_ENABLE | DWM_BB_BLURREGION
    bb[0].hRgnBlur = hRgn
    bb[0].fEnable = true
    local result = dwmapi.DwmEnableBlurBehindWindow(hwnd, bb);
    if result == 0 then return true else return false, result end
end

function windows.prevent_out_of_bound(hwnd)
    local rect = ffi.new('RECT[1]')
    local result = ffi.C.GetWindowRect(hwnd, rect)
    if result == 0 then
        return false, ffi.C.GetLastError()
    end
    local x = rect[0].left
    local y = rect[0].top
    local cx = rect[0].right - rect[0].left
    local cy = rect[0].bottom - rect[0].top
    if not (ffi.C.MonitorFromPoint({x = x, y = y}, 0) == nil
    or ffi.C.MonitorFromPoint({x = x + cx - 1, y = y}, 0) == nil
    or ffi.C.MonitorFromPoint({x = x, y = y + cy - 1}, 0) == nil
    or ffi.C.MonitorFromPoint({x = x + cx - 1, y = y + cy - 1}, 0) == nil) then
        return -- is in bound
    end
    -- get nearest monitor
    local hmonitor = ffi.C.MonitorFromPoint({x = x + cx / 2, y = y + cy / 2}, 2) -- MONITOR_DEFAULTTONEAREST
    local monitorinfo = ffi.new("MONITORINFO[1]")
    monitorinfo[0].cbSize = ffi.sizeof("MONITORINFO")
    local result = ffi.C.GetMonitorInfoA(hmonitor, monitorinfo)
    if result == 0 then
        return false, ffi.C.GetLastError()
    end
    local target_rect = monitorinfo[0].rcWork
    if x < target_rect.left then
        x = target_rect.left
    end
    if x + cx > target_rect.right then
        x = target_rect.right - cx
    end
    if y < target_rect.top then
        y = target_rect.top
    end
    if y + cy > target_rect.bottom then
        y = target_rect.bottom - cy
    end
    ffi.C.SetWindowPos(hwnd, nil, x, y, cx, cy,0x0214) -- SWP_NOOWNERZORDER | SWP_NOACTIVATE | SWP_NOZORDER
end

function windows.subclass_window_proc(hWnd, uMsg, wParam, lParam, uIdSubclass, dwRefData)
    if uMsg == 0x0082 then -- WM_NCDESTROY
        comctl32.RemoveWindowSubclass(hWnd, windows.subclass_window_proc_cb, uIdSubclass)
    elseif uMsg == 0x0046 then -- WM_WINDOWPOSCHANGING
        local windowpos = ffi.cast("WINDOWPOS*", lParam)
        if windows.at_bottom then
            -- https://stackoverflow.com/questions/2027536/setting-a-windows-form-to-be-bottommost
            windowpos.flags = bit.bor(windowpos.flags, 0x0004) -- SWP_NOZORDER
        end
        -- snap
        local x = windowpos.x
        x = x - (x - windows.snap_offset_x) % windows.snap_x
        local y = windowpos.y
        y = y - (y - windows.snap_offset_y) % windows.snap_y
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
    elseif uMsg == 0x007e then -- WM_DISPLAYCHANGE
        windows.prevent_out_of_bound(hWnd)
    end
    return comctl32.DefSubclassProc(hWnd, uMsg, wParam, lParam)
end

windows.subclass_window_proc_cb = ffi.cast("SUBCLASSPROC", windows.subclass_window_proc)

function windows.register_subclass_window_proc(hwnd)
    windows.set_bottom(hwnd)
    -- https://stackoverflow.com/questions/63143237/change-wndproc-of-the-window
    local result = comctl32.SetWindowSubclass(hwnd, windows.subclass_window_proc_cb, 1, 0)
    if result == 1 then return true else return false end
end

function windows.set_bottom(hwnd)
    -- set to HWND_BOTTOM
    local result = ffi.C.SetWindowPos(hwnd, ffi.cast("HWND", 1), 0, 0, 0, 0, 0x0013) -- SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE
    if result ~= 0 then
        windows.at_bottom = true
        return true
    else
        return false, ffi.C.GetLastError()
    end
end

function windows.set_top(hwnd)
    windows.at_bottom = false
    -- set to HWND_TOPMOST
    local result = ffi.C.SetWindowPos(hwnd, ffi.cast("HWND", -1), 0, 0, 0, 0, 0x0013) -- SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE
    if result ~= 0 then
        return true
    else
        return false, ffi.C.GetLastError()
    end
end

function windows.hide_taskbar(hwnd)
    local orig_ex = ffi.C.GetWindowLongA(hwnd, -20)
    local result = ffi.C.SetWindowLongA(hwnd, -20, bit.bor(orig_ex, 0x00000080)) -- WS_EX_TOOLWINDOW
    if result ~= 0 then
        return true
    else
        return false, ffi.C.GetLastError()
    end
end

function windows.get_hwnd()
    return ffi.C.GetActiveWindow()
end

function windows.init(user, hittest)
    windows.hittest = hittest
    windows.snap_x = user.config.windows_snap_x
    windows.snap_y = user.config.windows_snap_y
    windows.snap_offset_x = user.windows_snap_offset_x
    windows.snap_offset_y = user.windows_snap_offset_y
    love.window.setMode(
        user.window_width, user.window_height,
        { borderless = user.config.window_borderless, resizable = false, vsync = 0, msaa = 4,
          display = user.config.window_display, x = user.window_x, y = user.window_y,
          highdpi = true, usedpiscale = false }
    )
    local hwnd = windows.get_hwnd()
    user.log("hWnd:", hwnd)
    if user.config.windows_transparent then
        local status, err = windows.set_transparent(hwnd)
        if not status then
            user.log("error setting transparent", err)
        end
    end
    local status, err = windows.register_subclass_window_proc(hwnd)
    if not status then
        user.log("error registering subclass proc", err)
    end
    if user.config.windows_bottom then
        windows.set_bottom(hwnd)
    else
        windows.set_top(hwnd)
    end
    if user.config.windows_hide_taskbar then
        local status, err = windows.hide_taskbar(hwnd)
        if not status then
          user.log("error hiding taskbar", err)
        end
    end
    love.graphics.setBackgroundColor(0, 0, 0, 0)
end

-- datetime part

local date = require "date"

ffi.cdef[[
typedef unsigned short WORD;
typedef unsigned long DWORD;

typedef struct _FILETIME {
  DWORD dwLowDateTime;
  DWORD dwHighDateTime;
} FILETIME, *PFILETIME, *LPFILETIME;

typedef struct _SYSTEMTIME {
  WORD wYear;
  WORD wMonth;
  WORD wDayOfWeek;
  WORD wDay;
  WORD wHour;
  WORD wMinute;
  WORD wSecond;
  WORD wMilliseconds;
} SYSTEMTIME, *PSYSTEMTIME, *LPSYSTEMTIME;

void GetSystemTimeAsFileTime(
  LPFILETIME lpSystemTimeAsFileTime
);

void GetSystemTimePreciseAsFileTime(
  LPFILETIME lpSystemTimeAsFileTime
);

void GetSystemTime(
  LPSYSTEMTIME lpSystemTime
);

void GetLocalTime(
  LPSYSTEMTIME lpSystemTime
);
]]

windows.epoch = date(1601, 1, 1, 0, 0, 0, 0)
function windows.get_datetime()
    local filetime = ffi.new('FILETIME[1]')
    ffi.C.GetSystemTimeAsFileTime(filetime)
    local low = tonumber(filetime[0].dwLowDateTime)
    local high = tonumber(filetime[0].dwHighDateTime)
    return date(windows.epoch):addticks((high * 0x100000000 + low) / 10)
end

return windows
