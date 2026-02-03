import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ZiyanOS.DownloadManager 1.0
import ZiyanOS.FileSystem

ZiyanWindow {
    id: downloadWindow
    width: 500
    height: 450
    windowTitle: "下载管理器"

    property var filePicker: null
    property var fileSystem: FileSystem {}
    property string selectedSavePath: ""

    // 下载管理器
    DownloadManager {
        id: downloadManager
        onDownloadProgress: (bytesReceived, bytesTotal) => {
            var progress = 0
            if (bytesTotal > 0) {
                progress = (bytesReceived / bytesTotal) * 100
            }
            downloadProgress.text = "进度: " + progress.toFixed(1) + "%"
            progressBar.value = progress

            var downloaded = formatBytes(bytesReceived)
            var total = formatBytes(bytesTotal)
            sizeText.text = downloaded + " / " + total
        }

        onDownloadFinished: (filePath) => {
            statusText.text = "下载完成: " + filePath
            downloadProgress.text = "完成"
            progressBar.value = 100
            downloadBtn.enabled = true
            urlInput.enabled = true
            selectPathBtn.enabled = true
            sizeText.text = ""
        }

        onDownloadError: (errorMessage) => {
            statusText.text = "错误: " + errorMessage
            downloadProgress.text = "失败"
            downloadBtn.enabled = true
            urlInput.enabled = true
            selectPathBtn.enabled = true
            sizeText.text = ""
        }

        onDownloadStarted: (fileName, fileSize) => {
            statusText.text = "开始下载: " + fileName
        }
    }

    function formatBytes(bytes) {
        if (bytes < 1024) return bytes + " B"
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB"
        if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + " MB"
        return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GB"
    }

    contentItem: Item {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // URL输入区域
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true

                Text {
                    text: "下载链接:"
                    font.pixelSize: 13
                    color: "#2c3e50"
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    color: "white"
                    border.color: "#bdc3c7"
                    border.width: 1
                    radius: 4

                    TextInput {
                        id: urlInput
                        anchors.fill: parent
                        anchors.margins: 8
                        verticalAlignment: TextInput.AlignVCenter
                        font.pixelSize: 13
                        selectByMouse: true
                    }

                    Text {
                        text: "输入下载链接"
                        color: "#95a5a6"
                        font.pixelSize: 13
                        anchors {
                            left: parent.left
                            leftMargin: 8
                            verticalCenter: parent.verticalCenter
                        }
                        visible: urlInput.text === ""
                    }
                }
            }

            // 保存路径选择
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true

                Text {
                    text: "保存位置:"
                    font.pixelSize: 13
                    color: "#2c3e50"
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        color: selectedSavePath ? "#f8f9fa" : "white"
                        border.color: "#bdc3c7"
                        border.width: 1
                        radius: 4

                        Text {
                            text: selectedSavePath ? selectedSavePath : "未选择位置"
                            color: selectedSavePath ? "#2c3e50" : "#95a5a6"
                            font.pixelSize: 12
                            elide: Text.ElideLeft
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                margins: 8
                            }
                        }
                    }

                    Rectangle {
                        width: 80
                        height: 32
                        color: "#3498db"
                        radius: 4

                        Text {
                            text: "选择"
                            color: "white"
                            font.pixelSize: 12
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: selectPathBtn
                            anchors.fill: parent
                            onClicked: showFilePicker()
                        }
                    }
                }
            }

            // SSL设置
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "SSL:"
                    font.pixelSize: 13
                    color: "#2c3e50"
                }

                Rectangle {
                    width: 50
                    height: 24
                    color: downloadManager.ignoreSslErrors ? "#f39c12" : "#27ae60"
                    radius: 3

                    Text {
                        text: downloadManager.ignoreSslErrors ? "禁用" : "启用"
                        color: "white"
                        font.pixelSize: 11
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            downloadManager.ignoreSslErrors = !downloadManager.ignoreSslErrors
                        }
                    }
                }

                Text {
                    text: downloadManager.ignoreSslErrors ? "⚠️ SSL验证已禁用" : "✅ SSL验证已启用"
                    color: downloadManager.ignoreSslErrors ? "#e74c3c" : "#27ae60"
                    font.pixelSize: 11
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                }
            }

            // 进度显示区域
            ColumnLayout {
                spacing: 6
                Layout.fillWidth: true

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        id: downloadProgress
                        text: "等待下载..."
                        font.pixelSize: 12
                        color: "#2c3e50"
                    }

                    Text {
                        id: sizeText
                        font.pixelSize: 11
                        color: "#7f8c8d"
                        Layout.alignment: Qt.AlignRight
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 16
                    radius: 8
                    color: "#ecf0f1"

                    Rectangle {
                        id: progressBar
                        width: 0
                        height: parent.height
                        radius: parent.radius
                        color: "#3498db"

                        property real value: 0

                        onValueChanged: {
                            width = (parent.width * value) / 100
                        }
                    }
                }
            }

            // 状态信息
            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: "#f8f9fa"
                radius: 6
                border.color: "#dee2e6"
                border.width: 1

                Text {
                    id: statusText
                    text: "准备就绪"
                    font.pixelSize: 12
                    color: "#7f8c8d"
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    anchors {
                        fill: parent
                        margins: 8
                    }
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // 操作按钮
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    id: downloadBtn
                    Layout.fillWidth: true
                    height: 40
                    color: enabled ? "#27ae60" : "#bdc3c7"
                    radius: 6
                    enabled: urlInput.text !== "" && selectedSavePath !== ""

                    Text {
                        text: "开始下载"
                        color: "white"
                        font.pixelSize: 14
                        font.bold: true
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: parent.enabled
                        onClicked: {
                            statusText.text = "正在下载..."
                            downloadProgress.text = "连接中..."
                            downloadBtn.enabled = false
                            urlInput.enabled = false
                            selectPathBtn.enabled = false
                            downloadManager.startDownload(urlInput.text, selectedSavePath)
                        }
                    }
                }

                Rectangle {
                    width: 80
                    height: 40
                    color: "#e74c3c"
                    radius: 6

                    Text {
                        text: "取消"
                        color: "white"
                        font.pixelSize: 14
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            downloadManager.cancelDownload()
                            statusText.text = "下载已取消"
                            downloadProgress.text = "已取消"
                            downloadBtn.enabled = true
                            urlInput.enabled = true
                            selectPathBtn.enabled = true
                            sizeText.text = ""
                        }
                    }
                }
            }
        }
    }

    // 显示文件选择器
    function showFilePicker() {
        filePicker = filePickerComponent.createObject(downloadWindow, {
            "selectFolder": false,
            "fileMode": "save",
            "defaultFileName": getDefaultFileName()
        })

        filePicker.fileSelected.connect(function(path) {
            selectedSavePath = path
            filePicker.destroy()
        })

        filePicker.canceled.connect(function() {
            filePicker.destroy()
        })

        filePicker.showWindow()
    }

    // 从URL提取默认文件名
    function getDefaultFileName() {
        var url = urlInput.text
        if (!url) return "download.file"

        var lastSlash = url.lastIndexOf('/')
        if (lastSlash !== -1 && lastSlash < url.length - 1) {
            var fileName = url.substring(lastSlash + 1)
            var questionMark = fileName.indexOf('?')
            if (questionMark !== -1) {
                fileName = fileName.substring(0, questionMark)
            }
            if (fileName.indexOf('.') === -1) {
                fileName += ".file"
            }
            fileName = fileName.replace(/[<>:"/\\|?*]/g, '_')
            return fileName
        }

        return "download.file"
    }

    // 文件选择器组件
    Component {
        id: filePickerComponent
        FilePicker {}
    }

    Component.onCompleted: {
        console.log("下载管理器已加载")
    }
}
