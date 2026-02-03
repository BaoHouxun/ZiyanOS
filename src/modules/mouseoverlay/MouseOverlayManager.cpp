#include "MouseOverlayManager.h"

#ifdef Q_OS_WINDOWS
#include <windows.h>
#include <tlhelp32.h>
#endif

MouseOverlayManager::MouseOverlayManager(QObject *parent)
    : QObject(parent)
    , m_process(nullptr)
    , m_isRunning(false)
{
}

MouseOverlayManager::~MouseOverlayManager()
{
    stopMouseOverlay();
}

// 静态方法：检查并结束鼠标覆盖程序
void MouseOverlayManager::checkAndTerminateMouseOverlay()
{
#ifdef Q_OS_WINDOWS
    qDebug() << "检查鼠标覆盖程序是否在运行...";

    HANDLE hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hSnapshot == INVALID_HANDLE_VALUE) {
        qWarning() << "无法创建进程快照";
        return;
    }

    PROCESSENTRY32 pe32;
    pe32.dwSize = sizeof(PROCESSENTRY32);

    if (!Process32First(hSnapshot, &pe32)) {
        CloseHandle(hSnapshot);
        qWarning() << "无法获取第一个进程";
        return;
    }

    do {
        QString processName = QString::fromWCharArray(pe32.szExeFile);
        if (processName.compare("MouseOverlay.exe", Qt::CaseInsensitive) == 0) {
            qDebug() << "找到鼠标覆盖程序，PID:" << pe32.th32ProcessID;

            // 尝试优雅地结束进程
            HANDLE hProcess = OpenProcess(PROCESS_TERMINATE, FALSE, pe32.th32ProcessID);
            if (hProcess) {
                if (TerminateProcess(hProcess, 0)) {
                    qDebug() << "已结束鼠标覆盖程序";
                } else {
                    DWORD error = GetLastError();
                    qWarning() << "无法结束鼠标覆盖程序，错误码:" << error;
                }
                CloseHandle(hProcess);
            } else {
                qWarning() << "无法打开鼠标覆盖程序进程";
            }
        }
    } while (Process32Next(hSnapshot, &pe32));

    CloseHandle(hSnapshot);
    qDebug() << "鼠标覆盖程序检查完成";
#else
    qDebug() << "非Windows平台，跳过鼠标覆盖程序检查";
#endif
}

void MouseOverlayManager::startMouseOverlay()
{
    if (m_isRunning) {
        qDebug() << "鼠标覆盖程序已经在运行";
        return;
    }

#ifdef Q_OS_WINDOWS
    qDebug() << "启动鼠标覆盖程序...";

    // 获取当前应用目录
    QString appDir = QCoreApplication::applicationDirPath();
    QString mouseExePath = appDir + "/MouseOverlay.exe";

    // 检查文件是否存在
    if (!QFile::exists(mouseExePath)) {
        qWarning() << "鼠标覆盖程序不存在:" << mouseExePath;
        qWarning() << "请确保已构建MouseOverlay子项目";
        return;
    }

    // 创建进程
    m_process = new QProcess(this);

    // 连接信号
    connect(m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &MouseOverlayManager::handleProcessFinished);
    connect(m_process, &QProcess::errorOccurred,
            this, &MouseOverlayManager::handleProcessError);

    // 设置进程环境（如果有特殊需求）
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    m_process->setProcessEnvironment(env);

    // 启动进程
    qDebug() << "启动:" << mouseExePath;
    m_process->start(mouseExePath);

    // 等待进程启动
    if (!m_process->waitForStarted(3000)) {
        qWarning() << "无法启动鼠标覆盖程序";
        delete m_process;
        m_process = nullptr;
        return;
    }

    m_isRunning = true;
    emit isRunningChanged(true);
    qDebug() << "鼠标覆盖程序已启动";
#else
    qDebug() << "鼠标覆盖程序仅支持Windows平台";
#endif
}

void MouseOverlayManager::stopMouseOverlay()
{
    if (!m_isRunning || !m_process) {
        return;
    }

    qDebug() << "停止鼠标覆盖程序...";

    // 尝试正常终止
    m_process->terminate();

    // 等待5秒让程序正常退出
    if (!m_process->waitForFinished(5000)) {
        // 如果正常终止失败，强制终止
        qWarning() << "鼠标覆盖程序未正常退出，强制终止";
        m_process->kill();
        m_process->waitForFinished(1000);
    }

    m_isRunning = false;
    m_process = nullptr;
    emit isRunningChanged(false);
    qDebug() << "鼠标覆盖程序已停止";
}

bool MouseOverlayManager::isRunning() const
{
    return m_isRunning;
}

void MouseOverlayManager::handleProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    qDebug() << "鼠标覆盖程序退出，退出码:" << exitCode << "退出状态:" << exitStatus;
    m_isRunning = false;
    m_process = nullptr;
    emit isRunningChanged(false);
}

void MouseOverlayManager::handleProcessError(QProcess::ProcessError error)
{
    qWarning() << "鼠标覆盖程序错误:" << error;
    m_isRunning = false;
    m_process = nullptr;
    emit isRunningChanged(false);
}
