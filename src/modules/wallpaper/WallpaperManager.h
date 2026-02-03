// WallpaperManager.h
#ifndef WALLPAPERMANAGER_H
#define WALLPAPERMANAGER_H

#include <QObject>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QFile>
#include <QDir>
#include <QDebug>
#include <QStandardPaths>
#include <QImage>
#include <QBuffer>

class WallpaperInfo : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString id READ id CONSTANT)
    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QString description READ description CONSTANT)
    Q_PROPERTY(QString imagePath READ imagePath CONSTANT)
    Q_PROPERTY(QString thumbnail READ thumbnail CONSTANT)

public:
    WallpaperInfo(const QString &id, const QString &name, const QString &description,
                  const QString &imagePath, const QString &thumbnail = "", QObject *parent = nullptr)
        : QObject(parent), m_id(id), m_name(name), m_description(description),
        m_imagePath(imagePath), m_thumbnail(thumbnail) {}

    QString id() const { return m_id; }
    QString name() const { return m_name; }
    QString description() const { return m_description; }
    QString imagePath() const { return m_imagePath; }
    QString thumbnail() const { return m_thumbnail; }

private:
    QString m_id;
    QString m_name;
    QString m_description;
    QString m_imagePath;
    QString m_thumbnail;
};

class WallpaperManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QList<QObject*> wallpapers READ wallpapers NOTIFY wallpapersLoaded)

public:
    explicit WallpaperManager(QObject *parent = nullptr);

    // 加载壁纸列表
    Q_INVOKABLE bool loadWallpapers();

    // 获取壁纸列表
    QList<QObject*> wallpapers() const { return m_wallpapers; }

    // 通过ID获取壁纸
    Q_INVOKABLE QObject* getWallpaperById(const QString &id);

    // 获取默认壁纸（第一个）
    Q_INVOKABLE QObject* getDefaultWallpaper();

    // 获取壁纸数量
    Q_INVOKABLE int count() const { return m_wallpapers.size(); }

signals:
    void wallpapersLoaded(bool success, const QString &errorMessage = "");
    void wallpaperSelected(const QString &id);

private:
    QList<QObject*> m_wallpapers;

    // 获取壁纸文件夹路径
    QString getWallpapersDir() const;

    // 获取JSON文件路径
    QString getJsonFilePath() const;

    // 创建默认JSON文件
    bool createDefaultJsonFile();

    // 验证壁纸文件是否存在
    bool validateWallpaperFiles();
};

#endif // WALLPAPERMANAGER_H
