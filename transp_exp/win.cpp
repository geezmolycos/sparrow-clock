
// Source: https://stackoverflow.com/questions/3970066/creating-a-transparent-window-in-c-win32
//https://stackoverflow.com/questions/15815404/create-transparent-image-from-png-winapi

#define WIN32_LEAN_AND_MEAN
#define WINVER 0x0600       // needed for alphablend function..

#include <windows.h>
#include <objidl.h>
#include <gdiplus.h>
#include <stdio.h>

const char g_szClassName[] = "myWindowClass";


// BMP, GIF, JPEG, PNG, TIFF, Exif, WMF, and EMF
// requires GDIPlus
HBITMAP mLoadImg(WCHAR *szFilename)
{
   HBITMAP result=NULL;

   Gdiplus::Bitmap* bitmap = new Gdiplus::Bitmap(szFilename,false);
   bitmap->GetHBITMAP(NULL, &result);
   delete bitmap;
   return result;
}

extern "C"
__declspec(dllexport) void paintdc(HDC hdcMem){
    Gdiplus::Graphics graphics(hdcMem);
   Gdiplus::Pen      pen(Gdiplus::Color(128, 0, 0, 255));
   graphics.DrawLine(&pen, 0, 0, 200, 100);
}

void SetSplashImage(HWND hwndSplash, HBITMAP hbmpSplash)
{
  printf("hello\n");
  // get the size of the bitmap
  BITMAP bm;
  GetObject(hbmpSplash, sizeof(bm), &bm);
  SIZE sizeSplash = { bm.bmWidth, bm.bmHeight };

  // get the primary monitor's info
  POINT ptZero = { 0 };
  HMONITOR hmonPrimary = MonitorFromPoint(ptZero, MONITOR_DEFAULTTOPRIMARY);
  MONITORINFO monitorinfo = { 0 };
  monitorinfo.cbSize = sizeof(monitorinfo);
  GetMonitorInfo(hmonPrimary, &monitorinfo);

  // center the splash screen in the middle of the primary work area
  const RECT & rcWork = monitorinfo.rcWork;
  POINT ptOrigin;
  ptOrigin.x = 0;
  ptOrigin.y = rcWork.top + (rcWork.bottom - rcWork.top - sizeSplash.cy) / 2;

  // create a memory DC holding the splash bitmap
  HDC hdcScreen = GetDC(NULL);
  HDC hdcMem = CreateCompatibleDC(hdcScreen);
    HBITMAP hbmpOld = (HBITMAP) SelectObject(hdcMem, hbmpSplash);

  // use the source image's alpha channel for blending
  BLENDFUNCTION blend = { 0 };
  blend.BlendOp = AC_SRC_OVER;
  blend.SourceConstantAlpha = 255;
  blend.AlphaFormat = AC_SRC_ALPHA;
Gdiplus::Graphics graphics(hdcMem);
   Gdiplus::Pen      pen(Gdiplus::Color(128, 0, 0, 255));
   graphics.DrawLine(&pen, 0, 0, 200, 100);
  // paint the window (in the right location) with the alpha-blended bitmap
    printf("ll: %d\n", UpdateLayeredWindow(hwndSplash, hdcScreen, &ptOrigin, &sizeSplash,
        hdcMem, &ptZero, RGB(0, 0, 0), &blend, ULW_ALPHA));
     printf("LE: %d\n", GetLastError());
    // printf("hdcmem: %p, newdc: %p", hdcMem, GetDC(hwndSplash));

  // delete temporary objects
    SelectObject(hdcMem, hbmpOld);
  DeleteDC(hdcMem);
  ReleaseDC(NULL, hdcScreen);
}


// Step 4: the Window Procedure
LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    static HBITMAP myImage;
    switch(msg)
    {
        case WM_CLOSE:
            DestroyWindow(hwnd);
        break;

        case WM_ERASEBKGND:
            SetSplashImage(hwnd, NULL);
        break;

        case WM_CREATE:
            printf("load\n");
            myImage = mLoadImg(L"bg_shadow_png.png");
            SetLayeredWindowAttributes(hwnd, RGB(255, 0, 0), 127, LWA_COLORKEY);
            SetSplashImage(hwnd, myImage);
        break;

        case WM_PAINT:
            //displayImage(HBITMAP mBmp, HWND mHwnd);
            break;

        case WM_DESTROY:
            PostQuitMessage(0);
        break;
        default:
            return DefWindowProc(hwnd, msg, wParam, lParam);
    }
    return 0;
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
    LPSTR lpCmdLine, int nCmdShow)
{
    WNDCLASSEX wc;
    HWND hwnd;
    MSG Msg;

    static Gdiplus::GdiplusStartupInput gdiplusStartupInput;
    static ULONG_PTR gdiplusToken;
    // so we can load all the image formats that windows supports natively - (I'm using a transparent PNG on the main dialog)
    GdiplusStartup(&gdiplusToken, &gdiplusStartupInput, NULL);


    //Step 1: Registering the Window Class
    wc.cbSize        = sizeof(WNDCLASSEX);
    wc.style         = 0;
    wc.lpfnWndProc   = WndProc;
    wc.cbClsExtra    = 0;
    wc.cbWndExtra    = 0;
    wc.hInstance     = hInstance;
    wc.hIcon         = LoadIcon(NULL, IDI_APPLICATION);
    wc.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW+1);
    wc.lpszMenuName  = NULL;
    wc.lpszClassName = g_szClassName;
    wc.hIconSm       = LoadIcon(NULL, IDI_APPLICATION);

    if(!RegisterClassEx(&wc))
    {
        MessageBox(NULL, "Window Registration Failed!", "Error!",
            MB_ICONEXCLAMATION | MB_OK);
        return 0;
    }

    // Step 2: Creating the Window
    hwnd = CreateWindowEx(
        WS_EX_CLIENTEDGE | WS_EX_LAYERED,
        g_szClassName,
        "The title of my window",
        WS_POPUP | WS_VISIBLE,
        CW_USEDEFAULT, CW_USEDEFAULT, 800, 600,
        NULL, NULL, hInstance, NULL);

    if(hwnd == NULL)
    {
        MessageBox(NULL, "Window Creation Failed!", "Error!",
            MB_ICONEXCLAMATION | MB_OK);
        return 0;
    }

    ShowWindow(hwnd, nCmdShow);
    UpdateWindow(hwnd);

    // Step 3: The Message Loop
    while(GetMessage(&Msg, NULL, 0, 0) > 0)
    {
        TranslateMessage(&Msg);
        DispatchMessage(&Msg);
    }

    Gdiplus::GdiplusShutdown(gdiplusToken);
    return Msg.wParam;
}