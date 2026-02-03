#include "LogManager.h"
#include <QCoreApplication>
#include <QMutexLocker>

// 静态成员初始化
LogManager* LogManager::m_instance = nullptr;
std::mutex LogManager::m_fileMutex;
QtMessageHandler LogManager::s_originalMessageHandler = nullptr;

LogManager::LogManager(QObject *parent)
    : QObject(parent)
    , m_initialized(false)
    , m_qmlEngine(nullptr)
{
}

LogManager::~LogManager()
{
    uninstallMessageHandler();

    // 关闭日志文件
    if (m_logFile.isOpen()) {
        writeToFile("========== 应用程序结束 ==========");
        m_logStream.flush();
        m_logFile.close();
    }

    m_instance = nullptr;
}

LogManager* LogManager::instance()
{
    static std::mutex instanceMutex;
    std::lock_guard<std::mutex> lock(instanceMutex);

    if (!m_instance) {
        m_instance = new LogManager();
    }
    return m_instance;
}

void LogManager::initialize()
{
    if (m_initialized) {
        return;
    }

    qDebug() << "开始初始化日志系统";

    // 1. 初始化日志目录
    if (!initLogDirectory()) {
        qWarning() << "无法初始化日志目录";
        return;
    }

    // 2. 初始化日志文件
    if (!initLogFile()) {
        qWarning() << "无法初始化日志文件";
        return;
    }

    // 3. 写入启动日志
    writeToFile("========== 应用程序启动 ==========");
    writeToFile("应用程序: " + QCoreApplication::applicationName());
    writeToFile("版本: " + QCoreApplication::applicationVersion());
    writeToFile("启动时间: " + getCurrentTimestamp());
    writeToFile("日志文件: " + m_logFilePath);

    // 4. 安装消息处理器（捕获qDebug等）
    installMessageHandler();

    m_initialized = true;

    qDebug() << "日志系统初始化完成，日志文件:" << m_logFilePath;

    emit initialized();
}

void LogManager::writeLog(const QString &message, const QString &category)
{
    if (!m_initialized) {
        // 如果日志系统未初始化，使用qDebug输出
        qDebug() << "[" << category << "]" << message;
        return;
    }

    QString timestamp = getCurrentTimestamp();
    QString logEntry = QString("[%1] [%2] %3")
                           .arg(timestamp)
                           .arg(category)
                           .arg(message);

    // 写入文件
    writeToFile(logEntry);

    // 发出信号（可选，用于UI显示）
    emit logMessage(message, category, timestamp);
}

QString LogManager::logFilePath() const
{
    return m_logFilePath;
}

void LogManager::setQmlEngine(QQmlEngine *engine)
{
    m_qmlEngine = engine;

    if (m_qmlEngine) {
        // 连接QML引擎的警告信号
        connect(m_qmlEngine, &QQmlEngine::warnings, this, &LogManager::handleQmlWarnings);
        qDebug() << "已连接QML引擎警告信号";
    }
}

bool LogManager::initLogDirectory()
{
    // 获取应用程序目录
    QString appDir = QCoreApplication::applicationDirPath();
    QString logDir = appDir + "/logs";

    QDir dir(logDir);
    if (!dir.exists()) {
        if (!dir.mkpath(".")) {
            qWarning() << "无法创建日志目录:" << logDir;
            return false;
        }
        qDebug() << "创建日志目录:" << logDir;
    }

    return true;
}

bool LogManager::initLogFile()
{
    // 获取应用程序目录
    QString appDir = QCoreApplication::applicationDirPath();
    QString logDir = appDir + "/logs";

    // 使用当前日期时间作为日志文件名
    QString timestamp = QDateTime::currentDateTime().toString("yyyyMMdd_HHmmss");
    m_logFilePath = logDir + "/ziyanos_" + timestamp + ".log";

    // 打开日志文件
    m_logFile.setFileName(m_logFilePath);
    if (!m_logFile.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        qWarning() << "无法打开日志文件:" << m_logFilePath;
        return false;
    }

    // 设置日志流
    m_logStream.setDevice(&m_logFile);

    qDebug() << "日志文件已创建:" << m_logFilePath;
    return true;
}

