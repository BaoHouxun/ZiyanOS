#ifndef MOUSEOVERLAYMANAGER_H
#define MOUSEOVERLAYMANAGER_H

#include <QObject>
#include <QProcess>
#include <QCoreApplication>
#include <QFileInfo>
#include <QDebug>

#ifdef Q_OS_WINDOWS
#include <windows.h>
#include <tlhelp32.h>
#endif

class MouseOverlayManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isRunning READ isRunning NOTIFY isRunningChanged)

public:
    explicit MouseOverlayManager(QObject *parent = nullptr);
    ~MouseOverlayManager();

    // 启动鼠标覆盖程序
    Q_INVOKABLE void startMouseOverlay();

    // 停止鼠标覆盖程序
    Q_INVOKABLE void stopMouseOverlay();

    // 检查是否正在运行
    bool isRunning() const;

    // 静态方法：检查并结束鼠标覆盖程序
    static void checkAndTerminateMouseOverlay();

signals:
    void isRunningChanged(bool running);

private slots:
    void handleProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void handleProcessError(QProcess::ProcessError error);

private:
    QProcess *m_process;
    bool m_isRunning;
};

#endif // MOUSEOVERLAYMANAGER_H
