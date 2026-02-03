#ifndef LOGMANAGER_H
#define LOGMANAGER_H

#include <QObject>
#include <QFile>
#include <QTextStream>
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QMutex>
#include <QQmlEngine>
#include <QQmlError>
#include <iostream>
#include <mutex>

class LogManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isInitialized READ isInitialized NOTIFY initialized)

public:
    explicit LogManager(QObject *parent = nullptr);
    ~LogManager();

    // 单例模式访问
    static LogManager* instance();

    // 初始化日志系统
    Q_INVOKABLE void initialize();

    // 获取是否已初始化
    bool isInitialized() const { return m_initialized; }

    // 手动写入日志
    Q_INVOKABLE void writeLog(const QString &message, const QString &category = "INFO");

    // 获取日志文件路径
    Q_INVOKABLE QString logFilePath() const;

    // 设置 QML 引擎以捕获 QML 错误
    Q_INVOKABLE void setQmlEngine(QQmlEngine *engine);

signals:
    void initialized();
    void logMessage(const QString &message, const QString &category, const QString &timestamp);
    void qmlError(const QString &errorMessage, const QString &url, int line);

private:
    // 初始化日志目录
    bool initLogDirectory();

    // 初始化日志文件
    bool initLogFile();

    // 安装消息处理器
    void installMessageHandler();

    // 卸载消息处理器
    void uninstallMessageHandler();

    // Qt消息处理器（静态）
    static void qtMessageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg);

    // QML警告处理器
    void handleQmlWarnings(const QList<QQmlError> &warnings);

    // 写入日志到文件（线程安全）
    void writeToFile(const QString &message);

    // 获取日志等级字符串
    static QString getLogLevelString(QtMsgType type);

    // 获取当前时间字符串
    static QString getCurrentTimestamp();

private:
    static LogManager* m_instance;
    static std::mutex m_fileMutex;

    QFile m_logFile;
    QTextStream m_logStream;
    QString m_logFilePath;
    bool m_initialized;

    // QML引擎指针
    QQmlEngine *m_qmlEngine;

    // 原始消息处理器
    static QtMessageHandler s_originalMessageHandler;
};

#endif // LOGMANAGER_H