void LogManager::installMessageHandler()
{
    // 保存原始的消息处理器
    s_originalMessageHandler = qInstallMessageHandler(qtMessageHandler);
    qDebug() << "Qt消息处理器已安装";
}

void LogManager::uninstallMessageHandler()
{
    if (s_originalMessageHandler) {
        qInstallMessageHandler(s_originalMessageHandler);
        s_originalMessageHandler = nullptr;
        qDebug() << "Qt消息处理器已卸载";
    }
}

void LogManager::qtMessageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    // 首先，将消息写入日志文件
    if (m_instance && m_instance->m_initialized) {
        QString levelStr = getLogLevelString(type);
        QString timestamp = getCurrentTimestamp();

        // 构建完整的日志条目
        QString logEntry = QString("[%1] [%2] %3")
                               .arg(timestamp)
                               .arg(levelStr)
                               .arg(msg);

// 添加上下文信息（在调试模式下）
#ifdef QT_DEBUG
        if (context.file && context.line && context.function) {
            QString contextInfo = QString(" (文件: %1, 行: %2, 函数: %3)")
                                      .arg(context.file)
                                      .arg(context.line)
                                      .arg(context.function);
            logEntry += contextInfo;
        }
#endif

        m_instance->writeToFile(logEntry);
    }

    // 然后，将消息传递给原始处理器（输出到控制台）
    if (s_originalMessageHandler) {
        s_originalMessageHandler(type, context, msg);
    } else {
        // 如果没有原始处理器，使用默认输出
        QByteArray localMsg = msg.toLocal8Bit();
        const char* file = context.file ? context.file : "";
        const char* function = context.function ? context.function : "";

        switch (type) {
        case QtDebugMsg:
            fprintf(stderr, "调试: %s (%s:%u, %s)\n", localMsg.constData(), file, context.line, function);
            break;
        case QtInfoMsg:
            fprintf(stderr, "信息: %s\n", localMsg.constData());
            break;
        case QtWarningMsg:
            fprintf(stderr, "警告: %s (%s:%u, %s)\n", localMsg.constData(), file, context.line, function);
            break;
        case QtCriticalMsg:
            fprintf(stderr, "严重: %s (%s:%u, %s)\n", localMsg.constData(), file, context.line, function);
            break;
        case QtFatalMsg:
            fprintf(stderr, "致命: %s (%s:%u, %s)\n", localMsg.constData(), file, context.line, function);
            break;
        }
    }
}

void LogManager::handleQmlWarnings(const QList<QQmlError> &warnings)
{
    for (const QQmlError &error : warnings) {
        QString errorMessage;

        if (error.url().isValid()) {
            errorMessage = QString("%1:%2: %3")
            .arg(error.url().toString())
                .arg(error.line())
                .arg(error.description());
        } else {
            errorMessage = QString("行 %1: %2")
                               .arg(error.line())
                               .arg(error.description());
        }

        // 写入日志文件
        writeLog(errorMessage, "QML_ERROR");

        // 发出信号
        emit qmlError(error.description(),
                      error.url().toString(),
                      error.line());

        // 同时输出到控制台
        qWarning() << "QML错误:" << errorMessage;
    }
}

void LogManager::writeToFile(const QString &message)
{
    std::lock_guard<std::mutex> lock(m_fileMutex);

    if (m_logFile.isOpen()) {
        m_logStream << message << "\n";
        m_logStream.flush();
    }
}

QString LogManager::getLogLevelString(QtMsgType type)
{
    switch (type) {
    case QtDebugMsg:    return "DEBUG";
    case QtInfoMsg:     return "INFO";
    case QtWarningMsg:  return "WARNING";
    case QtCriticalMsg: return "CRITICAL";
    case QtFatalMsg:    return "FATAL";
    default:            return "UNKNOWN";
    }
}

QString LogManager::getCurrentTimestamp()
{
    return QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss.zzz");
}
