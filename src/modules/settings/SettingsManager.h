#ifndef SETTINGSMANAGER_H
#define SETTINGSMANAGER_H

#include <QObject>
#include <QSettings>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QImage>
#include <QDebug>
#include <QColor>

class SettingsManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString desktopBackground READ desktopBackground WRITE setDesktopBackground NOTIFY desktopBackgroundChanged)
    Q_PROPERTY(QString desktopWallpaper READ desktopWallpaper WRITE setDesktopWallpaper NOTIFY desktopWallpaperChanged)

    // 新增：窗口标题栏颜色设置
    Q_PROPERTY(QString windowTitleBarMode READ windowTitleBarMode WRITE setWindowTitleBarMode NOTIFY windowTitleBarModeChanged)
    Q_PROPERTY(QString windowTitleBarColor READ windowTitleBarColor WRITE setWindowTitleBarColor NOTIFY windowTitleBarColorChanged)

public:
    explicit SettingsManager(QObject *parent = nullptr);

    QString desktopBackground() const;
    void setDesktopBackground(const QString &background);

    QString desktopWallpaper() const;
    void setDesktopWallpaper(const QString &wallpaper);

    // 新增：窗口标题栏颜色设置方法
    QString windowTitleBarMode() const;
    void setWindowTitleBarMode(const QString &mode);

    QString windowTitleBarColor() const;
    void setWindowTitleBarColor(const QString &color);

    Q_INVOKABLE void saveSettings();
    Q_INVOKABLE void loadSettings();

    // 新增：保存壁纸图片到本地（覆盖式）
    Q_INVOKABLE QString saveWallpaperImage(const QString &sourcePath);

    // 新增：清除壁纸文件
    Q_INVOKABLE bool removeWallpaperFile();

    // 新增：获取壁纸文件路径
    Q_INVOKABLE QString getWallpaperPath() const;

    // 新增：验证颜色字符串
    Q_INVOKABLE bool isValidColor(const QString &color);

    Q_INVOKABLE void setWallpaperInfo(const QString &name, const QString &description);
    Q_INVOKABLE QVariantMap getWallpaperInfo() const;


signals:
    void desktopBackgroundChanged(const QString &background);
    void desktopWallpaperChanged(const QString &wallpaper);
    // 新增：窗口设置信号
    void windowTitleBarModeChanged(const QString &mode);
    void windowTitleBarColorChanged(const QString &color);
    void wallpaperInfoChanged(const QString &name, const QString &description);

private:
    QSettings *m_settings;
    QString m_desktopBackground;
    QString m_desktopWallpaper;

    // 新增：窗口标题栏颜色设置
    QString m_windowTitleBarMode;
    QString m_windowTitleBarColor;

    // 新增：壁纸文件路径
    QString m_wallpaperPath;

    // 新增：固定壁纸文件名
    static const QString WALLPAPER_FILENAME;

    // 新增：初始化壁纸目录
    void initializeWallpaperDir();

    // 新增：获取支持的图片扩展名
    QString getImageExtension(const QString &sourcePath);

    // 新增：获取壁纸目录
    QString getWallpaperDir() const;

    QString m_currentWallpaperName;
    QString m_currentWallpaperDescription;
};

#endif // SETTINGSMANAGER_H
