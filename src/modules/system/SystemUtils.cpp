#include "SystemUtils.h"

SystemUtils::SystemUtils(QObject *parent) : QObject(parent)
{
    shutdownProcess = new QProcess(this);
}

bool SystemUtils::hasPecmdIni()
{
#ifdef Q_OS_WINDOWS
    QString windowsPath = getWindowsPath();
    if (windowsPath.isEmpty()) {
        qDebug() << "无法获取Windows目录路径";
        return false;
    }

    QString pecmdIniPath = windowsPath + "\\pecmd.ini";
    QFileInfo pecmdFile(pecmdIniPath);

    bool exists = pecmdFile.exists() && pecmdFile.isFile();
    qDebug() << "检测pecmd.ini文件:" << pecmdIniPath << "存在:" << exists;

    return exists;
#else
    // 非Windows系统直接返回false（视为实体机）
    qDebug() << "非Windows系统，视为实体机";
    return false;
#endif
}

bool SystemUtils::enableShutdownPrivilege()
{
#ifdef Q_OS_WINDOWS
    HANDLE hToken = NULL;
    TOKEN_PRIVILEGES tkp = {0};

    // 获取当前进程的令牌句柄
    if (!OpenProcessToken(GetCurrentProcess(),
                          TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY,
                          &hToken)) {
        qWarning() << "无法打开进程令牌，错误码:" << GetLastError();
        return false;
    }

    // 获取关机权限的LUID
    LookupPrivilegeValue(NULL, SE_SHUTDOWN_NAME, &tkp.Privileges[0].Luid);

    tkp.PrivilegeCount = 1;
    tkp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;

    // 调整令牌权限
    if (!AdjustTokenPrivileges(hToken, FALSE, &tkp, 0, NULL, NULL)) {
        qWarning() << "无法调整令牌权限，错误码:" << GetLastError();
        CloseHandle(hToken);
        return false;
    }

    CloseHandle(hToken);
    qDebug() << "已成功启用关机权限";
    return true;
#else
    return false;
#endif
}

bool SystemUtils::setResolution(int width, int height)
{
#ifdef Q_OS_WINDOWS
    DEVMODEW devMode = {0};
    devMode.dmSize = sizeof(DEVMODEW);

    // 获取当前显示设置
    if (!EnumDisplaySettingsW(NULL, ENUM_CURRENT_SETTINGS, &devMode)) {
        qWarning() << "无法获取当前显示设置";
        return false;
    }

    // 保存原始分辨率（如果是第一次设置）
    if (!hasOriginalResolution) {
        originalWidth = devMode.dmPelsWidth;
        originalHeight = devMode.dmPelsHeight;
        hasOriginalResolution = true;
        qDebug() << "保存原始分辨率:" << originalWidth << "x" << originalHeight;
    }

    // 设置新分辨率
    devMode.dmPelsWidth = width;
    devMode.dmPelsHeight = height;
    devMode.dmFields = DM_PELSWIDTH | DM_PELSHEIGHT;

    // 应用新的显示设置
    LONG result = ChangeDisplaySettingsW(&devMode, CDS_TEST);

    if (result != DISP_CHANGE_SUCCESSFUL) {
        qWarning() << "测试分辨率失败:" << width << "x" << height << "错误码:" << result;
        return false;
    }

    // 实际应用设置
    result = ChangeDisplaySettingsW(&devMode, 0);

    if (result != DISP_CHANGE_SUCCESSFUL) {
        qWarning() << "应用分辨率失败:" << width << "x" << height << "错误码:" << result;
        return false;
    }

    qDebug() << "分辨率设置成功:" << width << "x" << height;
    return true;
#else
    return false;
#endif
}

bool SystemUtils::restoreOriginalResolution()
{
    if (!hasOriginalResolution) {
        qWarning() << "没有保存原始分辨率";
        return false;
    }

    return setResolution(originalWidth, originalHeight);
}

