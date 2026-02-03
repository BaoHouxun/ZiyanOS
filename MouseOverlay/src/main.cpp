#include <windows.h>
#include <stdio.h>
#include <tchar.h>
#include <shellapi.h>

// 全局变量
HINSTANCE hInst;
const TCHAR* WINDOW_CLASS = _T("MouseOverlayClass");
HWND hOverlayWnd;
POINT g_mousePos;
const int CURSOR_WIDTH = 16;
const int CURSOR_HEIGHT = 24;
COLORREF TRANSPARENT_COLOR = RGB(0, 255, 0); // 绿色作为透明色

// 鼠标光标像素数组（16x24）
static const char mouse_cursor[24][17] = {
    "X               ",
    "XX              ",
    "X.X             ",
    "X..X            ",
    "X...X           ",
    "X....X          ",
    "X.....X         ",
    "X......X        ",
    "X.......X       ",
    "X........X      ",
    "X.........X     ",
    "X..........X    ",
    "X...........X   ",
    "X............X  ",
    "X.......XXXXXX  ",
    "X..X....X       ",
    "X.X X....X      ",
    "XX  X....X      ",
    "X    X....X     ",
    "     X....X     ",
    "      X....X    ",
    "      X..XX     ",
    "       XX       ",
    "                "
};

// 函数声明
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam);
void DrawCustomCursor(HDC hdc, int x, int y);

// 注册窗口类
ATOM RegisterWindowClass(HINSTANCE hInstance)
{
    WNDCLASSEX wcex;
    wcex.cbSize = sizeof(WNDCLASSEX);
    wcex.style = CS_HREDRAW | CS_VREDRAW;
    wcex.lpfnWndProc = WndProc;
    wcex.cbClsExtra = 0;
    wcex.cbWndExtra = 0;
    wcex.hInstance = hInstance;
    wcex.hIcon = NULL;  // 无图标
    wcex.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wcex.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wcex.lpszMenuName = nullptr;
    wcex.lpszClassName = WINDOW_CLASS;
    wcex.hIconSm = NULL;  // 无小图标
    return RegisterClassEx(&wcex);
}

// 创建覆盖窗口
HWND CreateOverlayWindow(HINSTANCE hInstance)
{
    // 获取屏幕尺寸
    int screenWidth = GetSystemMetrics(SM_CXSCREEN);
    int screenHeight = GetSystemMetrics(SM_CYSCREEN);

    HWND hWnd = CreateWindowEx(
        WS_EX_TOPMOST | WS_EX_TRANSPARENT | WS_EX_LAYERED | WS_EX_TOOLWINDOW,
        WINDOW_CLASS,
        _T("Mouse Overlay"),
        WS_POPUP,
        0, 0, screenWidth, screenHeight,
        nullptr, nullptr, hInstance, nullptr);

    if (hWnd)
    {
        // 设置窗口为透明
        SetLayeredWindowAttributes(hWnd, TRANSPARENT_COLOR, 0, LWA_COLORKEY);

        // 确保窗口在最顶层
        SetWindowPos(hWnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);

        ShowWindow(hWnd, SW_SHOW);
        UpdateWindow(hWnd);
    }

    return hWnd;
}

// 绘制像素艺术风格的鼠标指针
void DrawCustomCursor(HDC hdc, int x, int y)
{
    // 创建画笔
    HPEN blackPen = CreatePen(PS_SOLID, 1, RGB(0, 0, 0));
    HPEN whitePen = CreatePen(PS_SOLID, 1, RGB(255, 255, 255));

    // 保存原始画笔
    HPEN oldPen = (HPEN)SelectObject(hdc, blackPen);

    // 设置绘图模式
    SetBkMode(hdc, TRANSPARENT);

    // 绘制每个像素
    for (int row = 0; row < CURSOR_HEIGHT; row++)
    {
        for (int col = 0; col < CURSOR_WIDTH; col++)
        {
            char pixel = mouse_cursor[row][col];

            if (pixel == 'X')
            {
                // 绘制黑色边框像素
                SelectObject(hdc, blackPen);
                SetPixel(hdc, x + col, y + row, RGB(0, 0, 0));
            }
            else if (pixel == '.')
            {
                // 绘制白色填充像素
                SelectObject(hdc, whitePen);
                SetPixel(hdc, x + col, y + row, RGB(255, 255, 255));
            }
        }
    }

    // 恢复原始画笔
    SelectObject(hdc, oldPen);

    // 清理资源
    DeleteObject(blackPen);
    DeleteObject(whitePen);
}

