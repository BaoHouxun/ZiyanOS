// WallpaperManager.cpp
#include "WallpaperManager.h"
#include <QCoreApplication>

WallpaperManager::WallpaperManager(QObject *parent)
    : QObject(parent)
{
    // 构造函数中不加载壁纸，延迟到需要时加载
}

QString WallpaperManager::getWallpapersDir() const
{
    // 壁纸文件夹在程序根目录下的 wallpapers 文件夹
    QString appDir = QCoreApplication::applicationDirPath();
    return appDir + "/wallpapers";
}

QString WallpaperManager::getJsonFilePath() const
{
    return getWallpapersDir() + "/wallpapers.json";
}

bool WallpaperManager::loadWallpapers()
{
    // 清空现有壁纸列表
    qDeleteAll(m_wallpapers);
    m_wallpapers.clear();

    // 获取壁纸文件夹路径
    QString wallpapersDir = getWallpapersDir();
    QDir dir(wallpapersDir);

    // 如果壁纸文件夹不存在，创建它
    if (!dir.exists()) {
        if (!dir.mkpath(".")) {
            qWarning() << "无法创建壁纸文件夹:" << wallpapersDir;
            emit wallpapersLoaded(false, "无法创建壁纸文件夹");
            return false;
        }
        qDebug() << "已创建壁纸文件夹:" << wallpapersDir;
    }

    // 获取JSON文件路径
    QString jsonPath = getJsonFilePath();
    QFile jsonFile(jsonPath);

    // 如果JSON文件不存在，创建默认的
    if (!jsonFile.exists()) {
        qDebug() << "JSON文件不存在，创建默认配置";
        if (!createDefaultJsonFile()) {
            emit wallpapersLoaded(false, "无法创建默认壁纸配置文件");
            return false;
        }
    }

    // 读取JSON文件
    if (!jsonFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "无法打开JSON文件:" << jsonPath;
        emit wallpapersLoaded(false, "无法打开壁纸配置文件");
        return false;
    }

    QByteArray jsonData = jsonFile.readAll();
    jsonFile.close();

    // 解析JSON
    QJsonParseError parseError;
    QJsonDocument jsonDoc = QJsonDocument::fromJson(jsonData, &parseError);

    if (parseError.error != QJsonParseError::NoError) {
        qWarning() << "JSON解析错误:" << parseError.errorString();
        emit wallpapersLoaded(false, "壁纸配置文件格式错误");
        return false;
    }

    if (!jsonDoc.isArray()) {
        qWarning() << "JSON根元素不是数组";
        emit wallpapersLoaded(false, "壁纸配置文件格式错误");
        return false;
    }

    QJsonArray wallpaperArray = jsonDoc.array();

    // 遍历壁纸配置
    for (int i = 0; i < wallpaperArray.size(); ++i) {
        QJsonObject wallpaperObj = wallpaperArray[i].toObject();

        QString id = wallpaperObj["id"].toString();
        QString name = wallpaperObj["name"].toString();
        QString description = wallpaperObj["description"].toString();
        QString fileName = wallpaperObj["file"].toString();

        if (id.isEmpty() || fileName.isEmpty()) {
            qWarning() << "壁纸配置缺少必要字段，跳过:" << i;
            continue;
        }

        // 构建壁纸文件路径
        QString imagePath = "file:///" + wallpapersDir + "/" + fileName;
        imagePath = imagePath.replace("\\", "/");

        // 检查壁纸文件是否存在
        QString localFilePath = wallpapersDir + "/" + fileName;
        if (!QFile::exists(localFilePath)) {
            qWarning() << "壁纸文件不存在，跳过:" << localFilePath;
            continue;
        }

        // 创建壁纸信息对象
        WallpaperInfo *wallpaper = new WallpaperInfo(id, name, description, imagePath, "", this);
        m_wallpapers.append(wallpaper);

        qDebug() << "加载壁纸:" << name << "路径:" << imagePath;
    }

    if (m_wallpapers.isEmpty()) {
        qWarning() << "没有找到有效的壁纸";
        emit wallpapersLoaded(false, "没有找到有效的壁纸");
        return false;
    }

    qDebug() << "成功加载" << m_wallpapers.size() << "个壁纸";
    emit wallpapersLoaded(true);
    return true;
}