// 执行命令行
bool SystemUtils::executeCommand(const QString& command, const QStringList& arguments)
{
#ifdef Q_OS_WINDOWS
    QProcess process;
    process.setProgram(command);
    process.setArguments(arguments);

    // 隐藏命令行窗口
    process.setCreateProcessArgumentsModifier([](QProcess::CreateProcessArguments *args) {
        args->flags |= CREATE_NO_WINDOW;
    });

    // 执行命令
    process.start();

    // 等待命令执行完成
    if (!process.waitForStarted(3000)) {
        qWarning() << "命令启动失败:" << command << arguments;
        return false;
    }

    // 等待命令执行完成（最多30秒）
    if (!process.waitForFinished(30000)) {
        qWarning() << "命令执行超时:" << command << arguments;
        process.kill();
        return false;
    }

    int exitCode = process.exitCode();
    if (exitCode != 0) {
        qWarning() << "命令执行失败，退出码:" << exitCode << "错误输出:" << process.readAllStandardError();
        return false;
    }

    qDebug() << "命令执行成功:" << command << arguments;
    return true;
#else
    // 非Windows平台，使用系统命令
    QString fullCommand = command + " " + arguments.join(" ");
    int result = system(fullCommand.toStdString().c_str());
    return result == 0;
#endif
}

// 执行关机命令
bool SystemUtils::executeShutdownCommand(const QString& arguments)
{
#ifdef Q_OS_WINDOWS
    // Windows使用shutdown命令
    QStringList args;
    args << arguments << "/t" << "0";  // 立即执行

    // 如果需要管理员权限，先尝试提权
    if (!enableShutdownPrivilege()) {
        qWarning() << "提权失败，可能无法执行关机操作";
    }

    return executeCommand("shutdown", args);
#else
    // Linux/Mac使用相应的命令
    QStringList args;
    args << "-h" << "now";
    return executeCommand("shutdown", args);
#endif
}

// 执行重启命令
bool SystemUtils::executeRebootCommand()
{
#ifdef Q_OS_WINDOWS
    // Windows使用shutdown /r命令
    QStringList args;
    args << "/r" << "/t" << "0";  // 立即重启

    // 如果需要管理员权限，先尝试提权
    if (!enableShutdownPrivilege()) {
        qWarning() << "提权失败，可能无法执行重启操作";
    }

    return executeCommand("shutdown", args);
#else
    // Linux/Mac使用相应的命令
    QStringList args;
    args << "-r" << "now";
    return executeCommand("shutdown", args);
#endif
}

void SystemUtils::shutdownWithCommand()
{
#ifdef Q_OS_WINDOWS
    QString windowsPath = getWindowsPath();
    if (windowsPath.isEmpty()) {
        qWarning() << "无法获取Windows目录，使用正常退出";
        emit shutdownFailed("无法获取Windows目录");
        QCoreApplication::quit();
        return;
    }

    QString pecmdIniPath = windowsPath + "\\pecmd.ini";
    QFileInfo pecmdFile(pecmdIniPath);

    if (pecmdFile.exists() && pecmdFile.isFile()) {
        qDebug() << "检测到pecmd.ini，使用命令行执行关机";

        emit shutdownStarted();

        // 使用命令行执行关机
        bool success = executeShutdownCommand("/s");

        if (success) {
            qDebug() << "关机命令已发送成功";

            // 等待3秒后退出应用，给系统处理关机的时间
            QTimer::singleShot(3000, []() {
                QCoreApplication::quit();
            });
        } else {
            qWarning() << "关机命令执行失败";
            emit shutdownFailed("关机命令执行失败");

            // 如果命令执行失败，尝试使用Windows API作为备选方案
            qDebug() << "尝试使用Windows API作为备选方案";

            // 提升权限
            if (!enableShutdownPrivilege()) {
                qWarning() << "权限提升失败，关机操作可能被拒绝";
            }

            // 执行关机操作
            BOOL result = ExitWindowsEx(EWX_SHUTDOWN | EWX_FORCE | EWX_POWEROFF, 0);

            if (result) {
                qDebug() << "Windows API关机命令已发送成功";
                QTimer::singleShot(3000, []() {
                    QCoreApplication::quit();
                });
            } else {
                DWORD error = GetLastError();
                QString errorMsg = QString("关机失败，错误码: %1").arg(error);
                qWarning() << errorMsg;
                emit shutdownFailed(errorMsg);

                // 如果关机失败，正常退出应用
                QCoreApplication::quit();
            }
        }
    } else {
        // 没有检测到pecmd.ini，视为实体机，正常退出
        qDebug() << "未检测到pecmd.ini，使用正常退出应用";
        QCoreApplication::quit();
    }
#else
    // 非Windows系统尝试执行关机命令
    qDebug() << "非Windows系统，尝试执行关机命令";

    emit shutdownStarted();

    bool success = executeShutdownCommand("");

    if (success) {
        qDebug() << "关机命令已发送成功";
        QTimer::singleShot(3000, []() {
            QCoreApplication::quit();
        });
    } else {
        qWarning() << "关机命令执行失败";
        emit shutdownFailed("关机命令执行失败");
        QCoreApplication::quit();
    }
#endif
}

