local windows_time = {}

local date = require "date"

local ffi = require "ffi"


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

-- more precision is not useful
--if pcall(function () return ffi.C.GetSystemTimePreciseAsFileTime end) then
--    -- has precise api function
--    function windows_time.get_timestamp_precise()
--        local filetime = ffi.new('FILETIME[1]')
--        ffi.C.GetSystemTimePreciseAsFileTime(filetime)
--        return {filetime.dwLowDateTime, filetime.dwHighDateTime}
--    end
--end
windows_time.epoch = date(1601, 1, 1, 0, 0, 0, 0)
function windows_time.get_datetime()
    local filetime = ffi.new('FILETIME[1]')
    ffi.C.GetSystemTimeAsFileTime(filetime)
--    return math.ceil(filetime.dwHighDateTime / 10000 * (0x100000000) + filetime.dwLowDateTime / 10000 + 0.5)
    local low = tonumber(filetime[0].dwLowDateTime)
    local high = tonumber(filetime[0].dwHighDateTime)
--    print(high * 0x100000000 + low)
    return date(windows_time.epoch):addticks((high * 0x100000000 + low) / 10)
end

return windows_time
