#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QFontDatabase>
#include <QFont>
#include <QDebug>
#include <QStringList>
#include <QQmlContext>
#include <QCommandLineParser>
#include <QCommandLineOption>

#include "filesystem.h"
#include "SettingsManager.h"
#include "SystemUtils.h"
#include "DownloadManager.h"
#include "MouseOverlayManager.h"
#include "LogManager.h"
#include "WallpaperManager.h"

int main(int argc, char *argv[])
{
    // 1. 创建应用程序实例
    QGuiApplication app(argc, argv);

    // 2. 设置应用程序信息
    app.setOrganizationName("Ziyan Studio");
    app.setApplicationName("ZiyanOS");
    app.setApplicationVersion("1.0.0");

    // 3. 解析命令行参数
    QCommandLineParser parser;
    parser.setApplicationDescription("字研OS");
    parser.addHelpOption();
    parser.addVersionOption();

    // 添加重启参数选项
    QCommandLineOption restartOption("restart-after-crash",
                                     "应用程序崩溃后由启动器重新启动");
    parser.addOption(restartOption);

    // 解析命令行参数
    parser.process(app);

    // 检查是否是异常重启
    bool restartAfterCrash = parser.isSet(restartOption);

    // 4. 如果是从异常重启，检查并结束可能还在运行的鼠标覆盖程序
    if (restartAfterCrash) {
        qInfo() << "检测到异常重启参数，上次可能是异常关闭";
        qInfo() << "检查并结束可能残留的鼠标覆盖程序...";
        MouseOverlayManager::checkAndTerminateMouseOverlay();
    }

    // 5. 记录应用程序启动信息
    qDebug() << "========== 应用程序启动 ==========";
    qDebug() << "应用程序名称:" << app.applicationName();
    qDebug() << "应用程序版本:" << app.applicationVersion();
    qDebug() << "组织名称:" << app.organizationName();

    if (restartAfterCrash) {
        qInfo() << "上次异常关闭已恢复";
    }

    // 6. 初始化日志系统（尽可能早）
    qDebug() << "开始初始化日志系统...";
    LogManager::instance()->initialize();
    qDebug() << "日志系统初始化完成";

    // 7. 创建鼠标覆盖管理器实例
    MouseOverlayManager mouseOverlayManager;

    // 8. 检查是否在PE环境（通过检查当前目录是否有pecmd.ini）
    QString currentDir = QCoreApplication::applicationDirPath();
    QString pecmdIniPath = currentDir + "/pecmd.ini";
    bool hasPecmdIni = QFile::exists(pecmdIniPath);

    if (hasPecmdIni) {
        qDebug() << "检测到pecmd.ini（PE环境），启动鼠标覆盖程序";
        mouseOverlayManager.startMouseOverlay();
    } else {
        qDebug() << "未检测到pecmd.ini（实体机环境），不启动鼠标覆盖程序";
    }

    // 9. 现在开始，所有的qDebug、qInfo、qWarning等输出都会被捕获到日志文件

    // 10. 设置应用程序样式
    QQuickStyle::setStyle("Basic");

    // 11. 确保当最后一个窗口关闭时应用程序退出
    app.setQuitOnLastWindowClosed(true);

    // 12. 加载 Noto Color Emoji 字体
    QString emojiFontFamily;
    int emojiFontId = QFontDatabase::addApplicationFont(":/qt/qml/ZiyanOS/src/resources/fonts/NotoColorEmoji-Regular.ttf");
    if (emojiFontId != -1) {
        QStringList emojiFamilies = QFontDatabase::applicationFontFamilies(emojiFontId);
        if (!emojiFamilies.isEmpty()) {
            emojiFontFamily = emojiFamilies.at(0);
            qDebug() << "成功加载 Noto Color Emoji 字体:" << emojiFontFamily;
        } else {
            qWarning() << "无法获取 Noto Color Emoji 字体的字体族名称";
        }
    } else {
        qWarning() << "无法加载 Noto Color Emoji 字体文件";
    }

    // 13. 加载 Source Han Sans SC 字体
    QString chineseFontFamily;
    int chineseFontId = QFontDatabase::addApplicationFont(":/qt/qml/ZiyanOS/src/resources/fonts/SourceHanSansSC-Medium-2.otf");
    if (chineseFontId != -1) {
        QStringList chineseFamilies = QFontDatabase::applicationFontFamilies(chineseFontId);
        if (!chineseFamilies.isEmpty()) {
            chineseFontFamily = chineseFamilies.at(0);
            qDebug() << "成功加载 Source Han Sans SC 字体:" << chineseFontFamily;
        } else {
            qWarning() << "无法获取 Source Han Sans SC 字体的字体族名称";
        }
    } else {
        qWarning() << "无法加载 Source Han Sans SC 字体文件";
    }

    // 14. 创建 QML 引擎
    QQmlApplicationEngine engine;

    // 15. 连接QML引擎到日志管理器以捕获QML错误
    LogManager::instance()->setQmlEngine(&engine);

    // 16. 设置全局字体 - 只使用项目中的字体，不使用系统字体回退
    QStringList fontFamilies;

    // 优先使用中文正文字体
    if (!chineseFontFamily.isEmpty()) {
        fontFamilies << chineseFontFamily;
    } else {
        qWarning() << "中文正文字体未加载，将影响中文显示";
    }

    // 然后添加Emoji字体
    if (!emojiFontFamily.isEmpty()) {
        fontFamilies << emojiFontFamily;
    } else {
        qWarning() << "Emoji字体未加载，Emoji表情将无法正确显示";
    }

    // 如果两个字体都加载失败，使用Qt的默认字体
    if (fontFamilies.isEmpty()) {
        qCritical() << "所有字体文件加载失败，使用Qt默认字体";
        QFont systemFont = QFontDatabase::systemFont(QFontDatabase::GeneralFont);
        app.setFont(systemFont);
        qDebug() << "使用系统默认字体:" << systemFont.family();
    } else {
        // 创建字体对象并设置字体族列表
        QFont globalFont;
        globalFont.setFamilies(fontFamilies);
        globalFont.setPixelSize(12);

        // 设置额外的字体属性来优化显示
        globalFont.setHintingPreference(QFont::PreferFullHinting);
        globalFont.setStyleStrategy(QFont::PreferAntialias);

        app.setFont(globalFont);
        qDebug() << "已设置全局字体，字体族列表:" << fontFamilies;
        qDebug() << "字体大小:" << globalFont.pixelSize();
    }

    // 17. 注册C++类到QML
    qmlRegisterType<FileSystem>("ZiyanOS.FileSystem", 1, 0, "FileSystem");
    qmlRegisterType<SettingsManager>("ZiyanOS.SettingsManager", 1, 0, "SettingsManager");
    qmlRegisterType<SystemUtils>("ZiyanOS.SystemUtils", 1, 0, "SystemUtils");
    qmlRegisterType<DownloadManager>("ZiyanOS.DownloadManager", 1, 0, "DownloadManager");
    qmlRegisterType<MouseOverlayManager>("ZiyanOS.MouseOverlayManager", 1, 0, "MouseOverlayManager");
    qmlRegisterType<LogManager>("ZiyanOS.LogManager", 1, 0, "LogManager");
    qmlRegisterType<WallpaperManager>("ZiyanOS.WallpaperManager", 1, 0, "WallpaperManager");
    qmlRegisterType<WallpaperInfo>("ZiyanOS.WallpaperInfo", 1, 0, "WallpaperInfo");

    qDebug() << "已注册C++类到QML系统";

    // 18. 连接QML引擎对象创建失败信号
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() {
                         qCritical() << "QML对象创建失败，应用程序退出";
                         QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);

    // 19. 加载QML主模块
    qDebug() << "正在加载QML主模块...";
    engine.loadFromModule("ZiyanOS", "WindowManager");

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "无法加载QML主模块，应用程序退出";
        return -1;
    }

    qDebug() << "QML引擎加载完成，进入事件循环";
    qInfo() << "========== 应用程序启动完成 ==========";

    // 20. 执行应用程序事件循环
    int exitCode = app.exec();

    // 21. 应用程序退出前，停止鼠标覆盖程序
    if (mouseOverlayManager.isRunning()) {
        qDebug() << "应用程序退出，停止鼠标覆盖程序";
        mouseOverlayManager.stopMouseOverlay();
    }

    qDebug() << "应用程序退出，退出码:" << exitCode;
    qInfo() << "========== 应用程序结束 ==========";

    return exitCode;
}