void SystemUtils::rebootWithCommand()
{
#ifdef Q_OS_WINDOWS
    QString windowsPath = getWindowsPath();
    if (windowsPath.isEmpty()) {
        qWarning() << "无法获取Windows目录，使用正常退出";
        emit rebootFailed("无法获取Windows目录");
        QCoreApplication::exit(0);
        return;
    }

    QString pecmdIniPath = windowsPath + "\\pecmd.ini";
    QFileInfo pecmdFile(pecmdIniPath);

    if (pecmdFile.exists() && pecmdFile.isFile()) {
        qDebug() << "检测到pecmd.ini，使用命令行执行重启";

        emit rebootStarted();

        // 使用命令行执行重启
        bool success = executeRebootCommand();

        if (success) {
            qDebug() << "重启命令已发送成功";

            // 等待3秒后退出应用，给系统处理重启的时间
            QTimer::singleShot(3000, []() {
                QCoreApplication::exit(1);
            });
        } else {
            qWarning() << "重启命令执行失败";
            emit rebootFailed("重启命令执行失败");

            // 如果命令执行失败，尝试使用Windows API作为备选方案
            qDebug() << "尝试使用Windows API作为备选方案";

            // 提升权限
            if (!enableShutdownPrivilege()) {
                qWarning() << "权限提升失败，重启操作可能被拒绝";
            }

            // 执行重启操作
            BOOL result = ExitWindowsEx(EWX_REBOOT | EWX_FORCE, 0);

            if (result) {
                qDebug() << "Windows API重启命令已发送成功";
                QTimer::singleShot(3000, []() {
                    QCoreApplication::exit(1);
                });
            } else {
                DWORD error = GetLastError();
                QString errorMsg = QString("重启失败，错误码: %1").arg(error);
                qWarning() << errorMsg;
                emit rebootFailed(errorMsg);

                // 如果重启失败，正常退出应用
                QCoreApplication::exit(1);
            }
        }
    } else {
        // 没有检测到pecmd.ini，视为实体机，正常退出
        qDebug() << "未检测到pecmd.ini，使用正常退出应用";
        QCoreApplication::exit(0);
    }
#else
    // 非Windows系统尝试执行重启命令
    qDebug() << "非Windows系统，尝试执行重启命令";

    emit rebootStarted();

    bool success = executeRebootCommand();

    if (success) {
        qDebug() << "重启命令已发送成功";
        QTimer::singleShot(3000, []() {
            QCoreApplication::exit(1);
        });
    } else {
        qWarning() << "重启命令执行失败";
        emit rebootFailed("重启命令执行失败");
        QCoreApplication::exit(0);
    }
#endif
}

