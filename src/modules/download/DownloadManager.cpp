#include "DownloadManager.h"
#include <QFileInfo>
#include <QCoreApplication>

DownloadManager::DownloadManager(QObject *parent)
    : QObject(parent)
    , m_curl(nullptr)
    , m_isDownloading(false)
    , m_ignoreSslErrors(false)  // 默认不忽略SSL错误
    , m_currentDownloadData(nullptr)
{
    // 初始化CURL全局库
    CURLcode res = curl_global_init(CURL_GLOBAL_DEFAULT);
    if (res != CURLE_OK) {
        qWarning() << "Failed to initialize curl: " << curl_easy_strerror(res);
        return;
    }

    // 创建CURL句柄
    m_curl = curl_easy_init();
    if (!m_curl) {
        qWarning() << "Failed to create curl handle";
    }
}

DownloadManager::~DownloadManager()
{
    // 清理CURL句柄
    if (m_curl) {
        curl_easy_cleanup(m_curl);
    }

    // 清理CURL全局状态
    curl_global_cleanup();

    // 清理下载数据
    if (m_currentDownloadData) {
        delete m_currentDownloadData;
    }
}

// SSL错误忽略属性访问器
bool DownloadManager::ignoreSslErrors() const
{
    return m_ignoreSslErrors;
}

void DownloadManager::setIgnoreSslErrors(bool ignore)
{
    if (m_ignoreSslErrors != ignore) {
        m_ignoreSslErrors = ignore;
        emit ignoreSslErrorsChanged(ignore);

        if (ignore) {
            qWarning() << "SSL证书验证已禁用。注意：这可能导致安全风险！";
        } else {
            qInfo() << "SSL证书验证已启用";
        }
    }
}

QString DownloadManager::formatFileSize(qint64 bytes) const
{
    if (bytes == 0) return "0 B";

    const QStringList units = {"B", "KB", "MB", "GB", "TB"};
    int unitIndex = 0;
    double size = static_cast<double>(bytes);

    // 计算合适的单位
    while (size >= 1024.0 && unitIndex < units.size() - 1) {
        size /= 1024.0;
        unitIndex++;
    }

    return QString("%1 %2").arg(QString::number(size, 'f', 1)).arg(units[unitIndex]);
}