// 窗口过程函数
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static UINT_PTR timerId = 0;

    switch (message)
    {
    case WM_CREATE:
    {
        // 设置定时器来轮询鼠标位置（每16ms，约60fps）
        timerId = SetTimer(hWnd, 1, 16, NULL);

        // 初始获取鼠标位置
        GetCursorPos(&g_mousePos);
        break;
    }

    case WM_TIMER:
    {
        // 定时器触发，更新鼠标位置
        POINT currentPos;
        GetCursorPos(&currentPos);

        // 只有当位置变化时才重绘
        if (currentPos.x != g_mousePos.x || currentPos.y != g_mousePos.y)
        {
            g_mousePos = currentPos;

            // 强制重绘窗口
            InvalidateRect(hWnd, NULL, TRUE);
            UpdateWindow(hWnd);
        }
        break;
    }

    case WM_PAINT:
    {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hWnd, &ps);

        // 获取窗口尺寸
        RECT clientRect;
        GetClientRect(hWnd, &clientRect);

        // 创建内存DC进行双缓冲
        HDC hdcMem = CreateCompatibleDC(hdc);
        HBITMAP hbmMem = CreateCompatibleBitmap(hdc, clientRect.right, clientRect.bottom);
        HBITMAP hbmOld = (HBITMAP)SelectObject(hdcMem, hbmMem);

        // 用透明色填充背景
        HBRUSH greenBrush = CreateSolidBrush(TRANSPARENT_COLOR);
        FillRect(hdcMem, &clientRect, greenBrush);
        DeleteObject(greenBrush);

        // 绘制鼠标指针
        DrawCustomCursor(hdcMem, g_mousePos.x, g_mousePos.y);

        // 将内存DC内容一次性绘制到屏幕
        BitBlt(hdc, 0, 0, clientRect.right, clientRect.bottom, hdcMem, 0, 0, SRCCOPY);

        // 清理资源
        SelectObject(hdcMem, hbmOld);
        DeleteObject(hbmMem);
        DeleteDC(hdcMem);

        EndPaint(hWnd, &ps);
        break;
    }

    case WM_ERASEBKGND:
        // 阻止擦除背景，减少闪烁
        return 1;

    case WM_DESTROY:
    {
        // 销毁定时器
        if (timerId)
        {
            KillTimer(hWnd, timerId);
            timerId = 0;
        }

        PostQuitMessage(0);
        break;
    }

    default:
        return DefWindowProc(hWnd, message, wParam, lParam);
    }
    return 0;
}

// 主函数
int APIENTRY WinMain(HINSTANCE hInstance,
                     HINSTANCE hPrevInstance,
                     LPSTR     lpCmdLine,
                     int       nCmdShow)
{
    UNREFERENCED_PARAMETER(hPrevInstance);
    UNREFERENCED_PARAMETER(lpCmdLine);

    hInst = hInstance;

    // 注册窗口类
    if (!RegisterWindowClass(hInstance))
        return 1;

    // 创建覆盖窗口
    hOverlayWnd = CreateOverlayWindow(hInstance);
    if (!hOverlayWnd)
        return 1;

    // 主消息循环
    MSG msg;
    while (GetMessage(&msg, nullptr, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return (int)msg.wParam;
}
