#include "filesystem.h"

FileSystem::FileSystem(QObject *parent) : QObject(parent)
{
}

QVariantList FileSystem::getDrives()
{
    QVariantList drives;

    try {
        QList<QStorageInfo> storageList = QStorageInfo::mountedVolumes();

        for (const QStorageInfo &storage : storageList) {
            if (storage.isValid() && storage.isReady()) {
                QVariantMap drive;
                QString rootPath = storage.rootPath();
                QString name = storage.name();
                if (name.isEmpty()) {
                    name = "本地磁盘 (" + rootPath.left(2) + ")";
                }
                drive["name"] = name;
                drive["path"] = rootPath;
                drive["type"] = "drive";
                drive["size"] = formatFileSize(storage.bytesTotal());

                drives.append(drive);
            }
        }
    } catch (const std::exception &e) {
        emit errorOccurred(QString("获取驱动器列表失败: %1").arg(e.what()));
    }

    return drives;
}

QVariantList FileSystem::getDirectoryContents(const QString &path)
{
    QVariantList contents;

    try {
        QDir dir(path);
        if (!dir.exists()) {
            emit errorOccurred("目录不存在: " + path);
            return contents;
        }

        // 获取所有条目
        QFileInfoList entries = dir.entryInfoList(QDir::AllEntries | QDir::NoDotAndDotDot, QDir::DirsFirst | QDir::Name);

        for (const QFileInfo &entry : entries) {
            QVariantMap item;
            item["name"] = entry.fileName();
            item["path"] = entry.absoluteFilePath();
            item["isDir"] = entry.isDir();
            item["size"] = entry.isDir() ? "" : formatFileSize(entry.size());
            item["type"] = entry.isDir() ? "文件夹" : "文件";
            item["modified"] = entry.lastModified().toString("yyyy-MM-dd hh:mm:ss");

            contents.append(item);
        }
    } catch (const std::exception &e) {
        emit errorOccurred(QString("读取目录失败: %1").arg(e.what()));
    }

    return contents;
}

bool FileSystem::isDir(const QString &path)
{
    QFileInfo info(path);
    return info.isDir();
}

QString FileSystem::getFileName(const QString &path)
{
    QFileInfo info(path);
    return info.fileName();
}

QString FileSystem::getFileSize(const QString &path)
{
    QFileInfo info(path);
    if (info.isDir()) {
        return "";
    }
    return formatFileSize(info.size());
}

QString FileSystem::getFileType(const QString &path)
{
    QFileInfo info(path);
    return info.isDir() ? "文件夹" : "文件";
}

QString FileSystem::getParentDirectory(const QString &path)
{
    QDir dir(path);
    if (dir.isRoot()) {
        return ""; // 根目录没有父目录
    }
    dir.cdUp();
    return dir.absolutePath();
}

QDateTime FileSystem::getFileModifiedTime(const QString &path)
{
    QFileInfo info(path);
    return info.lastModified();
}

QString FileSystem::readFile(const QString &filePath)
{
    QFile file(filePath);
    if (!file.exists()) {
        emit errorOccurred("文件不存在: " + filePath);
        return "";
    }

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        emit errorOccurred("无法打开文件: " + filePath);
        return "";
    }

    // Qt 6 中不再使用 setCodec，使用 QTextStream 的默认编码（通常是 UTF-8）
    QTextStream in(&file);
    QString content = in.readAll();
    file.close();

    // 取消成功提示信号
    // emit fileOperationCompleted("文件读取成功: " + getFileName(filePath));
    return content;
}


bool FileSystem::writeFile(const QString &filePath, const QString &content)
{
    QFile file(filePath);

    // 确保目录存在
    QFileInfo fileInfo(filePath);
    QDir dir = fileInfo.absoluteDir();
    if (!dir.exists()) {
        if (!dir.mkpath(".")) {
            emit errorOccurred("无法创建目录: " + dir.absolutePath());
            return false;
        }
    }

    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        emit errorOccurred("无法写入文件: " + filePath);
        return false;
    }

    // Qt 6 中不再使用 setCodec，使用 QTextStream 的默认编码（通常是 UTF-8）
    QTextStream out(&file);
    out << content;
    file.close();

    // 取消成功提示信号
    // emit fileOperationCompleted("文件保存成功: " + getFileName(filePath));
    return true;
}

bool FileSystem::createDirectory(const QString &path)
{
    QDir dir;
    if (dir.mkpath(path)) {
        emit fileOperationCompleted("目录创建成功: " + path);
        return true;
    } else {
        emit errorOccurred("无法创建目录: " + path);
        return false;
    }
}

bool FileSystem::fileExists(const QString &filePath)
{
    return QFile::exists(filePath);
}

bool FileSystem::deleteFile(const QString &filePath)
{
    QFileInfo fileInfo(filePath);

    if (fileInfo.isDir()) {
        // 如果是文件夹，调用删除文件夹的方法
        return deleteDirectory(filePath);
    } else {
        // 如果是文件，使用原来的删除逻辑
        if (QFile::remove(filePath)) {
            emit fileOperationCompleted("文件删除成功: " + getFileName(filePath));
            return true;
        } else {
            emit errorOccurred("无法删除文件: " + filePath);
            return false;
        }
    }
}

// 新增：删除文件夹（递归删除）
bool FileSystem::deleteDirectory(const QString &path)
{
    QDir dir(path);

    if (!dir.exists()) {
        emit errorOccurred("文件夹不存在: " + path);
        return false;
    }

    // 递归删除文件夹及其内容
    if (dir.removeRecursively()) {
        emit fileOperationCompleted("文件夹删除成功: " + getFileName(path));
        return true;
    } else {
        emit errorOccurred("无法删除文件夹: " + path);
        return false;
    }
}

QString FileSystem::formatFileSize(qint64 bytes) const
{
    if (bytes == 0) return "0 B";

    const QStringList units = {"B", "KB", "MB", "GB", "TB"};
    int unitIndex = 0;
    double size = bytes;

    while (size >= 1024.0 && unitIndex < units.size() - 1) {
        size /= 1024.0;
        unitIndex++;
    }

    return QString("%1 %2").arg(size, 0, 'f', 1).arg(units[unitIndex]);
}

bool FileSystem::renameFile(const QString &oldPath, const QString &newPath)
{
    if (oldPath.isEmpty() || newPath.isEmpty()) {
        emit errorOccurred("文件路径不能为空");
        return false;
    }

    QFileInfo oldInfo(oldPath);
    if (!oldInfo.exists()) {
        emit errorOccurred("文件或文件夹不存在: " + oldPath);
        return false;
    }

    QFileInfo newInfo(newPath);
    if (newInfo.exists()) {
        emit errorOccurred("目标文件或文件夹已存在: " + newPath);
        return false;
    }

    // 对于文件和文件夹都使用 QFile::rename
    QFile file(oldPath);
    if (file.rename(newPath)) {
        QString operation = oldInfo.isDir() ? "文件夹" : "文件";
        emit fileOperationCompleted(operation + "重命名成功: " + getFileName(oldPath) + " -> " + getFileName(newPath));
        return true;
    } else {
        emit errorOccurred("重命名失败: " + oldPath);
        return false;
    }
}
