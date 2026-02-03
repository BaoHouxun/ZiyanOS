#ifndef DOWNLOADMANAGER_H
#define DOWNLOADMANAGER_H

#include <QObject>
#include <QString>
#include <QFile>
#include <QThread>
#include <QDebug>
#include <curl/curl.h>

class DownloadManager : public QObject
{
    Q_OBJECT

    // QML属性：是否忽略SSL证书验证
    Q_PROPERTY(bool ignoreSslErrors READ ignoreSslErrors WRITE setIgnoreSslErrors NOTIFY ignoreSslErrorsChanged)

public:
    explicit DownloadManager(QObject *parent = nullptr);
    ~DownloadManager();

    // QML可调用的方法
    Q_INVOKABLE void startDownload(const QString &url, const QString &savePath);
    Q_INVOKABLE void cancelDownload();

    // SSL错误忽略属性访问器
    bool ignoreSslErrors() const;
    void setIgnoreSslErrors(bool ignore);

signals:
    // 进度信号：bytesReceived已接收字节数，bytesTotal总字节数
    void downloadProgress(qint64 bytesReceived, qint64 bytesTotal);

    // 下载完成信号：filePath保存的文件路径
    void downloadFinished(const QString &filePath);

    // 下载错误信号：errorMessage错误信息
    void downloadError(const QString &errorMessage);

    // 下载开始信号：fileName文件名，fileSize文件大小（格式化后的字符串）
    void downloadStarted(const QString &fileName, const QString &fileSize);

    // SSL错误忽略属性改变信号
    void ignoreSslErrorsChanged(bool ignore);

private:
    // 静态回调函数，供CURL库调用
    static size_t writeData(void *ptr, size_t size, size_t nmemb, void *userdata);
    static int progressCallback(void *clientp, curl_off_t dltotal, curl_off_t dlnow,
                                curl_off_t ultotal, curl_off_t ulnow);

    // 文件大小格式化辅助函数
    QString formatFileSize(qint64 bytes) const;

    // 下载数据结构
    struct DownloadData {
        QFile *file;                    // 要写入的文件对象
        qint64 totalSize;               // 文件总大小
        qint64 downloadedSize;          // 已下载大小
        DownloadManager *manager;       // 指向DownloadManager的指针
    };

    CURL *m_curl;                       // CURL句柄
    bool m_isDownloading;               // 下载状态标志
    bool m_ignoreSslErrors;             // 是否忽略SSL证书验证
    QString m_currentUrl;               // 当前下载的URL
    QString m_currentSavePath;          // 当前保存路径
    DownloadData *m_currentDownloadData; // 当前下载数据
};

#endif // DOWNLOADMANAGER_H
