#include <windows.h>
#include <tlhelp32.h>
#include <psapi.h>
#include <iostream>
#include <string>
#include <chrono>
#include <thread>
#include <atomic>

// 主程序名称
const wchar_t* MAIN_APP_NAME = L"ZiyanOS.exe";
const wchar_t* RESTART_ARG = L"--restart-after-crash";

// 全局变量 - 使用构造函数初始化
std::atomic<bool> g_shouldExit(false);
std::atomic<bool> g_normalExit(false);
HANDLE g_mutex = nullptr;

// 检查进程是否存在
bool IsProcessRunning(const wchar_t* processName) {
    HANDLE hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hSnapshot == INVALID_HANDLE_VALUE) {
        std::wcerr << L"无法创建进程快照" << std::endl;
        return false;
    }

    PROCESSENTRY32W pe32;
    pe32.dwSize = sizeof(PROCESSENTRY32W);

    if (!Process32FirstW(hSnapshot, &pe32)) {
        CloseHandle(hSnapshot);
        return false;
    }

    do {
        if (_wcsicmp(pe32.szExeFile, processName) == 0) {
            CloseHandle(hSnapshot);
            return true;
        }
    } while (Process32NextW(hSnapshot, &pe32));

    CloseHandle(hSnapshot);
    return false;
}

// 获取主程序路径
std::wstring GetMainAppPath() {
    wchar_t exePath[MAX_PATH];
    GetModuleFileNameW(NULL, exePath, MAX_PATH);

    // 获取启动器所在目录
    std::wstring launcherPath(exePath);
    size_t pos = launcherPath.find_last_of(L"\\/");

    if (pos != std::wstring::npos) {
        // 构建主程序路径（假设与启动器在同一目录）
        return launcherPath.substr(0, pos + 1) + MAIN_APP_NAME;
    }

    // 如果无法获取路径，返回当前目录下的主程序
    return MAIN_APP_NAME;
}

// 启动主程序
DWORD StartMainApp(bool restartAfterCrash = false) {
    std::wstring appPath = GetMainAppPath();

    // 检查主程序是否存在
    if (GetFileAttributesW(appPath.c_str()) == INVALID_FILE_ATTRIBUTES) {
        std::wcerr << L"主程序不存在: " << appPath << std::endl;
        return 0;
    }

    // 构建命令行参数
    std::wstring commandLine = L"\"" + appPath + L"\"";
    if (restartAfterCrash) {
        commandLine += L" ";
        commandLine += RESTART_ARG;
    }

    // 设置启动信息
    STARTUPINFOW si = { sizeof(si) };
    PROCESS_INFORMATION pi = { 0 };

    si.dwFlags = STARTF_USESHOWWINDOW;
    si.wShowWindow = SW_SHOW;  // 正常显示窗口

    // 创建进程
    if (CreateProcessW(
            NULL,                           // 应用程序名（使用命令行）
            const_cast<wchar_t*>(commandLine.c_str()),  // 命令行
            NULL,                           // 进程安全属性
            NULL,                           // 线程安全属性
            FALSE,                          // 不继承句柄
            CREATE_NEW_PROCESS_GROUP,       // 创建标志
            NULL,                           // 环境变量
            NULL,                           // 当前目录
            &si,                            // 启动信息
            &pi                             // 进程信息
            )) {
        std::wcout << L"成功启动主程序: " << commandLine << std::endl;

        // 等待进程退出
        WaitForSingleObject(pi.hProcess, INFINITE);

        // 获取退出码
        DWORD exitCode = 0;
        GetExitCodeProcess(pi.hProcess, &exitCode);

        std::wcout << L"主程序退出，返回码: " << exitCode << std::endl;

        // 关闭句柄
        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);

        return exitCode;
    } else {
        DWORD error = GetLastError();
        std::wcerr << L"无法启动主程序，错误码: " << error << std::endl;
        return 0xFFFFFFFF;  // 返回一个特殊值表示启动失败
    }
}

// 检测是否是正常关机
bool IsNormalShutdown(DWORD exitCode) {
    // 正常退出返回0，异常退出返回非0
    // 您可以在主程序中设置特定的退出码来表示不同的退出类型
    switch (exitCode) {
    case 0:  // 正常退出
        return true;
    case 1:  // 一般错误
    case 2:  // 致命错误
    case 3:  // 应用程序崩溃
        return false;
    default:
        // 其他退出码视为异常
        return (exitCode == 0);
    }
}