void SystemUtils::normalQuit()
{
    qDebug() << "正常退出应用，返回码: 0";

    // 正常退出，返回码0
    QCoreApplication::exit(0);
}

QPointF SystemUtils::getCursorPosition()
{
    if (QGuiApplication::primaryScreen()) {
        return QCursor::pos();
    }
    return QPointF(0, 0);
}

void SystemUtils::setCursorPosition(int x, int y)
{
    QCursor::setPos(x, y);
    emit cursorPositionChanged(x, y);
}

bool SystemUtils::needCustomMouse()
{
    // 在PE环境下可能需要自定义鼠标
    return hasPecmdIni();
}

QString SystemUtils::getWindowsPath()
{
#ifdef Q_OS_WINDOWS
    // 尝试从环境变量获取Windows目录
    wchar_t windowsPath[MAX_PATH] = {0};

    // 方法1: 使用SHGetFolderPath获取Windows目录
    if (SUCCEEDED(SHGetFolderPathW(NULL, CSIDL_WINDOWS, NULL, 0, windowsPath))) {
        return QString::fromWCharArray(windowsPath);
    }

    // 方法2: 使用GetWindowsDirectory API
    if (GetWindowsDirectoryW(windowsPath, MAX_PATH) > 0) {
        return QString::fromWCharArray(windowsPath);
    }

    // 方法3: 尝试从环境变量获取
    QString windir = qEnvironmentVariable("SystemRoot");
    if (!windir.isEmpty()) {
        return windir;
    }

    windir = qEnvironmentVariable("WINDIR");
    if (!windir.isEmpty()) {
        return windir;
    }

    // 方法4: 尝试常见的Windows目录路径
    QStringList possiblePaths = {
        "C:\\Windows",
        "D:\\Windows"
    };

    for (const QString &path : possiblePaths) {
        QDir dir(path);
        if (dir.exists()) {
            return path;
        }
    }
#endif

    return QString();
}

// 新增：启动应用程序的方法
bool SystemUtils::startApplication(const QString& filePath)
{
    return startApplicationWithArgs(filePath, "");
}

bool SystemUtils::startApplicationWithArgs(const QString& filePath, const QString& arguments)
{
#ifdef Q_OS_WINDOWS
    return startApplicationWindows(filePath, arguments);
#else
    // 非Windows平台，暂时返回false
    emit applicationStartFailed(QFileInfo(filePath).fileName(), "非Windows平台不支持");
    return false;
#endif
}

