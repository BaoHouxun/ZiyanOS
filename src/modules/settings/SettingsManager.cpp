#include "SettingsManager.h"
#include <QRegularExpression>

// 固定壁纸文件名
const QString SettingsManager::WALLPAPER_FILENAME = "wallpaper";

SettingsManager::SettingsManager(QObject *parent)
    : QObject(parent)
{
    // 设置文件路径
    QString configPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/ZiyanOS/config.ini";
    QFileInfo configFile(configPath);
    QDir configDir = configFile.absoluteDir();

    // 确保配置目录存在
    if (!configDir.exists()) {
        configDir.mkpath(".");
    }

    m_settings = new QSettings(configPath, QSettings::IniFormat, this);

    // 初始化壁纸目录
    initializeWallpaperDir();

    // 加载设置
    loadSettings();
}

QString SettingsManager::desktopBackground() const
{
    return m_desktopBackground;
}

void SettingsManager::setDesktopBackground(const QString &background)
{
    if (m_desktopBackground != background) {
        m_desktopBackground = background;
        emit desktopBackgroundChanged(background);
    }
}

QString SettingsManager::desktopWallpaper() const
{
    return m_desktopWallpaper;
}

void SettingsManager::setDesktopWallpaper(const QString &wallpaper)
{
    if (m_desktopWallpaper != wallpaper) {
        m_desktopWallpaper = wallpaper;
        emit desktopWallpaperChanged(wallpaper);
    }
}

// 新增：窗口标题栏模式
QString SettingsManager::windowTitleBarMode() const
{
    return m_windowTitleBarMode;
}

void SettingsManager::setWindowTitleBarMode(const QString &mode)
{
    if (m_windowTitleBarMode != mode) {
        m_windowTitleBarMode = mode;
        emit windowTitleBarModeChanged(mode);
    }
}

// 新增：窗口标题栏颜色
QString SettingsManager::windowTitleBarColor() const
{
    return m_windowTitleBarColor;
}

void SettingsManager::setWindowTitleBarColor(const QString &color)
{
    if (m_windowTitleBarColor != color) {
        m_windowTitleBarColor = color;
        emit windowTitleBarColorChanged(color);
    }
}

void SettingsManager::saveSettings()
{
    m_settings->setValue("Desktop/Background", m_desktopBackground);
    m_settings->setValue("Desktop/Wallpaper", m_desktopWallpaper);
    m_settings->setValue("Window/TitleBarMode", m_windowTitleBarMode);
    m_settings->setValue("Window/TitleBarColor", m_windowTitleBarColor);
    m_settings->setValue("Desktop/WallpaperName", m_currentWallpaperName);
    m_settings->setValue("Desktop/WallpaperDescription", m_currentWallpaperDescription);
    m_settings->sync();

    qDebug() << "设置已保存 - 背景:" << m_desktopBackground
             << "壁纸:" << m_desktopWallpaper
             << "窗口模式:" << m_windowTitleBarMode
             << "窗口颜色:" << m_windowTitleBarColor;
}

void SettingsManager::setWallpaperInfo(const QString &name, const QString &description)
{
    if (m_currentWallpaperName != name || m_currentWallpaperDescription != description) {
        m_currentWallpaperName = name;
        m_currentWallpaperDescription = description;
        emit wallpaperInfoChanged(name, description);
        saveSettings();
    }
}

QVariantMap SettingsManager::getWallpaperInfo() const
{
    QVariantMap info;
    info["name"] = m_currentWallpaperName;
    info["description"] = m_currentWallpaperDescription;
    return info;
}

void SettingsManager::loadSettings()
{
    m_desktopBackground = m_settings->value("Desktop/Background", "#1a1a1a").toString();
    m_desktopWallpaper = m_settings->value("Desktop/Wallpaper", "").toString();
    m_windowTitleBarMode = m_settings->value("Window/TitleBarMode", "auto").toString();
    m_windowTitleBarColor = m_settings->value("Window/TitleBarColor", "#3498db").toString();
    m_currentWallpaperName = m_settings->value("Desktop/WallpaperName", "").toString();
    m_currentWallpaperDescription = m_settings->value("Desktop/WallpaperDescription", "").toString();

    qDebug() << "设置已加载 - 背景:" << m_desktopBackground
             << "壁纸:" << m_desktopWallpaper
             << "窗口模式:" << m_windowTitleBarMode
             << "窗口颜色:" << m_windowTitleBarColor;

    // 发出信号通知属性已加载
    emit desktopBackgroundChanged(m_desktopBackground);
    emit desktopWallpaperChanged(m_desktopWallpaper);
    emit windowTitleBarModeChanged(m_windowTitleBarMode);
    emit windowTitleBarColorChanged(m_windowTitleBarColor);
}