bool WallpaperManager::createDefaultJsonFile()
{
    QString wallpapersDir = getWallpapersDir();
    QString jsonPath = getJsonFilePath();

    // 创建默认壁纸配置
    QJsonArray wallpaperArray;

    // 创建几个示例壁纸配置
    QJsonObject wallpaper1;
    wallpaper1["id"] = "mountain";
    wallpaper1["name"] = "雪山晨曦";
    wallpaper1["description"] = "清晨的阳光洒在雪山之巅";
    wallpaper1["file"] = "mountain.jpg";

    QJsonObject wallpaper2;
    wallpaper2["id"] = "forest";
    wallpaper2["name"] = "迷雾森林";
    wallpaper2["description"] = "晨雾中的神秘森林";
    wallpaper2["file"] = "forest.jpg";

    QJsonObject wallpaper3;
    wallpaper3["id"] = "ocean";
    wallpaper3["name"] = "蔚蓝海洋";
    wallpaper3["description"] = "平静的海面与蓝天相接";
    wallpaper3["file"] = "ocean.jpg";

    wallpaperArray.append(wallpaper1);
    wallpaperArray.append(wallpaper2);
    wallpaperArray.append(wallpaper3);

    // 写入JSON文件
    QFile jsonFile(jsonPath);
    if (!jsonFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        qWarning() << "无法创建JSON文件:" << jsonPath;
        return false;
    }

    QJsonDocument jsonDoc(wallpaperArray);
    jsonFile.write(jsonDoc.toJson(QJsonDocument::Indented));
    jsonFile.close();

    qDebug() << "已创建默认JSON配置文件:" << jsonPath;

    // 创建README文件说明如何添加壁纸
    QString readmePath = wallpapersDir + "/README.txt";
    QFile readmeFile(readmePath);
    if (readmeFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QString readmeText =
            "壁纸文件夹使用说明\n"
            "==================\n\n"
            "1. 将壁纸图片文件（支持jpg、png格式）放在此文件夹中\n"
            "2. 编辑 wallpapers.json 文件，添加壁纸配置\n"
            "3. 壁纸配置格式：\n"
            "   {\n"
            "     \"id\": \"唯一标识符\",\n"
            "     \"name\": \"壁纸名称\",\n"
            "     \"description\": \"壁纸描述\",\n"
            "     \"file\": \"图片文件名\"\n"
            "   }\n\n"
            "注意：\n"
            "- 修改后重启程序生效\n"
            "- 确保图片文件存在于本文件夹中\n";
        readmeFile.write(readmeText.toUtf8());
        readmeFile.close();
    }

    return true;
}

bool WallpaperManager::validateWallpaperFiles()
{
    QString wallpapersDir = getWallpapersDir();

    for (QObject *obj : m_wallpapers) {
        WallpaperInfo *wallpaper = qobject_cast<WallpaperInfo*>(obj);
        if (wallpaper) {
            // 提取本地文件路径（移除file:///前缀）
            QString imagePath = wallpaper->imagePath();
            if (imagePath.startsWith("file:///")) {
                imagePath = imagePath.mid(8);
            }

            if (!QFile::exists(imagePath)) {
                qWarning() << "壁纸文件不存在:" << imagePath;
                return false;
            }
        }
    }

    return true;
}

QObject* WallpaperManager::getWallpaperById(const QString &id)
{
    for (QObject *obj : m_wallpapers) {
        WallpaperInfo *wallpaper = qobject_cast<WallpaperInfo*>(obj);
        if (wallpaper && wallpaper->id() == id) {
            return wallpaper;
        }
    }
    return nullptr;
}

QObject* WallpaperManager::getDefaultWallpaper()
{
    if (!m_wallpapers.isEmpty()) {
        return m_wallpapers.first();
    }
    return nullptr;
}