void DownloadManager::startDownload(const QString &url, const QString &savePath)
{
    // 检查是否已有下载任务
    if (m_isDownloading) {
        emit downloadError("已有下载任务正在进行");
        return;
    }

    // 检查CURL句柄是否有效
    if (!m_curl) {
        emit downloadError("CURL初始化失败");
        return;
    }

    // 检查URL是否为空
    if (url.isEmpty()) {
        emit downloadError("URL不能为空");
        return;
    }

    // 检查保存路径是否为空
    if (savePath.isEmpty()) {
        emit downloadError("保存路径不能为空");
        return;
    }

    m_currentUrl = url;
    m_currentSavePath = savePath;

    // 在新线程中执行下载，避免阻塞UI
    QThread *downloadThread = QThread::create([this, url, savePath]() {
        m_isDownloading = true;

        // 创建下载数据结构
        DownloadData *downloadData = new DownloadData();
        downloadData->file = new QFile(savePath);
        downloadData->totalSize = 0;
        downloadData->downloadedSize = 0;
        downloadData->manager = this;

        m_currentDownloadData = downloadData;

        // 尝试打开文件进行写入
        if (!downloadData->file->open(QIODevice::WriteOnly)) {
            emit downloadError("无法创建文件: " + savePath);
            delete downloadData->file;
            delete downloadData;
            m_currentDownloadData = nullptr;
            m_isDownloading = false;
            return;
        }

        CURLcode res;

        // 重置CURL句柄选项
        curl_easy_reset(m_curl);

        // 设置CURL选项
        curl_easy_setopt(m_curl, CURLOPT_URL, url.toUtf8().constData());
        curl_easy_setopt(m_curl, CURLOPT_WRITEFUNCTION, writeData);
        curl_easy_setopt(m_curl, CURLOPT_WRITEDATA, downloadData);
        curl_easy_setopt(m_curl, CURLOPT_NOPROGRESS, 0L);
        curl_easy_setopt(m_curl, CURLOPT_XFERINFOFUNCTION, progressCallback);
        curl_easy_setopt(m_curl, CURLOPT_XFERINFODATA, downloadData);

        // 设置超时
        curl_easy_setopt(m_curl, CURLOPT_CONNECTTIMEOUT, 30L);
        curl_easy_setopt(m_curl, CURLOPT_TIMEOUT, 300L); // 总超时300秒

        // 设置用户代理
        curl_easy_setopt(m_curl, CURLOPT_USERAGENT, "ZiyanOS-Downloader/1.0");

        // 跟随重定向
        curl_easy_setopt(m_curl, CURLOPT_FOLLOWLOCATION, 1L);
        curl_easy_setopt(m_curl, CURLOPT_MAXREDIRS, 10L);

        // 设置SSL选项（根据用户设置决定是否忽略证书验证）
        if (m_ignoreSslErrors) {
            // 忽略SSL证书验证
            curl_easy_setopt(m_curl, CURLOPT_SSL_VERIFYPEER, 0L);
            curl_easy_setopt(m_curl, CURLOPT_SSL_VERIFYHOST, 0L);
            qDebug() << "SSL证书验证已禁用";
        } else {
            // 启用SSL证书验证（默认）
            curl_easy_setopt(m_curl, CURLOPT_SSL_VERIFYPEER, 1L);
            curl_easy_setopt(m_curl, CURLOPT_SSL_VERIFYHOST, 2L);
        }

        // 先获取文件大小（HEAD请求）
        curl_easy_setopt(m_curl, CURLOPT_NOBODY, 1L);
        res = curl_easy_perform(m_curl);

        if (res == CURLE_OK) {
            // 获取文件大小
            curl_off_t fileSize = 0;
            curl_easy_getinfo(m_curl, CURLINFO_CONTENT_LENGTH_DOWNLOAD_T, &fileSize);
            downloadData->totalSize = static_cast<qint64>(fileSize);

            // 发出开始信号
            QFileInfo fileInfo(savePath);
            QString sizeStr = formatFileSize(static_cast<qint64>(fileSize));
            emit downloadStarted(fileInfo.fileName(), sizeStr);
        } else {
            qDebug() << "无法获取文件大小，将继续尝试下载";
        }

        // 重新设置以获取文件内容
        curl_easy_setopt(m_curl, CURLOPT_NOBODY, 0L);

        // 执行下载
        res = curl_easy_perform(m_curl);

        // 关闭文件
        downloadData->file->close();

        if (res == CURLE_OK) {
            // 检查HTTP状态码
            long http_code = 0;
            curl_easy_getinfo(m_curl, CURLINFO_RESPONSE_CODE, &http_code);

            if (http_code >= 200 && http_code < 300) {
                emit downloadFinished(savePath);
            } else {
                emit downloadError(QString("HTTP错误: %1").arg(http_code));
            }
        } else {
            QString errorMsg = QString("下载失败: %1").arg(curl_easy_strerror(res));

            // 如果是SSL证书错误，提供更详细的提示
            if (res == CURLE_SSL_CACERT || res == CURLE_SSL_CERTPROBLEM) {
                errorMsg += "\n可能是SSL证书验证失败，尝试在设置中忽略SSL证书验证";
            }

            emit downloadError(errorMsg);
        }

        // 清理下载数据
        delete downloadData->file;
        delete downloadData;
        m_currentDownloadData = nullptr;
        m_isDownloading = false;
    });

    // 线程结束后自动清理
    connect(downloadThread, &QThread::finished, downloadThread, &QThread::deleteLater);
    downloadThread->start();
}

void DownloadManager::cancelDownload()
{
    if (m_curl && m_isDownloading) {
        // 设置超时以快速中断下载
        curl_easy_setopt(m_curl, CURLOPT_TIMEOUT_MS, 1L);
    }
}

size_t DownloadManager::writeData(void *ptr, size_t size, size_t nmemb, void *userdata)
{
    DownloadData *data = static_cast<DownloadData*>(userdata);
    size_t written = 0;

    // 确保文件已打开
    if (data->file && data->file->isOpen()) {
        written = data->file->write(static_cast<char*>(ptr), size * nmemb);
        if (written > 0) {
            data->downloadedSize += written;
        }
    }

    return written;
}

int DownloadManager::progressCallback(void *clientp, curl_off_t dltotal, curl_off_t dlnow,
                                      curl_off_t ultotal, curl_off_t ulnow)
{
    Q_UNUSED(ultotal);
    Q_UNUSED(ulnow);

    DownloadData *data = static_cast<DownloadData*>(clientp);

    // 当有下载进度时，发送进度信号
    if (dltotal > 0 && dlnow > 0) {
        // 使用Qt的元对象系统在主线程中调用信号
        QMetaObject::invokeMethod(data->manager, "downloadProgress",
                                  Qt::QueuedConnection,
                                  Q_ARG(qint64, dlnow),
                                  Q_ARG(qint64, dltotal));
    }

    return 0; // 返回0继续下载，返回非0取消下载
}
