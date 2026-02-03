#ifndef FILESYSTEM_H
#define FILESYSTEM_H

#include <QObject>
#include <QFileInfo>
#include <QDir>
#include <QFileInfoList>
#include <QStorageInfo>
#include <QDebug>
#include <QFile>
#include <QTextStream>
#include <QDateTime>

class FileSystem : public QObject
{
    Q_OBJECT

public:
    explicit FileSystem(QObject *parent = nullptr);

    Q_INVOKABLE QVariantList getDrives();
    Q_INVOKABLE QVariantList getDirectoryContents(const QString &path);
    Q_INVOKABLE bool isDir(const QString &path);
    Q_INVOKABLE QString getFileName(const QString &path);
    Q_INVOKABLE QString getFileSize(const QString &path);
    Q_INVOKABLE QString getFileType(const QString &path);
    Q_INVOKABLE QString getParentDirectory(const QString &path);
    Q_INVOKABLE QDateTime getFileModifiedTime(const QString &path);

    // 文件读写功能
    Q_INVOKABLE QString readFile(const QString &filePath);
    Q_INVOKABLE bool writeFile(const QString &filePath, const QString &content);
    Q_INVOKABLE bool createDirectory(const QString &path);
    Q_INVOKABLE bool fileExists(const QString &filePath);

    // 修改：添加文件夹删除支持
    Q_INVOKABLE bool deleteFile(const QString &filePath);
    Q_INVOKABLE bool deleteDirectory(const QString &path);

    // 修改：重命名支持文件和文件夹
    Q_INVOKABLE bool renameFile(const QString &oldPath, const QString &newPath);

signals:
    void errorOccurred(const QString &errorMessage);
    void fileOperationCompleted(const QString &message);

private:
    QString formatFileSize(qint64 bytes) const;
};

#endif // FILESYSTEM_H