// 检查是否需要启动（防止重复启动）
bool ShouldStartLauncher() {
    // 创建一个命名互斥体，确保只有一个启动器实例运行
    g_mutex = CreateMutexW(NULL, FALSE, L"ZiyanOS_Launcher_Mutex");
    if (GetLastError() == ERROR_ALREADY_EXISTS) {
        CloseHandle(g_mutex);
        return false;
    }
    return true;
}

// 处理控制台关闭事件
BOOL WINAPI ConsoleHandler(DWORD signal) {
    if (signal == CTRL_C_EVENT || signal == CTRL_CLOSE_EVENT) {
        std::wcout << L"\n启动器正在关闭..." << std::endl;
        g_shouldExit = true;
        return TRUE;
    }
    return FALSE;
}

// 监控主进程
void MonitorMainProcess() {
    bool restartAfterCrash = false;
    int normalExitCount = 0;
    const int maxNormalExits = 1;  // 正常退出后不再重启

    std::wcout << L"====== 启动器开始工作 ======" << std::endl;
    std::wcout << L"启动器PID: " << GetCurrentProcessId() << std::endl;

    // 检查命令行参数
    int argc = 0;
    wchar_t** argv = CommandLineToArgvW(GetCommandLineW(), &argc);
    if (argv != NULL) {
        for (int i = 0; i < argc; i++) {
            if (wcscmp(argv[i], RESTART_ARG) == 0) {
                restartAfterCrash = true;
                std::wcout << L"检测到异常重启参数" << std::endl;
                break;
            }
        }
        LocalFree(argv);
    }

    while (!g_shouldExit) {
        // 如果主程序不在运行，则启动它
        if (!IsProcessRunning(MAIN_APP_NAME)) {
            std::wcout << L"主程序未运行，正在启动..." << std::endl;

            DWORD exitCode = StartMainApp(restartAfterCrash);

            if (exitCode == 0xFFFFFFFF) {
                // 启动失败
                std::wcerr << L"无法启动主程序，等待5秒后重试..." << std::endl;
                for (int i = 0; i < 5 && !g_shouldExit; i++) {
                    std::this_thread::sleep_for(std::chrono::seconds(1));
                }
                continue;
            }

            // 重置重启标志
            restartAfterCrash = false;

            // 检查退出码
            if (IsNormalShutdown(exitCode)) {
                std::wcout << L"主程序正常退出，启动器将退出" << std::endl;
                normalExitCount++;
                if (normalExitCount >= maxNormalExits) {
                    break;
                }
            } else {
                std::wcout << L"主程序异常退出，将在5秒后重启..." << std::endl;
                restartAfterCrash = true;
                for (int i = 0; i < 5 && !g_shouldExit; i++) {
                    std::this_thread::sleep_for(std::chrono::seconds(1));
                }
            }
        } else {
            // 主程序正在运行，等待一会儿再检查
            for (int i = 0; i < 5 && !g_shouldExit; i++) {
                std::this_thread::sleep_for(std::chrono::seconds(1));
            }
        }
    }

    std::wcout << L"====== 启动器结束 ======" << std::endl;
}

int main() {
    // 设置控制台输出编码为UTF-8
    SetConsoleOutputCP(CP_UTF8);

    std::wcout << L"字研OS启动器 v1.0" << std::endl;
    std::wcout << L"功能: 监控主程序并在异常关闭时重启" << std::endl;
    std::wcout << L"启动参数 --restart-after-crash 表示上次是异常关闭" << std::endl;
    std::wcout << std::endl;

    // 检查是否应该启动（防止多个实例）
    if (!ShouldStartLauncher()) {
        std::wcerr << L"启动器已经在运行中，本实例将退出" << std::endl;
        return 1;
    }

    // 设置控制台事件处理
    SetConsoleCtrlHandler(ConsoleHandler, TRUE);

    MonitorMainProcess();

    // 清理互斥体
    if (g_mutex) {
        CloseHandle(g_mutex);
    }

    return 0;
}