// 新增：初始化壁纸目录
void SettingsManager::initializeWallpaperDir()
{
    QString wallpaperDir = getWallpaperDir();
    QDir dir(wallpaperDir);
    if (!dir.exists()) {
        if (dir.mkpath(".")) {
            qDebug() << "创建壁纸目录:" << wallpaperDir;
        } else {
            qWarning() << "无法创建壁纸目录:" << wallpaperDir;
        }
    }

    // 构建壁纸文件路径（不包含扩展名）
    m_wallpaperPath = wallpaperDir + "/" + WALLPAPER_FILENAME;

    qDebug() << "壁纸文件路径:" << m_wallpaperPath;
}

// 新增：保存壁纸图片到本地（覆盖式）
QString SettingsManager::saveWallpaperImage(const QString &sourcePath)
{
    if (sourcePath.isEmpty()) {
        qWarning() << "壁纸源路径为空";
        return "";
    }

    // 检查源文件是否存在
    QFileInfo sourceFile(sourcePath);
    if (!sourceFile.exists()) {
        qWarning() << "壁纸源文件不存在:" << sourcePath;
        return "";
    }

    // 获取支持的图片扩展名
    QString extension = getImageExtension(sourcePath);
    if (extension.isEmpty()) {
        qWarning() << "不支持的图片格式:" << sourcePath;
        return "";
    }

    // 构建完整的壁纸文件路径（包含扩展名）
    QString fullWallpaperPath = m_wallpaperPath + extension;

    qDebug() << "保存壁纸到:" << fullWallpaperPath;

    // 先尝试删除旧的壁纸文件（所有可能的扩展名）
    QStringList extensions = {".jpg", ".jpeg", ".png", ".bmp", ".gif"};
    for (const QString &ext : extensions) {
        QString oldPath = m_wallpaperPath + ext;
        if (QFile::exists(oldPath)) {
            QFile::remove(oldPath);
            qDebug() << "删除旧的壁纸文件:" << oldPath;
        }
    }

    // 复制图片文件（覆盖式）
    if (QFile::copy(sourcePath, fullWallpaperPath)) {
        qDebug() << "壁纸图片已保存（覆盖式）:" << fullWallpaperPath;

        // 转换为 file:// URL 格式
        QString fileUrl = "file:///" + fullWallpaperPath.replace("\\", "/");
        return fileUrl;
    } else {
        qWarning() << "无法保存壁纸图片:" << sourcePath << "到:" << fullWallpaperPath;

        // 尝试使用QImage保存
        QImage image(sourcePath);
        if (!image.isNull() && image.save(fullWallpaperPath)) {
            qDebug() << "壁纸通过QImage保存成功:" << fullWallpaperPath;
            QString fileUrl = "file:///" + fullWallpaperPath.replace("\\", "/");
            return fileUrl;
        } else {
            qWarning() << "壁纸保存失败:" << sourcePath;
            return "";
        }
    }
}

// 新增：清除壁纸文件
bool SettingsManager::removeWallpaperFile()
{
    QStringList extensions = {".jpg", ".jpeg", ".png", ".bmp", ".gif"};
    bool removed = false;

    for (const QString &ext : extensions) {
        QString wallpaperPath = m_wallpaperPath + ext;
        if (QFile::exists(wallpaperPath)) {
            if (QFile::remove(wallpaperPath)) {
                qDebug() << "壁纸文件已删除:" << wallpaperPath;
                removed = true;
            } else {
                qWarning() << "无法删除壁纸文件:" << wallpaperPath;
            }
        }
    }

    return removed;
}

// 新增：获取壁纸文件路径
QString SettingsManager::getWallpaperPath() const
{
    // 检查哪个扩展名的文件存在
    QStringList extensions = {".jpg", ".jpeg", ".png", ".bmp", ".gif"};
    for (const QString &ext : extensions) {
        QString wallpaperPath = m_wallpaperPath + ext;
        if (QFile::exists(wallpaperPath)) {
            return "file:///" + wallpaperPath.replace("\\", "/");
        }
    }

    return "";
}

// 新增：获取支持的图片扩展名
QString SettingsManager::getImageExtension(const QString &sourcePath)
{
    QFileInfo fileInfo(sourcePath);
    QString extension = fileInfo.suffix().toLower();

    // 支持的图片格式
    if (extension == "jpg" || extension == "jpeg") {
        return ".jpg";
    } else if (extension == "png") {
        return ".png";
    } else if (extension == "bmp") {
        return ".bmp";
    } else if (extension == "gif") {
        return ".gif";
    }

    return "";
}

// 新增：获取壁纸目录
QString SettingsManager::getWallpaperDir() const
{
    return QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) + "/ZiyanOS";
}

// 新增：验证颜色字符串
bool SettingsManager::isValidColor(const QString &color)
{
    if (color.isEmpty()) return false;

    // 检查是否为有效的十六进制颜色
    QRegularExpression hexRegex("^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$");
    return hexRegex.match(color).hasMatch();
}