#ifdef Q_OS_WINDOWS
bool SystemUtils::startApplicationWindows(const QString& filePath, const QString& arguments)
{
    QString appName = QFileInfo(filePath).fileName();

    // 检查文件是否存在
    QFileInfo fileInfo(filePath);
    if (!fileInfo.exists()) {
        QString error = "文件不存在: " + filePath;
        qWarning() << error;
        emit applicationStartFailed(appName, error);
        return false;
    }

    // 检查文件是否是可执行文件
    QString suffix = fileInfo.suffix().toLower();
    QStringList executableSuffixes = {"exe", "com", "bat", "cmd", "msi"};
    if (!executableSuffixes.contains(suffix)) {
        QString error = "文件不是可执行文件: " + filePath;
        qWarning() << error;
        emit applicationStartFailed(appName, error);
        return false;
    }

    // 将路径转换为Windows宽字符格式
    std::wstring wFilePath = filePath.toStdWString();
    std::wstring wArguments = arguments.toStdWString();

    // 构建STARTUPINFO结构
    STARTUPINFOW startupInfo = {0};
    startupInfo.cb = sizeof(STARTUPINFOW);

    // 构建PROCESS_INFORMATION结构
    PROCESS_INFORMATION processInfo = {0};

    // 准备命令行（需要可修改的字符串）
    std::wstring commandLine = L"\"" + wFilePath + L"\"";
    if (!wArguments.empty()) {
        commandLine += L" " + wArguments;
    }

    // 创建可修改的命令行缓冲区
    wchar_t* cmdLine = new wchar_t[commandLine.size() + 1];
    wcscpy_s(cmdLine, commandLine.size() + 1, commandLine.c_str());

    // 尝试以管理员权限运行（如果需要的話）
    DWORD creationFlags = CREATE_NO_WINDOW; // 不显示窗口

    // 根据文件类型设置不同的创建标志
    if (suffix == "exe" || suffix == "com") {
        creationFlags = 0; // 显示窗口
    }

    // 启动应用程序
    BOOL success = CreateProcessW(
        wFilePath.c_str(),           // 应用程序路径
        cmdLine,                     // 命令行（包括参数）
        NULL,                        // 进程安全属性
        NULL,                        // 线程安全属性
        FALSE,                       // 句柄继承
        creationFlags,               // 创建标志
        NULL,                        // 环境变量
        NULL,                        // 当前目录
        &startupInfo,                // STARTUPINFO
        &processInfo                 // PROCESS_INFORMATION
        );

    // 清理命令行缓冲区
    delete[] cmdLine;

    if (success) {
        qDebug() << "应用程序启动成功:" << filePath;

        // 关闭不需要的句柄
        CloseHandle(processInfo.hProcess);
        CloseHandle(processInfo.hThread);

        emit applicationStarted(appName, true);
        return true;
    } else {
        DWORD errorCode = GetLastError();
        QString error = getLastErrorMessage();
        qWarning() << "应用程序启动失败:" << filePath << "错误码:" << errorCode << "错误信息:" << error;
        emit applicationStartFailed(appName, error);
        return false;
    }
}

QString SystemUtils::getLastErrorMessage()
{
    DWORD errorCode = GetLastError();
    if (errorCode == 0) {
        return "未知错误";
    }

    wchar_t* messageBuffer = nullptr;
    DWORD bufferSize = FormatMessageW(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        errorCode,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        (LPWSTR)&messageBuffer,
        0,
        NULL
        );

    if (bufferSize == 0) {
        return QString("错误码: %1").arg(errorCode);
    }

    QString errorMessage = QString::fromWCharArray(messageBuffer, bufferSize);
    LocalFree(messageBuffer);

    return errorMessage.trimmed();
}

QStringList SystemUtils::getRunningProcesses()
{
    QStringList processes;

    // 获取进程快照
    DWORD processesArray[1024], bytesReturned;
    if (!EnumProcesses(processesArray, sizeof(processesArray), &bytesReturned)) {
        return processes;
    }

    DWORD numProcesses = bytesReturned / sizeof(DWORD);

    for (DWORD i = 0; i < numProcesses; i++) {
        DWORD processID = processesArray[i];
        if (processID == 0) continue;

        HANDLE hProcess = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, FALSE, processID);
        if (hProcess) {
            wchar_t processName[MAX_PATH] = L"<unknown>";
            HMODULE hModule;
            DWORD bytesNeeded;

            if (EnumProcessModules(hProcess, &hModule, sizeof(hModule), &bytesNeeded)) {
                GetModuleBaseNameW(hProcess, hModule, processName, sizeof(processName) / sizeof(wchar_t));
            }

            QString name = QString::fromWCharArray(processName);
            if (!name.isEmpty() && name != "<unknown>") {
                processes.append(name + " (PID: " + QString::number(processID) + ")");
            }

            CloseHandle(hProcess);
        }
    }

    return processes;
}

bool SystemUtils::isProcessRunning(const QString& processName)
{
    QStringList processes = getRunningProcesses();
    for (const QString& process : processes) {
        if (process.contains(processName, Qt::CaseInsensitive)) {
            return true;
        }
    }
    return false;
}

#else
// 非Windows平台的空实现
QStringList SystemUtils::getRunningProcesses()
{
    return QStringList();
}

bool SystemUtils::isProcessRunning(const QString& processName)
{
    return false;
}
#endif
