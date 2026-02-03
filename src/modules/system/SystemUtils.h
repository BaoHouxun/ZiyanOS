#ifndef SYSTEMUTILS_H
#define SYSTEMUTILS_H

#include <QObject>
#include <QString>
#include <QDebug>
#include <QCoreApplication>
#include <QGuiApplication>
#include <QScreen>
#include <QCursor>
#include <QPointF>
#include <QFileInfo>
#include <QDir>
#include <QTimer>
#include <QProcess>

// Windows平台特定的头文件
#ifdef Q_OS_WINDOWS
#include <windows.h>
#include <shlobj.h>
#include <shellapi.h>
#include <tchar.h>
#include <psapi.h>
#endif

class SystemUtils : public QObject
{
    Q_OBJECT

public:
    explicit SystemUtils(QObject *parent = nullptr);

    // 检测是否存在 pecmd.ini 文件
    Q_INVOKABLE bool hasPecmdIni();

    // 使用命令行执行关机
    Q_INVOKABLE void shutdownWithCommand();

    // 使用命令行执行重启
    Q_INVOKABLE void rebootWithCommand();

    // 正常退出应用
    Q_INVOKABLE void normalQuit();

    // 获取当前鼠标位置
    Q_INVOKABLE QPointF getCursorPosition();

    // 设置鼠标位置（模拟鼠标移动）
    Q_INVOKABLE void setCursorPosition(int x, int y);

    // 检查是否需要在PE环境中显示自定义鼠标
    Q_INVOKABLE bool needCustomMouse();

    Q_INVOKABLE bool setResolution(int width, int height);
    Q_INVOKABLE bool restoreOriginalResolution();

    // 新增：启动应用程序的方法
    Q_INVOKABLE bool startApplication(const QString& filePath);
    Q_INVOKABLE bool startApplicationWithArgs(const QString& filePath, const QString& arguments);
    Q_INVOKABLE QStringList getRunningProcesses();
    Q_INVOKABLE bool isProcessRunning(const QString& processName);

signals:
    // 鼠标位置改变信号
    void cursorPositionChanged(int x, int y);
    // 新增：应用程序启动结果信号
    void applicationStarted(const QString& appName, bool success);
    void applicationStartFailed(const QString& appName, const QString& error);
    // 新增：关机重启状态信号
    void shutdownStarted();
    void shutdownFailed(const QString& error);
    void rebootStarted();
    void rebootFailed(const QString& error);

private:
    QString getWindowsPath();

    // 新增：命令行执行关机重启
    bool executeCommand(const QString& command, const QStringList& arguments);
    bool executeShutdownCommand(const QString& arguments);
    bool executeRebootCommand();

    // Windows平台专用：提升权限以执行关机/重启
    bool enableShutdownPrivilege();

    // 新增：Windows平台启动应用的方法
#ifdef Q_OS_WINDOWS
    bool startApplicationWindows(const QString& filePath, const QString& arguments = "");
    QString getLastErrorMessage();
#endif

    int originalWidth = 0;
    int originalHeight = 0;
    bool hasOriginalResolution = false;
    QProcess* shutdownProcess = nullptr;
};

#endif // SYSTEMUTILS_H
